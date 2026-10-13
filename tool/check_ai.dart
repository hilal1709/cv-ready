// Checks the AI key in .env.json with one tiny request.
// Run: dart run tool/check_ai.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main() async {
  final env = jsonDecode(File('.env.json').readAsStringSync()) as Map;
  final claude = '${env['ANTHROPIC_API_KEY'] ?? ''}';
  final gemini = '${env['GEMINI_API_KEY'] ?? ''}';
  final http.Response res;
  if (claude.isNotEmpty) {
    res = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {'content-type': 'application/json', 'x-api-key': claude, 'anthropic-version': '2023-06-01'},
      body: jsonEncode({
        'model': 'claude-opus-5-5',
        'max_tokens': 64,
        'messages': [
          {'role': 'user', 'content': 'Say OK.'},
        ],
      }),
    );
    stdout.writeln('Claude: HTTP ${res.statusCode}');
  } else if (gemini.isNotEmpty) {
    final model = '${env['GEMINI_MODEL'] ?? 'gemini-flash-latest'}';
    res = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
      headers: {'content-type': 'application/json', 'x-goog-api-key': gemini},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'Say OK.'},
            ],
          },
        ],
      }),
    );
    stdout.writeln('Gemini ($model): HTTP ${res.statusCode}');
  } else {
    stdout.writeln('No AI key in .env.json');
    return;
  }
  stdout.writeln(res.statusCode == 200 ? 'Key works.' : res.body);
}
