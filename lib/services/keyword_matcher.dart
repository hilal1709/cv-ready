class KeywordMatch {
  const KeywordMatch({required this.matched, required this.missing});
  final List<String> matched;
  final List<String> missing;

  int get total => matched.length + missing.length;
  int get percent => total == 0 ? 0 : (matched.length * 100 / total).round();
}

/// Pulls the terms a job post repeats or emphasises and checks which of them
/// appear in the CV. Works for English and Indonesian postings.
class KeywordMatcher {
  static const _stop = {
    // English
    'a', 'about', 'above', 'across', 'after', 'all', 'also', 'an', 'and', 'any', 'are', 'as', 'at', 'be',
    'been', 'being', 'both', 'but', 'by', 'can', 'candidate', 'candidates', 'company', 'could', 'day', 'do',
    'does', 'each', 'etc', 'every', 'experience', 'for', 'from', 'good', 'great', 'has', 'have', 'help',
    'high', 'how', 'ideal', 'if', 'in', 'including', 'into', 'is', 'it', 'its', 'job', 'join', 'just',
    'least', 'like', 'looking', 'make', 'may', 'more', 'most', 'must', 'new', 'nice', 'not', 'of', 'on',
    'one', 'or', 'other', 'our', 'out', 'over', 'own', 'part', 'per', 'plus', 'preferred', 'role', 'so',
    'some', 'strong', 'such', 'team', 'teams', 'than', 'that', 'the', 'their', 'them', 'then', 'there',
    'these', 'they', 'this', 'through', 'to', 'time', 'up', 'us', 'use', 'using', 'very', 'want', 'was',
    'we', 'well', 'were', 'what', 'when', 'where', 'which', 'while', 'who', 'will', 'with', 'within',
    'work', 'working', 'would', 'year', 'years', 'you', 'your', 'able', 'ability', 'responsibilities',
    'requirements', 'qualifications', 'skills', 'knowledge', 'understanding', 'minimum', 'related',
    'relevant', 'equivalent', 'degree', 'bachelor', 'benefits', 'apply', 'opportunity', 'position',
    'responsible', 'ensure', 'based', 'level', 'environment',
    // Indonesian
    'ada', 'adalah', 'agar', 'akan', 'antara', 'atau', 'bagi', 'bahwa', 'baik', 'bersama', 'bisa', 'dalam',
    'dan', 'dapat', 'dari', 'dengan', 'di', 'diutamakan', 'hal', 'harus', 'ini', 'itu', 'jika', 'juga',
    'kami', 'kamu', 'ke', 'kepada', 'lebih', 'maupun', 'memiliki', 'menjadi', 'mampu', 'minimal', 'oleh',
    'pada', 'para', 'pengalaman', 'perusahaan', 'sebagai', 'secara', 'sesuai', 'serta', 'tahun', 'tanggung',
    'jawab', 'tentang', 'terhadap', 'tim', 'untuk', 'yang', 'kualifikasi', 'persyaratan', 'kandidat',
    'pekerjaan', 'posisi', 'kerja', 'tinggi', 'sangat', 'setiap', 'sudah', 'telah', 'tidak',
  };

  static final _token = RegExp(r"[a-zA-Z][a-zA-Z0-9+#./\-]*[a-zA-Z0-9+#]|[a-zA-Z]");

  static List<String> _tokens(String text) => _token.allMatches(text).map((m) => m.group(0)!.toLowerCase()).toList();

  static List<String> extract(String jobText, {int limit = 24}) {
    final tokens = _tokens(jobText);
    final freq = <String, double>{};
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (t.length < 2 || _stop.contains(t) || RegExp(r'^\d').hasMatch(t)) continue;
      // Short tokens only count when they look like tech terms (c#, go, ui, qa).
      if (t.length <= 2 &&
          !RegExp(r'[+#]').hasMatch(t) &&
          !{'ui', 'ux', 'qa', 'ai', 'ml', 'go', 'r', 'hr', 'pr', 'bi'}.contains(t)) {
        continue;
      }
      freq[t] = (freq[t] ?? 0) + 1;
      if (i + 1 < tokens.length) {
        final n = tokens[i + 1];
        if (!_stop.contains(n) && n.length > 2) {
          final bi = '$t $n';
          freq[bi] = (freq[bi] ?? 0) + 1.6; // phrases outrank their parts
        }
      }
    }
    // Capitalised mid-sentence words in the source are usually tools/brands.
    for (final m in RegExp(r'(?<=[a-z,;:]\s)([A-Z][a-zA-Z0-9+#.]+)').allMatches(jobText)) {
      final w = m.group(1)!.toLowerCase();
      if (!_stop.contains(w)) freq[w] = (freq[w] ?? 0) + 1.5;
    }
    final ranked = freq.entries.where((e) => e.value >= 1.5 || !e.key.contains(' ')).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final picked = <String>[];
    for (final e in ranked) {
      if (picked.length >= limit) break;
      // Skip a word already covered by a picked phrase, and vice versa.
      if (picked.any((p) => p.split(' ').contains(e.key) || e.key.split(' ').contains(p))) continue;
      picked.add(e.key);
    }
    return picked;
  }

  static KeywordMatch match(String jobText, String cvText) {
    final cv = ' ${_tokens(cvText).join(' ')} ';
    final keys = extract(jobText);
    final matched = <String>[];
    final missing = <String>[];
    for (final k in keys) {
      (cv.contains(' $k ') ? matched : missing).add(k);
    }
    return KeywordMatch(matched: matched, missing: missing);
  }
}
