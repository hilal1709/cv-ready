import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lamar/data/models.dart';
import 'package:lamar/services/ats_scorer.dart';
import 'package:lamar/services/keyword_matcher.dart';
import 'package:lamar/services/pdf_builder.dart';
import 'package:lamar/services/updater.dart';

ResumeData sample() => ResumeData(
  contact: Contact(
    fullName: 'Hilal Andi',
    headline: 'Frontend Engineer',
    email: 'hilal@example.com',
    phone: '+62 812 3456 7890',
    location: 'Jakarta, Indonesia',
    linkedin: 'linkedin.com/in/hilalandi',
  ),
  summary:
      'Frontend engineer with 4 years of experience building fast, accessible web apps with React and '
      'TypeScript. Led the redesign of a checkout flow that lifted conversion by 18%. Comfortable working '
      'with designers, product managers and backend teams across time zones.',
  experiences: [
    Experience(
      role: 'Frontend Engineer',
      company: 'PT Contoh Teknologi',
      location: 'Jakarta',
      start: 'Jan 2022',
      current: true,
      bullets: [
        'Led a React and TypeScript rewrite of the checkout, increasing conversion by 18% in 3 months.',
        'Reduced bundle size by 42% through code splitting and image optimization across 30 pages.',
        'Mentored 3 junior engineers and introduced component testing with 85% coverage.',
      ],
    ),
    Experience(
      role: 'Web Developer Intern',
      company: 'Startup Satu',
      start: 'Jun 2021',
      end: 'Dec 2021',
      bullets: [
        'Built 12 landing pages in Next.js that served 50,000 monthly visitors.',
        'Automated weekly reporting with Google Sheets scripts, saving 4 hours per week.',
      ],
    ),
  ],
  education: [
    Education(
      school: 'Universitas Indonesia',
      degree: 'Bachelor of Science',
      field: 'Computer Science',
      start: '2017',
      end: '2021',
      gpa: '3.65/4.00',
    ),
  ],
  skills: ['React', 'TypeScript', 'Next.js', 'HTML', 'CSS', 'Jest', 'Figma', 'Git', 'REST APIs', 'Accessibility'],
  certifications: [Certification(name: 'Meta Front-End Developer', issuer: 'Coursera', year: '2023')],
  languages: [
    LanguageSkill(name: 'Indonesian', level: 'Native'),
    LanguageSkill(name: 'English', level: 'Professional'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('empty CV scores low, complete CV scores high', () {
    expect(AtsScorer.score(ResumeData()).percent, lessThan(15));
    final full = AtsScorer.score(sample());
    expect(full.percent, greaterThanOrEqualTo(85), reason: full.todo.map((c) => '${c.title}: ${c.tip}').join('\n'));
  });

  test('keyword matcher finds missing terms', () {
    const job =
        'We are hiring a Frontend Engineer to build our design system. You will work with React, TypeScript '
        'and GraphQL every day. Experience with GraphQL and Storybook is a must. You will write unit tests with Jest, '
        'care about accessibility, and collaborate with designers in Figma. Bonus: experience with AWS.';
    final m = KeywordMatcher.match(job, sample().plainText);
    expect(m.missing, contains('graphql'));
    expect(m.matched, contains('react'));
    expect(m.percent, inInclusiveRange(1, 99));
  });

  test('PDF renders for every template with real text', () async {
    final out = Directory('design/preview/pdf')..createSync(recursive: true);
    for (final t in CvTemplate.values) {
      final r = Resume(
        id: 'x',
        title: 'Test',
        template: t,
        data: sample(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final bytes = await PdfBuilder.build(r);
      expect(bytes.length, greaterThan(2000));
      File('${out.path}/${t.id}.pdf').writeAsBytesSync(bytes);
    }
  });

  test('update version comparison is numeric, not lexical', () {
    expect(Updater.compareVersions('1.10.0', '1.9.2'), 1);
    expect(Updater.compareVersions('1.0.0', '1.0.0+5'), 0);
    expect(Updater.compareVersions('1.0.1', '1.0.2'), -1);
    expect(Updater.compareVersions('2.0', '1.9.9'), 1);
  });
}
