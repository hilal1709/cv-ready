import 'dart:convert';

class AppUser {
  const AppUser({required this.id, required this.email, required this.fullName});
  final String id;
  final String email;
  final String fullName;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'fullName': fullName};
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(id: j['id'], email: j['email'], fullName: j['fullName']);
}

List<String> _strings(dynamic v) => (v as List? ?? const []).map((e) => '$e').toList();
String _s(dynamic v) => v == null ? '' : '$v';

class Contact {
  Contact({
    this.fullName = '',
    this.headline = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.website = '',
  });
  String fullName, headline, email, phone, location, linkedin, website;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'headline': headline,
    'email': email,
    'phone': phone,
    'location': location,
    'linkedin': linkedin,
    'website': website,
  };
  factory Contact.fromJson(Map<String, dynamic>? j) {
    j ??= const {};
    return Contact(
      fullName: _s(j['fullName']),
      headline: _s(j['headline']),
      email: _s(j['email']),
      phone: _s(j['phone']),
      location: _s(j['location']),
      linkedin: _s(j['linkedin']),
      website: _s(j['website']),
    );
  }
}

class Experience {
  Experience({
    this.role = '',
    this.company = '',
    this.location = '',
    this.start = '',
    this.end = '',
    this.current = false,
    List<String>? bullets,
  }) : bullets = bullets ?? [];
  String role, company, location, start, end;
  bool current;
  List<String> bullets;

  String get period => [start, current ? 'Present' : end].where((e) => e.trim().isNotEmpty).join(' – ');

  Map<String, dynamic> toJson() => {
    'role': role,
    'company': company,
    'location': location,
    'start': start,
    'end': end,
    'current': current,
    'bullets': bullets,
  };
  factory Experience.fromJson(Map<String, dynamic> j) => Experience(
    role: _s(j['role']),
    company: _s(j['company']),
    location: _s(j['location']),
    start: _s(j['start']),
    end: _s(j['end']),
    current: j['current'] == true,
    bullets: _strings(j['bullets']),
  );
}

class Education {
  Education({
    this.school = '',
    this.degree = '',
    this.field = '',
    this.start = '',
    this.end = '',
    this.gpa = '',
    this.details = '',
  });
  String school, degree, field, start, end, gpa, details;

  String get period => [start, end].where((e) => e.trim().isNotEmpty).join(' – ');

  Map<String, dynamic> toJson() => {
    'school': school,
    'degree': degree,
    'field': field,
    'start': start,
    'end': end,
    'gpa': gpa,
    'details': details,
  };
  factory Education.fromJson(Map<String, dynamic> j) => Education(
    school: _s(j['school']),
    degree: _s(j['degree']),
    field: _s(j['field']),
    start: _s(j['start']),
    end: _s(j['end']),
    gpa: _s(j['gpa']),
    details: _s(j['details']),
  );
}

class Project {
  Project({this.name = '', this.link = '', List<String>? bullets}) : bullets = bullets ?? [];
  String name, link;
  List<String> bullets;

  Map<String, dynamic> toJson() => {'name': name, 'link': link, 'bullets': bullets};
  factory Project.fromJson(Map<String, dynamic> j) =>
      Project(name: _s(j['name']), link: _s(j['link']), bullets: _strings(j['bullets']));
}

class Certification {
  Certification({this.name = '', this.issuer = '', this.year = ''});
  String name, issuer, year;

  Map<String, dynamic> toJson() => {'name': name, 'issuer': issuer, 'year': year};
  factory Certification.fromJson(Map<String, dynamic> j) =>
      Certification(name: _s(j['name']), issuer: _s(j['issuer']), year: _s(j['year']));
}

class LanguageSkill {
  LanguageSkill({this.name = '', this.level = ''});
  String name, level;

  Map<String, dynamic> toJson() => {'name': name, 'level': level};
  factory LanguageSkill.fromJson(Map<String, dynamic> j) => LanguageSkill(name: _s(j['name']), level: _s(j['level']));
}

/// The full CV content, stored as one JSONB document per resume.
class ResumeData {
  ResumeData({
    Contact? contact,
    this.summary = '',
    List<Experience>? experiences,
    List<Education>? education,
    List<String>? skills,
    List<Project>? projects,
    List<Certification>? certifications,
    List<LanguageSkill>? languages,
  }) : contact = contact ?? Contact(),
       experiences = experiences ?? [],
       education = education ?? [],
       skills = skills ?? [],
       projects = projects ?? [],
       certifications = certifications ?? [],
       languages = languages ?? [];

  Contact contact;
  String summary;
  List<Experience> experiences;
  List<Education> education;
  List<String> skills;
  List<Project> projects;
  List<Certification> certifications;
  List<LanguageSkill> languages;

  Map<String, dynamic> toJson() => {
    'contact': contact.toJson(),
    'summary': summary,
    'experiences': experiences.map((e) => e.toJson()).toList(),
    'education': education.map((e) => e.toJson()).toList(),
    'skills': skills,
    'projects': projects.map((e) => e.toJson()).toList(),
    'certifications': certifications.map((e) => e.toJson()).toList(),
    'languages': languages.map((e) => e.toJson()).toList(),
  };

  factory ResumeData.fromJson(Map<String, dynamic>? j) {
    j ??= const {};
    List<Map<String, dynamic>> maps(dynamic v) =>
        (v as List? ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    return ResumeData(
      contact: Contact.fromJson(j['contact'] == null ? null : Map<String, dynamic>.from(j['contact'])),
      summary: _s(j['summary']),
      experiences: maps(j['experiences']).map(Experience.fromJson).toList(),
      education: maps(j['education']).map(Education.fromJson).toList(),
      skills: _strings(j['skills']),
      projects: maps(j['projects']).map(Project.fromJson).toList(),
      certifications: maps(j['certifications']).map(Certification.fromJson).toList(),
      languages: maps(j['languages']).map(LanguageSkill.fromJson).toList(),
    );
  }

  ResumeData clone() => ResumeData.fromJson(jsonDecode(jsonEncode(toJson())));

  /// Every word of the CV, for keyword matching and length checks.
  String get plainText {
    final b = StringBuffer()
      ..writeln(contact.fullName)
      ..writeln(contact.headline)
      ..writeln(summary);
    for (final e in experiences) {
      b.writeln('${e.role} ${e.company} ${e.location}');
      e.bullets.forEach(b.writeln);
    }
    for (final e in education) {
      b.writeln('${e.degree} ${e.field} ${e.school} ${e.details}');
    }
    b.writeln(skills.join(', '));
    for (final p in projects) {
      b.writeln(p.name);
      p.bullets.forEach(b.writeln);
    }
    for (final c in certifications) {
      b.writeln('${c.name} ${c.issuer}');
    }
    for (final l in languages) {
      b.writeln('${l.name} ${l.level}');
    }
    return b.toString();
  }
}

enum CvTemplate {
  harvard('harvard', 'Harvard Classic', 'Serif klasik, nama di tengah. Aman untuk semua industri.'),
  modern('modern', 'Modern Clean', 'Sans-serif lega, nama rata kiri. Cocok untuk tech & kreatif.'),
  compact('compact', 'Compact', 'Padat, muat lebih banyak di 1 halaman. Untuk pengalaman panjang.'),
  executive('executive', 'Executive', 'Ringkasan & keahlian di atas. Untuk posisi senior.');

  const CvTemplate(this.id, this.label, this.description);
  final String id;
  final String label;
  final String description;

  static CvTemplate byId(String id) => values.firstWhere((t) => t.id == id, orElse: () => harvard);
}

class Resume {
  Resume({
    required this.id,
    required this.title,
    required this.template,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  String title;
  CvTemplate template;
  ResumeData data;
  final DateTime createdAt;
  DateTime updatedAt;
}
