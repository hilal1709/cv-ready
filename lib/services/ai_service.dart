import 'dart:convert';

import '../data/api_client.dart';
import '../data/models.dart';
import 'keyword_matcher.dart';

class AiException implements Exception {
  AiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// CV writing help. The prompts are built here; the backend adds the system
/// prompt, holds the AI keys and picks the model. Nothing is sent until the
/// user taps an AI action.
class AiService {
  AiService({ApiClient? api}) : _api = api ?? ApiClient.instance;
  final ApiClient _api;

  Future<String> _ask(String prompt, {int maxTokens = 2000, bool json = false}) async {
    try {
      final res = await _api.request(
        'POST',
        '/ai',
        body: {'prompt': prompt, 'maxTokens': maxTokens, 'json': json},
        timeout: const Duration(seconds: 100),
      );
      final text = '${res['text'] ?? ''}'.trim();
      if (text.isEmpty) throw AiException('AI tidak memberi jawaban. Coba lagi.');
      return text;
    } on ApiException catch (e) {
      throw AiException(e.message);
    }
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

  /// Parses a JSON object out of an AI answer, tolerating code fences or a
  /// sentence around it.
  static Map<String, dynamic> _decodeJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        final v = jsonDecode(text.substring(start, end + 1));
        if (v is Map<String, dynamic>) return v;
      } on FormatException {
        // fall through
      }
    }
    throw AiException('AI memberi jawaban yang tidak terbaca. Coba lagi.');
  }

  static List<String> _strings(Object? v) =>
      (v is List ? v : const []).map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();

  /// Reads which skills a job post asks for and which of them the CV shows.
  Future<KeywordMatch> matchSkills(String jobPost, ResumeData d) async {
    final text = await _ask(
      'Compare the job post with the CV below.\n'
      'List the skills the job post asks for: hard skills, tools, technologies, methods, certifications, '
      'spoken languages, and soft skills the post names explicitly. At most 20, most important first.\n'
      'Do NOT include cities, company names, benefits, job titles, years of experience, education levels, '
      'or generic words (e.g. "customer", "growth", "business").\n'
      'Use a short standard name for each skill (e.g. "React", "Microsoft Excel", "Komunikasi"), '
      'in the language the job post uses.\n'
      'Put a skill in "matched" if the CV clearly shows it, including synonyms or more specific versions '
      '(ReactJS counts as React). Otherwise put it in "missing".\n'
      'Answer with JSON only: {"matched": ["..."], "missing": ["..."]}\n\n'
      'Job post:\n$jobPost\n\nCV:\n${d.plainText}',
      maxTokens: 1200,
      json: true,
    );
    final j = _decodeJson(text);
    final matched = _strings(j['matched']);
    final missing = _strings(j['missing']).where((m) => !matched.contains(m)).toList();
    if (matched.isEmpty && missing.isEmpty) throw AiException('AI tidak menemukan skill di lowongan ini.');
    return KeywordMatch(matched: matched, missing: missing, byAi: true);
  }

  /// Rewrites the bullets of each entry (experience or project) toward the
  /// job post. Returns new bullets by entry id; entries the AI skipped or
  /// whose bullet count changed are left out.
  Future<Map<String, List<String>>> tailorBullets(
    String jobPost,
    Map<String, ({String title, List<String> bullets})> entries,
  ) async {
    final input = jsonEncode({
      'items': [
        for (final e in entries.entries) {'id': e.key, 'title': e.value.title, 'bullets': e.value.bullets},
      ],
    });
    final text = await _ask(
      'Rewrite the CV bullet points below so they target the job post.\n'
      'Rules:\n'
      '- Keep every item and the same number of bullets in the same order.\n'
      '- Keep the facts. Use the job post\'s terms only where they truly describe what the bullet already says.\n'
      '- Never add skills, tools, employers or numbers that are not in the original bullet; '
      'a bracketed placeholder like [X%] is allowed.\n'
      '- One line per bullet, strong action verb first, same language as the original bullet.\n'
      'Answer with JSON only, same shape as the input: {"items": [{"id": "...", "bullets": ["..."]}]}\n\n'
      'Job post:\n$jobPost\n\nInput:\n$input',
      maxTokens: 3000,
      json: true,
    );
    final out = <String, List<String>>{};
    for (final item in (_decodeJson(text)['items'] as List? ?? const []).whereType<Map>()) {
      final id = '${item['id']}';
      final bullets = _strings(item['bullets']);
      final before = entries[id]?.bullets;
      if (before != null && bullets.length == before.length) out[id] = bullets;
    }
    if (out.isEmpty) throw AiException('AI tidak memberi saran. Coba lagi.');
    return out;
  }
}
