import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/env.dart';
import '../data/models.dart';

class AiException implements Exception {
  AiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// CV writing help. Uses the Claude Messages API when ANTHROPIC_API_KEY is
/// set, otherwise Google Gemini (which has a free tier) when GEMINI_API_KEY
/// is set. Both over raw HTTP. Nothing is sent until the user taps an AI action.
class AiService {
  static const _claudeModel = 'claude-opus-5-5';
  static final _claudeUri = Uri.parse('https://api.anthropic.com/v1/messages');

  static const _system = '''
You are an expert international recruiter and CV writer. You write for ATS (applicant tracking systems) and human recruiters at the same time.
Rules:
- Write in the same language as the user's input. If the input is Indonesian, answer in Indonesian; otherwise English.
- No first-person pronouns. Start bullets with a strong past-tense action verb (present tense for a current role).
- Prefer concrete outcomes and numbers. Never invent numbers, employers, tools or achievements: if a metric is unknown, write the sentence so it reads well without one, or use a bracketed placeholder like [X%] the user can fill in.
- Plain text only. No markdown, no headings, no quotes around the answer, no commentary.''';

  Future<String> _ask(String prompt, {int maxTokens = 2000}) async {
    if (!Env.hasAi) {
      throw AiException(
        'Fitur AI belum aktif. Isi GEMINI_API_KEY atau ANTHROPIC_API_KEY di .env.json lalu build ulang.',
      );
    }
    final http.Response res;
    try {
      if (Env.anthropicKey.isNotEmpty) {
        res = await _postClaude(prompt, maxTokens).timeout(const Duration(seconds: 90));
      } else {
        var r = await _postGemini(prompt, maxTokens, Env.geminiModel).timeout(const Duration(seconds: 90));
        // Free-tier Flash is often overloaded (503); fall back to Flash-Lite once.
        if (r.statusCode == 503 || r.statusCode == 429) {
          r = await _postGemini(prompt, maxTokens, 'gemini-flash-lite-latest').timeout(const Duration(seconds: 90));
        }
        res = r;
      }
    } catch (_) {
      throw AiException('Tidak bisa menghubungi layanan AI. Cek koneksi internet.');
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      final msg = (body['error'] as Map?)?['message'] ?? 'HTTP ${res.statusCode}';
      throw AiException(switch (res.statusCode) {
        400 when '$msg'.toLowerCase().contains('api key') => 'API key AI tidak valid.',
        401 || 403 => 'API key AI tidak valid.',
        429 => 'Batas pemakaian AI tercapai. Coba lagi beberapa menit lagi.',
        >= 500 => 'Layanan AI sedang gangguan. Coba lagi nanti.',
        _ => 'AI gagal: $msg',
      });
    }
    final text = Env.anthropicKey.isNotEmpty ? _readClaude(body) : _readGemini(body);
    if (text.isEmpty) throw AiException('AI tidak memberi jawaban. Coba lagi.');
    return text;
  }

  Future<http.Response> _postClaude(String prompt, int maxTokens) => http.post(
    _claudeUri,
    headers: {
      'content-type': 'application/json',
      'x-api-key': Env.anthropicKey,
      'anthropic-version': '2023-06-01',
      'anthropic-beta': 'server-side-fallback-2026-07-01',
    },
    body: jsonEncode({
      'model': _claudeModel,
      'max_tokens': maxTokens,
      'fallbacks': 'default',
      'output_config': {'effort': 'low'},
      'system': _system,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    }),
  );

  String _readClaude(Map<String, dynamic> body) {
    if (body['stop_reason'] == 'refusal') {
      throw AiException('AI menolak permintaan ini. Ubah teksnya lalu coba lagi.');
    }
    return (body['content'] as List)
        .whereType<Map>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join()
        .trim();
  }

  Future<http.Response> _postGemini(String prompt, int maxTokens, String model) => http.post(
    Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
    headers: {'content-type': 'application/json', 'x-goog-api-key': Env.geminiKey},
    body: jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _system},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': maxTokens},
    }),
  );

  String _readGemini(Map<String, dynamic> body) {
    final candidates = body['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw AiException('AI menolak permintaan ini. Ubah teksnya lalu coba lagi.');
    }
    final parts = ((candidates.first as Map)['content'] as Map?)?['parts'] as List? ?? const [];
    return parts.whereType<Map>().where((p) => p['thought'] != true).map((p) => '${p['text'] ?? ''}').join().trim();
  }

  static List<String> _lines(String text) => text
      .split('\n')
      .map((l) => l.replaceFirst(RegExp(r'^\s*([-•*]|\d+[.)])\s*'), '').trim())
      .where((l) => l.isNotEmpty)
      .toList();

  Future<String> improveBullet(String bullet, {String role = ''}) => _ask(
    'Rewrite this CV bullet point to be stronger and ATS-friendly. Keep the facts. '
    'Return only the rewritten bullet, one line.\n'
    '${role.isEmpty ? '' : 'Role: $role\n'}Bullet: $bullet',
    maxTokens: 600,
  );

  Future<List<String>> bulletsFromNotes(String notes, {String role = '', String company = ''}) async {
    final text = await _ask(
      'Turn these rough notes about a job into 3-5 CV bullet points. One bullet per line, no numbering.\n'
      'Role: $role\nCompany: $company\nNotes: $notes',
    );
    return _lines(text).take(6).toList();
  }

  Future<String> writeSummary(ResumeData d, {String targetRole = ''}) {
    final exp = d.experiences
        .map((e) => '- ${e.role} at ${e.company} (${e.period}): ${e.bullets.join('; ')}')
        .join('\n');
    return _ask(
      'Write a professional CV summary of 3 sentences (40-70 words) for this person.'
      '${targetRole.isEmpty ? '' : ' Target role: $targetRole.'}\n'
      'Headline: ${d.contact.headline}\nExisting summary: ${d.summary}\n'
      'Experience:\n$exp\nSkills: ${d.skills.join(', ')}\n'
      'Return only the summary paragraph.',
      maxTokens: 800,
    );
  }

  Future<String> tailorSummary(ResumeData d, String jobPost) => _ask(
    'Rewrite the CV summary so it targets the job post below, using its key terms only where they are true '
    'for this candidate. 40-70 words, one paragraph.\n'
    'Current summary: ${d.summary}\nSkills: ${d.skills.join(', ')}\n'
    'Roles: ${d.experiences.map((e) => e.role).join(', ')}\n\nJob post:\n$jobPost',
    maxTokens: 800,
  );
}
