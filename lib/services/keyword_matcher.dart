import 'skill_dictionary.dart';

class KeywordMatch {
  KeywordMatch({required this.matched, required this.missing, this.byAi = false});
  final List<String> matched;
  final List<String> missing;

  /// True when the AI read the job post; false for the offline dictionary.
  final bool byAi;

  int get total => matched.length + missing.length;
  int get percent => total == 0 ? 0 : (matched.length * 100 / total).round();
}

/// Offline skill matching: finds the skills from [skillDictionary] that a job
/// post asks for and checks which of them the CV shows. Used when the AI is
/// off or fails, so it only ever reports real skills, never random words.
class KeywordMatcher {
  /// Aliases that are also everyday words ("excel at", "accurate data");
  /// they only count when written capitalised, as a product name.
  static const _caseSensitive = {
    'excel', 'swift', 'spring', 'sketch', 'notion', 'rust', 'accurate', 'ruby', 'express', 'flask',
    'spark', 'jest', 'looker', 'oracle', 'canva', 'go lang', 'go', 'r', 'c', 'lean',
  };

  static final _patterns = <String, List<RegExp>>{
    for (final e in skillDictionary.entries)
      e.key: [
        for (final alias in {e.key.toLowerCase(), ...e.value})
          _caseSensitive.contains(alias)
              ? RegExp('(?<![A-Za-z0-9+#])${RegExp.escape('${alias[0].toUpperCase()}${alias.substring(1)}')}(?![A-Za-z0-9+#])')
              : RegExp('(?<![A-Za-z0-9+#])${RegExp.escape(alias)}(?![A-Za-z0-9+#])', caseSensitive: false),
      ],
  };

  /// First position of [skill] in [text], or -1.
  static int _find(String skill, String text) {
    var best = -1;
    for (final p in _patterns[skill]!) {
      final m = p.firstMatch(text);
      if (m != null && (best == -1 || m.start < best)) best = m.start;
    }
    return best;
  }

  /// Skills the job post mentions, in the order it mentions them.
  static List<String> extract(String jobText, {int limit = 24}) {
    final found = <(String, int)>[];
    for (final skill in skillDictionary.keys) {
      final at = _find(skill, jobText);
      if (at >= 0) found.add((skill, at));
    }
    found.sort((a, b) => a.$2.compareTo(b.$2));
    return found.take(limit).map((f) => f.$1).toList();
  }

  static KeywordMatch match(String jobText, String cvText) {
    final matched = <String>[];
    final missing = <String>[];
    for (final skill in extract(jobText)) {
      (_find(skill, cvText) >= 0 ? matched : missing).add(skill);
    }
    return KeywordMatch(matched: matched, missing: missing);
  }
}
