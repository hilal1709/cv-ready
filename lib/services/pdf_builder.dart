import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models.dart';

/// Renders a CV to an ATS-safe PDF: real selectable text, one column,
/// standard English section headings, no tables, images or text boxes.
class PdfBuilder {
  static final Map<String, pw.Font> _fonts = {};

  static Future<pw.Font> _font(String file) async =>
      _fonts[file] ??= pw.Font.ttf(await rootBundle.load('assets/fonts/$file'));

  static Future<Uint8List> build(Resume resume, {CvTemplate? template}) async {
    final t = template ?? resume.template;
    final serif = t == CvTemplate.harvard;
    final family = serif ? 'Tinos' : 'Carlito';
    final style = _Style.of(t);
    final theme = pw.ThemeData.withFont(
      base: await _font('$family-400-normal.ttf'),
      bold: await _font('$family-700-normal.ttf'),
      italic: await _font('$family-400-italic.ttf'),
    );

    final d = resume.data;
    final doc = pw.Document(
      title: '${d.contact.fullName.isEmpty ? resume.title : d.contact.fullName} - CV',
      author: d.contact.fullName,
      creator: 'CV Ready',
      subject: d.contact.headline,
      keywords: d.skills.join(', '),
    );

    final sections = <String, List<pw.Widget>>{
      'summary': _summary(d, style),
      'experience': _experience(d, style),
      'education': _education(d, style),
      'skills': _skills(d, style),
      'projects': _projects(d, style),
      'certifications': _certifications(d, style),
      'languages': _languages(d, style),
    };
    final order = t == CvTemplate.executive
        ? ['summary', 'skills', 'experience', 'projects', 'education', 'certifications', 'languages']
        : ['summary', 'experience', 'education', 'skills', 'projects', 'certifications', 'languages'];

    doc.addPage(
      pw.MultiPage(
        theme: theme.copyWith(
          defaultTextStyle: pw.TextStyle(fontSize: style.body, lineSpacing: style.leading),
        ),
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: style.marginX, vertical: style.marginY),
        build: (_) => [..._header(d, style), for (final key in order) ...sections[key]!],
      ),
    );
    return doc.save();
  }

  // ------------------------------------------------------------ pieces ---
  static List<pw.Widget> _header(ResumeData d, _Style s) {
    final c = d.contact;
    final contact = [
      c.email,
      c.phone,
      c.location,
      c.linkedin,
      c.website,
    ].where((e) => e.trim().isNotEmpty).join('  |  ');
    final align = s.centerName ? pw.CrossAxisAlignment.center : pw.CrossAxisAlignment.start;
    final textAlign = s.centerName ? pw.TextAlign.center : pw.TextAlign.left;
    return [
      pw.SizedBox(
        width: double.infinity,
        child: pw.Column(
          crossAxisAlignment: align,
          children: [
            pw.Text(
              c.fullName.isEmpty ? 'Your Name' : c.fullName.trim(),
              textAlign: textAlign,
              style: pw.TextStyle(fontSize: s.name, fontWeight: pw.FontWeight.bold, color: s.ink),
            ),
            if (c.headline.trim().isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(
                  c.headline,
                  textAlign: textAlign,
                  style: pw.TextStyle(fontSize: s.body + 1.5, color: s.accent),
                ),
              ),
            if (contact.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  contact,
                  textAlign: textAlign,
                  style: pw.TextStyle(fontSize: s.body - 0.5, color: s.muted),
                ),
              ),
          ],
        ),
      ),
      pw.SizedBox(height: s.gap),
    ];
  }

  static pw.Widget _heading(String title, _Style s) => pw.Container(
    width: double.infinity,
    margin: pw.EdgeInsets.only(top: s.gap, bottom: s.gap * 0.45),
    padding: const pw.EdgeInsets.only(bottom: 2),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: s.rule, width: 0.8)),
    ),
    child: pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(fontSize: s.heading, fontWeight: pw.FontWeight.bold, color: s.accent, letterSpacing: 0.8),
    ),
  );

  static pw.Widget _lineWithDate(String left, String right, _Style s, {bool bold = true}) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Text(
          left,
          style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null, color: s.ink),
        ),
      ),
      if (right.isNotEmpty) pw.Text(right, style: pw.TextStyle(color: s.muted)),
    ],
  );

  static pw.Widget _bullet(String text, _Style s) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 1.5, left: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 10,
          child: pw.Text('•', style: pw.TextStyle(color: s.ink)),
        ),
        pw.Expanded(
          child: pw.Text(text.trim(), style: pw.TextStyle(color: s.ink)),
        ),
      ],
    ),
  );

  static List<pw.Widget> _summary(ResumeData d, _Style s) => d.summary.trim().isEmpty
      ? []
      : [_heading('Professional Summary', s), pw.Text(d.summary.trim(), style: pw.TextStyle(color: s.ink))];

  static List<pw.Widget> _experience(ResumeData d, _Style s) {
    final items = d.experiences.where((e) => e.role.trim().isNotEmpty || e.company.trim().isNotEmpty).toList();
    if (items.isEmpty) return [];
    return [
      _heading('Experience', s),
      for (final e in items)
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: s.gap * 0.6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _lineWithDate([e.role, e.company].where((x) => x.trim().isNotEmpty).join(', '), e.period, s),
              if (e.location.trim().isNotEmpty)
                pw.Text(
                  e.location,
                  style: pw.TextStyle(color: s.muted, fontStyle: pw.FontStyle.italic),
                ),
              for (final b in e.bullets.where((b) => b.trim().isNotEmpty)) _bullet(b, s),
            ],
          ),
        ),
    ];
  }

  static List<pw.Widget> _education(ResumeData d, _Style s) {
    final items = d.education.where((e) => e.school.trim().isNotEmpty).toList();
    if (items.isEmpty) return [];
    return [
      _heading('Education', s),
      for (final e in items)
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: s.gap * 0.5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _lineWithDate(e.school, e.period, s),
              pw.Text(
                [
                  [e.degree, e.field].where((x) => x.trim().isNotEmpty).join(' in '),
                  if (e.gpa.trim().isNotEmpty) 'GPA ${e.gpa}',
                ].where((x) => x.isNotEmpty).join('  |  '),
                style: pw.TextStyle(color: s.ink),
              ),
              if (e.details.trim().isNotEmpty) pw.Text(e.details, style: pw.TextStyle(color: s.muted)),
            ],
          ),
        ),
    ];
  }

  static List<pw.Widget> _skills(ResumeData d, _Style s) {
    final skills = d.skills.where((e) => e.trim().isNotEmpty).toList();
    if (skills.isEmpty) return [];
    return [_heading('Skills', s), pw.Text(skills.join(', '), style: pw.TextStyle(color: s.ink))];
  }

  static List<pw.Widget> _projects(ResumeData d, _Style s) {
    final items = d.projects.where((p) => p.name.trim().isNotEmpty).toList();
    if (items.isEmpty) return [];
    return [
      _heading('Projects', s),
      for (final p in items)
        pw.Padding(
          padding: pw.EdgeInsets.only(bottom: s.gap * 0.5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _lineWithDate(p.name, p.link, s),
              for (final b in p.bullets.where((b) => b.trim().isNotEmpty)) _bullet(b, s),
            ],
          ),
        ),
    ];
  }

  static List<pw.Widget> _certifications(ResumeData d, _Style s) {
    final items = d.certifications.where((c) => c.name.trim().isNotEmpty).toList();
    if (items.isEmpty) return [];
    return [
      _heading('Certifications', s),
      for (final c in items)
        _lineWithDate([c.name, c.issuer].where((x) => x.trim().isNotEmpty).join(', '), c.year, s, bold: false),
    ];
  }

  static List<pw.Widget> _languages(ResumeData d, _Style s) {
    final items = d.languages.where((l) => l.name.trim().isNotEmpty).toList();
    if (items.isEmpty) return [];
    return [
      _heading('Languages', s),
      pw.Text(
        items.map((l) => l.level.trim().isEmpty ? l.name : '${l.name} (${l.level})').join(', '),
        style: pw.TextStyle(color: s.ink),
      ),
    ];
  }
}

class _Style {
  const _Style({
    required this.name,
    required this.heading,
    required this.body,
    required this.leading,
    required this.gap,
    required this.marginX,
    required this.marginY,
    required this.centerName,
    required this.accent,
  });
  final double name, heading, body, leading, gap, marginX, marginY;
  final bool centerName;
  final PdfColor accent;
  PdfColor get ink => PdfColor.fromHex('#1C1A19');
  PdfColor get muted => PdfColor.fromHex('#4A4644');
  PdfColor get rule => PdfColor.fromHex('#8C8784');

  static _Style of(CvTemplate t) => switch (t) {
    CvTemplate.harvard => _Style(
      name: 22,
      heading: 11.5,
      body: 10.5,
      leading: 1.5,
      gap: 10,
      marginX: 48,
      marginY: 42,
      centerName: true,
      accent: PdfColor.fromHex('#1C1A19'),
    ),
    CvTemplate.modern => _Style(
      name: 24,
      heading: 11,
      body: 10.5,
      leading: 1.8,
      gap: 11,
      marginX: 46,
      marginY: 40,
      centerName: false,
      accent: PdfColor.fromHex('#1D5C46'),
    ),
    CvTemplate.compact => _Style(
      name: 19,
      heading: 10,
      body: 9.5,
      leading: 1.1,
      gap: 7,
      marginX: 36,
      marginY: 30,
      centerName: false,
      accent: PdfColor.fromHex('#1C1A19'),
    ),
    CvTemplate.executive => _Style(
      name: 23,
      heading: 11,
      body: 10.5,
      leading: 1.6,
      gap: 10,
      marginX: 50,
      marginY: 44,
      centerName: true,
      accent: PdfColor.fromHex('#3A2A22'),
    ),
  };
}
