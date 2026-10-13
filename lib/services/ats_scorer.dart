import '../data/models.dart';

enum CheckStatus { pass, partial, fail }

class AtsCheck {
  const AtsCheck({
    required this.title,
    required this.status,
    required this.points,
    required this.maxPoints,
    required this.tip,
    this.section,
  });
  final String title;
  final CheckStatus status;
  final int points;
  final int maxPoints;

  /// What to do next, in plain Indonesian.
  final String tip;

  /// Which editor section fixes this (for "Perbaiki" deep links).
  final String? section;
}

class AtsReport {
  const AtsReport(this.checks);
  final List<AtsCheck> checks;

  int get score => checks.fold(0, (s, c) => s + c.points);
  int get max => checks.fold(0, (s, c) => s + c.maxPoints);
  int get percent => max == 0 ? 0 : (score * 100 / max).round();
  List<AtsCheck> get todo => checks.where((c) => c.status != CheckStatus.pass).toList();

  String get verdict => switch (percent) {
    >= 85 => 'Siap kirim',
    >= 70 => 'Hampir siap',
    >= 45 => 'Perlu dipoles',
    _ => 'Baru dimulai',
  };
}

/// Heuristic ATS readiness score. It checks what recruiters' parsers and
/// screeners reward: complete contact data, a focused summary, dated roles,
/// bullets that start with action verbs and carry numbers, and enough skills.
class AtsScorer {
  static const actionVerbs = {
    'achieved', 'accelerated', 'analyzed', 'architected', 'automated', 'boosted', 'built', 'championed',
    'collaborated', 'conducted', 'consolidated', 'coordinated', 'created', 'cut', 'decreased', 'defined',
    'delivered', 'deployed', 'designed', 'developed', 'directed', 'drove', 'eliminated', 'enabled',
    'engineered', 'established', 'evaluated', 'executed', 'expanded', 'facilitated', 'founded', 'generated',
    'grew', 'guided', 'handled', 'headed', 'identified', 'implemented', 'improved', 'increased', 'initiated',
    'introduced', 'launched', 'led', 'maintained', 'managed', 'mentored', 'migrated', 'modernized',
    'negotiated', 'optimized', 'orchestrated', 'organized', 'oversaw', 'owned', 'pioneered', 'planned',
    'prepared', 'presented', 'prioritized', 'produced', 'programmed', 'published', 'raised', 'redesigned',
    'reduced', 'refactored', 'resolved', 'restructured', 'revamped', 'saved', 'scaled', 'secured',
    'served', 'shipped', 'simplified', 'spearheaded', 'streamlined', 'strengthened', 'supervised',
    'supported', 'taught', 'tested', 'trained', 'transformed', 'translated', 'tripled', 'doubled', 'unified',
    'upgraded', 'won', 'wrote',
    // Bahasa Indonesia (for CVs written in Indonesian)
    'memimpin', 'mengembangkan', 'merancang', 'membangun', 'meningkatkan', 'mengurangi', 'mengelola',
    'menyusun', 'meluncurkan', 'mengoptimalkan', 'menganalisis', 'mengotomatisasi', 'menerapkan',
    'mengkoordinasikan', 'membimbing', 'melatih', 'menghemat', 'menjual', 'menangani', 'membuat',
  };

  static final _number = RegExp(r'(\d|%|\$|rp\b|idr|usd|x\b)', caseSensitive: false);
  static final _firstPerson = RegExp(r'\b(i|me|my|saya|aku)\b', caseSensitive: false);

  static int _words(String s) => s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;

  static AtsReport score(ResumeData d) {
    final checks = <AtsCheck>[];
    final c = d.contact;

    // Contact (14)
    final missing = <String>[
      if (c.fullName.trim().isEmpty) 'nama',
      if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(c.email.trim())) 'email',
      if (c.phone.replaceAll(RegExp(r'\D'), '').length < 8) 'telepon',
      if (c.location.trim().isEmpty) 'kota',
    ];
    checks.add(
      AtsCheck(
        title: 'Kontak lengkap',
        status: missing.isEmpty ? CheckStatus.pass : (missing.length <= 2 ? CheckStatus.partial : CheckStatus.fail),
        points: ((4 - missing.length) / 4 * 11).round(),
        maxPoints: 11,
        tip: missing.isEmpty
            ? 'Nama, email, telepon, dan kota terbaca jelas oleh parser.'
            : 'Lengkapi ${missing.join(', ')}. Recruiter dan ATS butuh ini untuk menghubungimu.',
        section: 'contact',
      ),
    );
    checks.add(
      AtsCheck(
        title: 'Profil LinkedIn',
        status: c.linkedin.trim().isEmpty ? CheckStatus.partial : CheckStatus.pass,
        points: c.linkedin.trim().isEmpty ? 0 : 3,
        maxPoints: 3,
        tip: c.linkedin.trim().isEmpty
            ? 'Tambahkan URL LinkedIn. Hampir semua recruiter internasional mengeceknya.'
            : 'LinkedIn tercantum.',
        section: 'contact',
      ),
    );

    // Summary (10)
    final sw = _words(d.summary);
    checks.add(
      AtsCheck(
        title: 'Ringkasan profesional',
        status: sw >= 30 && sw <= 90 ? CheckStatus.pass : (sw > 0 ? CheckStatus.partial : CheckStatus.fail),
        points: sw >= 30 && sw <= 90 ? 10 : (sw > 0 ? 5 : 0),
        maxPoints: 10,
        tip: switch (sw) {
          0 => 'Tulis 2–4 kalimat: siapa kamu, keahlian utama, dan hasil terbaikmu.',
          < 30 => 'Ringkasan terlalu pendek ($sw kata). Idealnya 30–90 kata.',
          > 90 => 'Ringkasan terlalu panjang ($sw kata). Padatkan jadi 30–90 kata.',
          _ => 'Panjang ringkasan pas ($sw kata).',
        },
        section: 'summary',
      ),
    );

    // Experience (15 + 6 dates)
    final exp = d.experiences.where((e) => e.role.trim().isNotEmpty || e.company.trim().isNotEmpty).toList();
    checks.add(
      AtsCheck(
        title: 'Pengalaman kerja',
        status: exp.isEmpty
            ? CheckStatus.fail
            : (exp.every((e) => e.bullets.length >= 2) ? CheckStatus.pass : CheckStatus.partial),
        points: exp.isEmpty ? 0 : (exp.every((e) => e.bullets.length >= 2) ? 15 : 9),
        maxPoints: 15,
        tip: exp.isEmpty
            ? 'Tambahkan minimal satu pengalaman (kerja, magang, organisasi, atau freelance).'
            : exp.every((e) => e.bullets.length >= 2)
            ? '${exp.length} pengalaman, masing-masing punya poin pencapaian.'
            : 'Beri setiap pengalaman 2–5 poin pencapaian.',
        section: 'experience',
      ),
    );
    final undated = exp.where((e) => e.start.trim().isEmpty || (!e.current && e.end.trim().isEmpty)).length;
    checks.add(
      AtsCheck(
        title: 'Tanggal di setiap peran',
        status: exp.isEmpty ? CheckStatus.fail : (undated == 0 ? CheckStatus.pass : CheckStatus.partial),
        points: exp.isEmpty ? 0 : (undated == 0 ? 6 : 3),
        maxPoints: 6,
        tip: undated == 0 && exp.isNotEmpty
            ? 'Semua peran punya periode yang jelas.'
            : 'Isi bulan & tahun mulai/selesai (contoh: Jan 2023). ATS menghitung lama pengalaman dari sini.',
        section: 'experience',
      ),
    );

    // Bullet quality (10 verbs + 10 metrics + 5 length)
    final bullets = [
      ...exp.expand((e) => e.bullets),
      ...d.projects.expand((p) => p.bullets),
    ].where((b) => b.trim().isNotEmpty).toList();
    if (bullets.isEmpty) {
      checks.add(
        const AtsCheck(
          title: 'Poin pencapaian',
          status: CheckStatus.fail,
          points: 0,
          maxPoints: 25,
          tip: 'Belum ada poin. Tulis apa yang kamu capai, bukan hanya tugas.',
          section: 'experience',
        ),
      );
    } else {
      final verbRate =
          bullets.where((b) {
            final first = b.trim().split(RegExp(r'\s+')).first.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
            return actionVerbs.contains(first);
          }).length /
          bullets.length;
      checks.add(
        AtsCheck(
          title: 'Diawali kata kerja aksi',
          status: verbRate >= 0.7 ? CheckStatus.pass : (verbRate >= 0.35 ? CheckStatus.partial : CheckStatus.fail),
          points: (verbRate * 10).round().clamp(0, 10),
          maxPoints: 10,
          tip: verbRate >= 0.7
              ? '${(verbRate * 100).round()}% poin dimulai dengan kata kerja kuat.'
              : 'Mulai tiap poin dengan kata kerja: Led, Built, Increased, Reduced… (${(verbRate * 100).round()}% sekarang).',
          section: 'experience',
        ),
      );
      final metricRate = bullets.where(_number.hasMatch).length / bullets.length;
      checks.add(
        AtsCheck(
          title: 'Ada angka & hasil terukur',
          status: metricRate >= 0.5 ? CheckStatus.pass : (metricRate >= 0.2 ? CheckStatus.partial : CheckStatus.fail),
          points: (metricRate / 0.5 * 10).round().clamp(0, 10),
          maxPoints: 10,
          tip: metricRate >= 0.5
              ? 'Banyak poin sudah membawa angka. Bagus.'
              : 'Tambahkan angka: %, jumlah user, waktu yang dihemat, omzet (${(metricRate * 100).round()}% poin punya angka).',
          section: 'experience',
        ),
      );
      final goodLen = bullets.where((b) => _words(b) >= 8 && _words(b) <= 32).length / bullets.length;
      checks.add(
        AtsCheck(
          title: 'Panjang poin pas',
          status: goodLen >= 0.8 ? CheckStatus.pass : CheckStatus.partial,
          points: (goodLen * 5).round(),
          maxPoints: 5,
          tip: goodLen >= 0.8
              ? 'Poin ringkas dan mudah dipindai.'
              : 'Usahakan tiap poin 8–32 kata: cukup konteks, tetap satu baris ide.',
          section: 'experience',
        ),
      );
    }

    // Education (8), Skills (8)
    final edu = d.education.where((e) => e.school.trim().isNotEmpty).length;
    checks.add(
      AtsCheck(
        title: 'Pendidikan',
        status: edu > 0 ? CheckStatus.pass : CheckStatus.fail,
        points: edu > 0 ? 8 : 0,
        maxPoints: 8,
        tip: edu > 0 ? 'Pendidikan tercantum.' : 'Tambahkan pendidikan terakhir (kampus, jurusan, tahun).',
        section: 'education',
      ),
    );
    final sk = d.skills.where((s) => s.trim().isNotEmpty).length;
    checks.add(
      AtsCheck(
        title: 'Keahlian (kata kunci)',
        status: sk >= 8 ? CheckStatus.pass : (sk >= 4 ? CheckStatus.partial : CheckStatus.fail),
        points: sk >= 8 ? 8 : (sk >= 4 ? 5 : (sk > 0 ? 2 : 0)),
        maxPoints: 8,
        tip: sk >= 8
            ? '$sk keahlian, cukup banyak kata kunci untuk dicocokkan ATS.'
            : 'Tambahkan keahlian sampai 8–15 (sekarang $sk). Pakai istilah persis dari lowongan.',
        section: 'skills',
      ),
    );

    // Voice (4) and length (6)
    final text = d.plainText;
    final fp = _firstPerson.allMatches('${d.summary} ${bullets.join(' ')}').length;
    checks.add(
      AtsCheck(
        title: 'Tanpa kata ganti orang pertama',
        status: fp == 0 ? CheckStatus.pass : CheckStatus.partial,
        points: fp == 0 ? 4 : 1,
        maxPoints: 4,
        tip: fp == 0
            ? 'Gaya penulisan sudah ringkas dan profesional.'
            : 'Hapus "I/my/saya" dari ringkasan dan poin. Tulis langsung: "Led a team of 5…"',
        section: 'summary',
      ),
    );
    final total = _words(text);
    checks.add(
      AtsCheck(
        title: 'Panjang CV',
        status: total >= 250 && total <= 900 ? CheckStatus.pass : CheckStatus.partial,
        points: total >= 250 && total <= 900 ? 6 : (total >= 120 ? 3 : 0),
        maxPoints: 6,
        tip: total < 250
            ? 'CV masih tipis ($total kata). Target 250–900 kata (1–2 halaman).'
            : total > 900
            ? 'CV terlalu panjang ($total kata). Pangkas jadi maksimal 2 halaman.'
            : 'Panjang ideal untuk 1–2 halaman ($total kata).',
      ),
    );

    return AtsReport(checks);
  }
}
