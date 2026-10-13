import 'package:flutter_test/flutter_test.dart';
import 'package:lamar/services/keyword_matcher.dart';

void main() {
  test('offline matcher finds real skills, not random words', () {
    const job = 'Kami mencari Frontend Developer di Jakarta. Kualifikasi: menguasai ReactJS dan TypeScript, '
        'terbiasa dengan Excel, kemampuan komunikasi yang baik, customer oriented, growth mindset, '
        'mampu excel at teamwork. Benefit: BPJS, bonus tahunan.';
    const cv = 'Built dashboards with React.js. Strong communication with stakeholders.';
    final m = KeywordMatcher.match(job, cv);
    final all = [...m.matched, ...m.missing];
    expect(all, containsAll(['React', 'TypeScript', 'Microsoft Excel', 'Communication', 'Teamwork']));
    expect(all.map((s) => s.toLowerCase()), isNot(anyOf(contains('jakarta'), contains('customer'), contains('growth'))));
    expect(m.matched, containsAll(['React', 'Communication']));
    expect(m.missing, contains('TypeScript'));
  });

  test('"excel at" alone is not Microsoft Excel', () {
    expect(KeywordMatcher.extract('Candidates who excel at sales.'), isNot(contains('Microsoft Excel')));
  });
}
