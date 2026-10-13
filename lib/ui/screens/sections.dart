import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../core/env.dart';
import '../../core/motion.dart';
import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';
import '../../data/models.dart';
import '../../services/ai_service.dart';
import '../../services/ats_scorer.dart';
import '../../state/resume_store.dart';
import '../kit/clay_widgets.dart';
import '../kit/feedback.dart';
import '../routes.dart';
import 'editor_screen.dart' show SaveIndicator;

// ------------------------------------------------------------ registry ---

class SectionInfo {
  const SectionInfo(
    this.id,
    this.title,
    this.icon,
    this.summary,
    this.status,
    this.builder, {
    this.optionalEmpty = false,
  });
  final String id;
  final String title;
  final IconData2 icon;
  final String summary;
  final CheckStatus status;
  final Widget Function(String resumeId) builder;

  /// Optional section with nothing in it: not a failure, but not "done" either.
  final bool optionalEmpty;
}

CheckStatus _worst(AtsReport r, String section) {
  final s = r.checks.where((c) => c.section == section).map((c) => c.status).toList();
  if (s.isEmpty) return CheckStatus.pass;
  if (s.contains(CheckStatus.fail)) return CheckStatus.fail;
  if (s.contains(CheckStatus.partial)) return CheckStatus.partial;
  return CheckStatus.pass;
}

List<SectionInfo> sectionsFor(ResumeData d, AtsReport r) {
  String count(int n, String noun) => n == 0 ? 'Belum diisi' : '$n $noun';
  final bullets = d.experiences.fold<int>(0, (s, e) => s + e.bullets.length);
  return [
    SectionInfo(
      'contact',
      'Kontak',
      HugeIcons.strokeRoundedUserCircle,
      d.contact.fullName.isEmpty
          ? 'Belum diisi'
          : [d.contact.fullName, d.contact.email].where((e) => e.isNotEmpty).join(' · '),
      _worst(r, 'contact'),
      (id) => ContactSection(resumeId: id),
    ),
    SectionInfo(
      'summary',
      'Ringkasan',
      HugeIcons.strokeRoundedNote01,
      d.summary.isEmpty ? 'Belum diisi' : d.summary,
      _worst(r, 'summary'),
      (id) => SummarySection(resumeId: id),
    ),
    SectionInfo(
      'experience',
      'Pengalaman',
      HugeIcons.strokeRoundedBriefcase01,
      d.experiences.isEmpty ? 'Belum diisi' : '${d.experiences.length} peran · $bullets poin',
      _worst(r, 'experience'),
      (id) => ExperienceSection(resumeId: id),
    ),
    SectionInfo(
      'education',
      'Pendidikan',
      HugeIcons.strokeRoundedMortarboard01,
      count(d.education.length, 'entri'),
      _worst(r, 'education'),
      (id) => EducationSection(resumeId: id),
    ),
    SectionInfo(
      'skills',
      'Keahlian',
      HugeIcons.strokeRoundedSparkles,
      d.skills.isEmpty ? 'Belum diisi' : d.skills.take(4).join(', ') + (d.skills.length > 4 ? '…' : ''),
      _worst(r, 'skills'),
      (id) => SkillsSection(resumeId: id),
    ),
    SectionInfo(
      'projects',
      'Proyek',
      HugeIcons.strokeRoundedIdea01,
      count(d.projects.length, 'proyek'),
      CheckStatus.pass,
      (id) => ProjectsSection(resumeId: id),
      optionalEmpty: d.projects.isEmpty,
    ),
    SectionInfo(
      'certifications',
      'Sertifikasi',
      HugeIcons.strokeRoundedCertificate01,
      count(d.certifications.length, 'sertifikat'),
      CheckStatus.pass,
      (id) => CertificationsSection(resumeId: id),
      optionalEmpty: d.certifications.isEmpty,
    ),
    SectionInfo(
      'languages',
      'Bahasa',
      HugeIcons.strokeRoundedTranslate,
      count(d.languages.length, 'bahasa'),
      CheckStatus.pass,
      (id) => LanguagesSection(resumeId: id),
      optionalEmpty: d.languages.isEmpty,
    ),
  ];
}

Widget sectionPageFor(String id, String resumeId) =>
    sectionsFor(ResumeData(), const AtsReport([])).firstWhere((s) => s.id == id).builder(resumeId);

// -------------------------------------------------------------- shared ---

class _SectionPage extends StatelessWidget {
  const _SectionPage({
    required this.resume,
    required this.title,
    required this.children,
    this.bottom,
    this.actions,
    this.sectionId,
  });
  final Resume resume;
  final String title;

  /// Set on top-level section pages; adds a "next section" step at the end.
  final String? sectionId;
  final List<Widget> children;
  final Widget? bottom;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) context.read<ResumeStore>().flush(resume.id);
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...?actions,
          SaveIndicator(resume: resume),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            ...children,
            if (sectionId != null) _NextSectionTile(resume: resume, sectionId: sectionId!),
          ],
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: bottom!),
    ),
  );
}

/// Wizard step footer: shows where you are (n of 8) and hops to the next
/// section so the CV can be filled in one pass without going back to the list.
class _NextSectionTile extends StatelessWidget {
  const _NextSectionTile({required this.resume, required this.sectionId});
  final Resume resume;
  final String sectionId;

  @override
  Widget build(BuildContext context) {
    final all = sectionsFor(resume.data, AtsScorer.score(resume.data));
    final i = all.indexWhere((s) => s.id == sectionId);
    if (i < 0) return const SizedBox.shrink();
    final c = context.clay;
    final last = i == all.length - 1;
    final next = last ? null : all[i + 1];
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          Text('Bagian ${i + 1} dari ${all.length}', style: context.text.labelMedium),
          const SizedBox(height: 10),
          ClayPressable(
            color: c.slab,
            semanticLabel: last ? 'Selesai, kembali ke daftar bagian' : 'Lanjut ke ${next!.title}',
            onTap: () {
              context.read<ResumeStore>().flush(resume.id);
              if (last) {
                Navigator.of(context).pop();
              } else {
                pushStep<void, void>(context, next!.builder(resume.id));
              }
            },
            child: Row(
              children: [
                Hi(last ? HugeIcons.strokeRoundedCheckmarkCircle02 : next!.icon, color: c.onSlab),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    last ? 'Selesai, lihat ringkasan' : 'Lanjut: ${next!.title}',
                    style: context.text.titleMedium!.copyWith(color: c.onSlab),
                  ),
                ),
                Hi(HugeIcons.strokeRoundedArrowRight01, color: c.onSlab),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Resume? _watch(BuildContext context, String id) => context.watch<ResumeStore>().byId(id);

Widget _missing() => Scaffold(
  appBar: AppBar(),
  body: const Center(child: Text('CV tidak ditemukan.')),
);

const _gap = SizedBox(height: 16);

/// Runs an AI call behind the clay loader and reports failures as a toast.
Future<T?> runAi<T>(BuildContext context, String label, Future<T> Function(AiService ai) task) async {
  final ai = context.read<AiService>();
  if (!Env.hasAi) {
    Toast.show(
      context,
      'Fitur AI belum aktif. Tambahkan GEMINI_API_KEY atau ANTHROPIC_API_KEY di .env.json.',
      tone: Tone.warning,
    );
    return null;
  }
  try {
    return await withBusy(context, label, () => task(ai));
  } catch (e) {
    if (context.mounted) Toast.show(context, friendlyError(e), tone: Tone.error);
    return null;
  }
}

/// Shows an AI suggestion next to the original; returns true when accepted.
Future<bool> reviewSuggestion(BuildContext context, {required String before, required String after}) async {
  final ok = await showClayDialog<bool>(
    context,
    title: 'Saran AI',
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (before.trim().isNotEmpty) ...[
          Text('Sebelum', style: context.text.labelMedium),
          const SizedBox(height: 4),
          Text(before, style: context.text.bodyMedium!.copyWith(color: context.clay.inkMuted)),
          const SizedBox(height: 14),
        ],
        Text('Sesudah', style: context.text.labelMedium!.copyWith(color: context.clay.primary)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: Clay.box(
            context,
            color: context.isDark ? context.clay.slab : Palette.lemon,
            radius: 18,
            depth: 0.4,
          ),
          child: Text(after, style: context.text.bodyLarge),
        ),
        const SizedBox(height: 10),
        Text('Periksa faktanya. Ganti [placeholder] dengan angka aslimu.', style: context.text.bodySmall),
      ],
    ),
    actions: (ctx) => [
      ClayButton(label: 'Batal', tone: ClayButtonTone.ghost, onPressed: () => Navigator.pop(ctx, false)),
      ClayButton(
        label: 'Pakai',
        compact: true,
        icon: HugeIcons.strokeRoundedTick02,
        onPressed: () => Navigator.pop(ctx, true),
      ),
    ],
  );
  return ok ?? false;
}

/// Shows AI-rewritten bullets per entry next to the originals, each with its
/// own "Pakai" toggle. Returns the ids the user kept (empty when cancelled).
Future<Set<String>> reviewBulletChanges(
  BuildContext context, {
  required Map<String, ({String title, List<String> bullets})> before,
  required Map<String, List<String>> after,
}) async {
  final keep = after.keys.toSet();
  final ok = await showClayDialog<bool>(
    context,
    title: 'Saran AI',
    message: 'Periksa faktanya. Ganti [placeholder] dengan angka aslimu.',
    body: StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final id in after.keys) ...[
            Row(
              children: [
                Expanded(child: Text(before[id]!.title, style: ctx.text.titleSmall)),
                Text('Pakai', style: ctx.text.labelMedium),
                Checkbox(
                  value: keep.contains(id),
                  activeColor: ctx.clay.primary,
                  onChanged: (v) => setState(() => v == true ? keep.add(id) : keep.remove(id)),
                ),
              ],
            ),
            Text('Sebelum', style: ctx.text.labelMedium),
            const SizedBox(height: 4),
            for (final b in before[id]!.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $b', style: ctx.text.bodyMedium!.copyWith(color: ctx.clay.inkMuted)),
              ),
            const SizedBox(height: 10),
            Text('Sesudah', style: ctx.text.labelMedium!.copyWith(color: ctx.clay.primary)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: Clay.box(
                ctx,
                color: ctx.isDark ? ctx.clay.slab : Palette.lemon,
                radius: 18,
                depth: 0.4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in after[id]!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $b', style: ctx.text.bodyMedium),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    ),
    actions: (ctx) => [
      ClayButton(label: 'Batal', tone: ClayButtonTone.ghost, onPressed: () => Navigator.pop(ctx, false)),
      ClayButton(
        label: 'Terapkan',
        compact: true,
        icon: HugeIcons.strokeRoundedTick02,
        onPressed: () => Navigator.pop(ctx, true),
      ),
    ],
  );
  return ok == true ? keep : const {};
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: ClayBanner(title: 'Tips ATS', message: text, tone: Tone.warning),
  );
}

/// A card for one entry in a repeatable section (experience, education…).
class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: ClayPressable(
      color: context.clay.paper,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                if (subtitle.isNotEmpty) ...[const SizedBox(height: 2), Text(subtitle, style: context.text.bodySmall)],
              ],
            ),
          ),
          Hi(HugeIcons.strokeRoundedEdit02, color: context.clay.inkMuted, size: 20),
        ],
      ),
    ),
  );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(20),
    decoration: Clay.well(context, radius: Clay.radiusL),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: context.text.bodyMedium!.copyWith(color: context.clay.inkMuted),
    ),
  );
}

Future<bool> _confirmDelete(BuildContext context, String what) => confirmClay(
  context,
  title: 'Hapus $what?',
  message: 'Isi $what ini akan hilang dari CV.',
  confirmLabel: 'Hapus',
  destructive: true,
);

// ------------------------------------------------------------- contact ---

class ContactSection extends StatelessWidget {
  const ContactSection({super.key, required this.resumeId});
  final String resumeId;

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, resumeId);
    if (r == null) return _missing();
    final c = r.data.contact;
    final store = context.read<ResumeStore>();
    Widget f(
      String label,
      String value,
      void Function(String) set, {
      String? ph,
      TextInputType? type,
      String? hint,
      TextCapitalization cap = TextCapitalization.words,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClayField(
        label: label,
        initialValue: value,
        placeholder: ph,
        hint: hint,
        keyboardType: type,
        capitalization: cap,
        textInputAction: TextInputAction.next,
        onChanged: (v) {
          set(v);
          store.touch(r);
        },
      ),
    );
    return _SectionPage(
      resume: r,
      title: 'Kontak',
      sectionId: 'contact',
      children: [
        const _Tip('Taruh kontak di badan CV, bukan di header/footer dokumen. Sebagian ATS melewatkan header.'),
        f('Nama lengkap', c.fullName, (v) => c.fullName = v, ph: 'Hilal Andi'),
        f(
          'Headline / posisi target',
          c.headline,
          (v) => c.headline = v,
          ph: 'Frontend Engineer',
          hint: 'Samakan dengan judul posisi di lowongan.',
        ),
        f(
          'Email',
          c.email,
          (v) => c.email = v,
          ph: 'nama@email.com',
          type: TextInputType.emailAddress,
          cap: TextCapitalization.none,
        ),
        f(
          'Telepon',
          c.phone,
          (v) => c.phone = v,
          ph: '+62 812 3456 7890',
          type: TextInputType.phone,
          hint: 'Pakai kode negara (+62) untuk lamaran internasional.',
        ),
        f('Kota, negara', c.location, (v) => c.location = v, ph: 'Jakarta, Indonesia'),
        f(
          'LinkedIn',
          c.linkedin,
          (v) => c.linkedin = v,
          ph: 'linkedin.com/in/namamu',
          type: TextInputType.url,
          cap: TextCapitalization.none,
        ),
        f(
          'Website / portofolio',
          c.website,
          (v) => c.website = v,
          ph: 'namamu.dev',
          type: TextInputType.url,
          cap: TextCapitalization.none,
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- summary ---

class SummarySection extends StatefulWidget {
  const SummarySection({super.key, required this.resumeId});
  final String resumeId;

  @override
  State<SummarySection> createState() => _SummarySectionState();
}

class _SummarySectionState extends State<SummarySection> {
  Key _fieldKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, widget.resumeId);
    if (r == null) return _missing();
    final store = context.read<ResumeStore>();
    final words = r.data.summary.trim().isEmpty ? 0 : r.data.summary.trim().split(RegExp(r'\s+')).length;
    return _SectionPage(
      resume: r,
      title: 'Ringkasan',
      sectionId: 'summary',
      bottom: ClayButton(
        label: r.data.summary.trim().isEmpty ? 'Tulis dengan AI' : 'Perbaiki dengan AI',
        icon: HugeIcons.strokeRoundedAiMagic,
        tone: ClayButtonTone.soft,
        expand: true,
        onPressed: () async {
          final out = await runAi(
            context,
            'Menulis ringkasan…',
            (ai) => ai.writeSummary(r.data, targetRole: r.data.contact.headline),
          );
          if (out == null || !context.mounted) return;
          if (await reviewSuggestion(context, before: r.data.summary, after: out)) {
            r.data.summary = out;
            store.touch(r);
            setState(() => _fieldKey = UniqueKey());
          }
        },
      ),
      children: [
        const _Tip(
          '2–4 kalimat: siapa kamu + tahun pengalaman, keahlian inti yang dicari lowongan, dan satu hasil terbaik dengan angka.',
        ),
        ClayField(
          key: _fieldKey,
          label: 'Ringkasan profesional',
          initialValue: r.data.summary,
          maxLines: 9,
          minLines: 6,
          placeholder: 'Frontend engineer with 4 years of experience building…',
          hint: '$words kata · ideal 30–90',
          onChanged: (v) {
            r.data.summary = v;
            store.touch(r);
          },
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- bullets ---

class BulletsEditor extends StatefulWidget {
  const BulletsEditor({super.key, required this.bullets, required this.onChanged, this.role = '', this.company = ''});
  final List<String> bullets;
  final VoidCallback onChanged;
  final String role;
  final String company;

  @override
  State<BulletsEditor> createState() => _BulletsEditorState();
}

class _BulletsEditorState extends State<BulletsEditor> {
  late final List<Key> _keys = List.generate(widget.bullets.length, (_) => UniqueKey());

  void _add([String text = '']) {
    setState(() {
      widget.bullets.add(text);
      _keys.add(UniqueKey());
    });
    widget.onChanged();
  }

  Future<void> _improve(int i) async {
    final before = widget.bullets[i];
    if (before.trim().length < 6) {
      Toast.show(context, 'Tulis dulu poinnya, lalu biarkan AI memolesnya.', tone: Tone.warning);
      return;
    }
    final out = await runAi(context, 'Memoles kalimat…', (ai) => ai.improveBullet(before, role: widget.role));
    if (out == null || !mounted) return;
    if (await reviewSuggestion(context, before: before, after: out)) {
      setState(() {
        widget.bullets[i] = out;
        _keys[i] = UniqueKey();
      });
      widget.onChanged();
    }
  }

  Future<void> _fromNotes() async {
    final notes = TextEditingController();
    final go = await showClayDialog<bool>(
      context,
      title: 'Buat poin dari catatan',
      message: 'Ceritakan apa yang kamu kerjakan dan hasilnya, bebas dan singkat. AI menyusunnya jadi 3–5 poin.',
      body: ClayField(
        controller: notes,
        maxLines: 6,
        minLines: 4,
        placeholder: 'urus web toko, bikin fitur checkout baru, penjualan naik…',
      ),
      actions: (ctx) => [
        ClayButton(label: 'Batal', tone: ClayButtonTone.ghost, onPressed: () => Navigator.pop(ctx, false)),
        ClayButton(
          label: 'Buat poin',
          compact: true,
          icon: HugeIcons.strokeRoundedAiMagic,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    );
    if (go != true || notes.text.trim().isEmpty || !mounted) return;
    final out = await runAi(
      context,
      'Menyusun poin…',
      (ai) => ai.bulletsFromNotes(notes.text, role: widget.role, company: widget.company),
    );
    if (out == null || out.isEmpty || !mounted) return;
    for (final b in out) {
      _add(b);
    }
    Toast.show(context, '${out.length} poin ditambahkan. Cek dan sesuaikan angkanya.', tone: Tone.success);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.bullets.length; i++)
          Padding(
            key: _keys[i],
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClayField(
                  initialValue: widget.bullets[i],
                  maxLines: 4,
                  minLines: 2,
                  placeholder: 'Increased checkout conversion by 18% by…',
                  onChanged: (v) {
                    widget.bullets[i] = v;
                    widget.onChanged();
                  },
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _improve(i),
                      icon: Hi(HugeIcons.strokeRoundedMagicWand01, size: 18, color: c.primary),
                      label: Text('Perbaiki dengan AI', style: context.text.labelMedium!.copyWith(color: c.primary)),
                      style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Hapus poin',
                      onPressed: () {
                        setState(() {
                          widget.bullets.removeAt(i);
                          _keys.removeAt(i);
                        });
                        widget.onChanged();
                      },
                      icon: Hi(HugeIcons.strokeRoundedDelete02, size: 20, color: c.inkMuted),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: Motion.of(context, Motion.fast)),
        if (widget.bullets.isEmpty) const _EmptyHint('Belum ada poin. Mulai dengan kata kerja: Led, Built, Reduced…'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ClayButton(
              label: 'Tambah poin',
              compact: true,
              tone: ClayButtonTone.soft,
              icon: HugeIcons.strokeRoundedAdd01,
              onPressed: _add,
            ),
            ClayButton(
              label: 'Dari catatan (AI)',
              compact: true,
              tone: ClayButtonTone.soft,
              icon: HugeIcons.strokeRoundedAiMagic,
              onPressed: _fromNotes,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------- experience ---

class ExperienceSection extends StatelessWidget {
  const ExperienceSection({super.key, required this.resumeId});
  final String resumeId;

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, resumeId);
    if (r == null) return _missing();
    final store = context.read<ResumeStore>();
    return _SectionPage(
      resume: r,
      title: 'Pengalaman',
      sectionId: 'experience',
      bottom: ClayButton(
        label: 'Tambah pengalaman',
        icon: HugeIcons.strokeRoundedAdd01,
        expand: true,
        onPressed: () {
          final e = Experience();
          r.data.experiences.insert(0, e);
          store.touch(r);
          push(context, ExperienceEditor(resumeId: resumeId, entry: e));
        },
      ),
      children: [
        const _Tip('Urutkan dari yang terbaru. Tiap peran 2–5 poin, diawali kata kerja, dan sebisa mungkin ada angka.'),
        if (r.data.experiences.isEmpty)
          const _EmptyHint('Magang, organisasi, freelance, dan proyek kampus juga dihitung.'),
        for (final e in r.data.experiences)
          _EntryCard(
            title: e.role.isEmpty ? 'Peran tanpa judul' : e.role,
            subtitle: [e.company, e.period].where((x) => x.isNotEmpty).join(' · '),
            onTap: () => push(context, ExperienceEditor(resumeId: resumeId, entry: e)),
          ),
      ],
    );
  }
}

class ExperienceEditor extends StatelessWidget {
  const ExperienceEditor({super.key, required this.resumeId, required this.entry});
  final String resumeId;
  final Experience entry;

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, resumeId);
    if (r == null) return _missing();
    final store = context.read<ResumeStore>();
    final e = entry;
    void save() => store.touch(r);
    return _SectionPage(
      resume: r,
      title: e.role.isEmpty ? 'Pengalaman' : e.role,
      actions: [
        IconButton(
          tooltip: 'Hapus pengalaman',
          onPressed: () async {
            if (!await _confirmDelete(context, 'pengalaman')) return;
            r.data.experiences.remove(e);
            save();
            if (context.mounted) Navigator.pop(context);
          },
          icon: Hi(HugeIcons.strokeRoundedDelete02, color: context.clay.danger),
        ),
      ],
      children: [
        ClayField(
          label: 'Posisi',
          initialValue: e.role,
          placeholder: 'Frontend Engineer',
          onChanged: (v) {
            e.role = v;
            save();
          },
        ),
        _gap,
        ClayField(
          label: 'Perusahaan / organisasi',
          initialValue: e.company,
          placeholder: 'PT Contoh Teknologi',
          onChanged: (v) {
            e.company = v;
            save();
          },
        ),
        _gap,
        ClayField(
          label: 'Lokasi',
          initialValue: e.location,
          placeholder: 'Jakarta, Indonesia (Remote)',
          onChanged: (v) {
            e.location = v;
            save();
          },
        ),
        _gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClayField(
                label: 'Mulai',
                initialValue: e.start,
                placeholder: 'Jan 2023',
                onChanged: (v) {
                  e.start = v;
                  save();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: e.current
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('Selesai', style: context.text.titleSmall),
                        ),
                        Container(
                          height: 52,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: Clay.well(context),
                          child: Text('Present', style: context.text.bodyLarge),
                        ),
                      ],
                    )
                  : ClayField(
                      label: 'Selesai',
                      initialValue: e.end,
                      placeholder: 'Des 2024',
                      onChanged: (v) {
                        e.end = v;
                        save();
                      },
                    ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ClaySwitchRow(
          label: 'Masih bekerja di sini',
          value: e.current,
          onChanged: (v) {
            e.current = v;
            save();
          },
        ),
        const SectionTitle('Poin pencapaian'),
        BulletsEditor(bullets: e.bullets, onChanged: save, role: e.role, company: e.company),
      ],
    );
  }
}

class _ClaySwitchRow extends StatelessWidget {
  const _ClaySwitchRow({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(label, style: context.text.bodyLarge),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Palette.lemon,
        activeTrackColor: context.clay.primary,
      ),
      onTap: () => onChanged(!value),
    ),
  );
}

// ----------------------------------------------------------- education ---

class EducationSection extends StatelessWidget {
  const EducationSection({super.key, required this.resumeId});
  final String resumeId;

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, resumeId);
    if (r == null) return _missing();
    final store = context.read<ResumeStore>();
    return _SectionPage(
      resume: r,
      title: 'Pendidikan',
      sectionId: 'education',
      bottom: ClayButton(
        label: 'Tambah pendidikan',
        icon: HugeIcons.strokeRoundedAdd01,
        expand: true,
        onPressed: () {
          final e = Education();
          r.data.education.insert(0, e);
          store.touch(r);
          push(context, EducationEditor(resumeId: resumeId, entry: e));
        },
      ),
      children: [
        const _Tip(
          'Tulis nama kampus dan gelar lengkap dalam bahasa Inggris, misalnya "Bachelor of Computer Science".',
        ),
        if (r.data.education.isEmpty) const _EmptyHint('Belum ada pendidikan.'),
        for (final e in r.data.education)
          _EntryCard(
            title: e.school.isEmpty ? 'Tanpa nama institusi' : e.school,
            subtitle: [e.degree, e.period].where((x) => x.isNotEmpty).join(' · '),
            onTap: () => push(context, EducationEditor(resumeId: resumeId, entry: e)),
          ),
      ],
    );
  }
}

class EducationEditor extends StatelessWidget {
  const EducationEditor({super.key, required this.resumeId, required this.entry});
  final String resumeId;
  final Education entry;

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, resumeId);
    if (r == null) return _missing();
    final store = context.read<ResumeStore>();
    final e = entry;
    void save() => store.touch(r);
    Widget f(String label, String v, void Function(String) set, String ph) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClayField(
        label: label,
        initialValue: v,
        placeholder: ph,
        onChanged: (x) {
          set(x);
          save();
        },
      ),
    );
    return _SectionPage(
      resume: r,
      title: 'Pendidikan',
      actions: [
        IconButton(
          tooltip: 'Hapus pendidikan',
          onPressed: () async {
            if (!await _confirmDelete(context, 'pendidikan')) return;
            r.data.education.remove(e);
            save();
            if (context.mounted) Navigator.pop(context);
          },
          icon: Hi(HugeIcons.strokeRoundedDelete02, color: context.clay.danger),
        ),
      ],
      children: [
        f('Institusi', e.school, (v) => e.school = v, 'Universitas Indonesia'),
        f('Gelar', e.degree, (v) => e.degree = v, 'Bachelor of Science'),
        f('Jurusan', e.field, (v) => e.field = v, 'Computer Science'),
        Row(
          children: [
            Expanded(child: f('Mulai', e.start, (v) => e.start = v, '2018')),
            const SizedBox(width: 12),
            Expanded(child: f('Lulus', e.end, (v) => e.end = v, '2022')),
          ],
        ),
        f('IPK (opsional)', e.gpa, (v) => e.gpa = v, '3.65/4.00'),
        ClayField(
          label: 'Prestasi / detail (opsional)',
          initialValue: e.details,
          maxLines: 4,
          minLines: 2,
          placeholder: "Dean's List 2020–2021; Thesis on…",
          onChanged: (v) {
            e.details = v;
            save();
          },
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- skills ---

class SkillsSection extends StatefulWidget {
  const SkillsSection({super.key, required this.resumeId});
  final String resumeId;

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add(Resume r) {
    final parts = _ctrl.text.split(RegExp(r'[,;\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
    var added = 0;
    for (final p in parts) {
      if (!r.data.skills.any((s) => s.toLowerCase() == p.toLowerCase())) {
        r.data.skills.add(p);
        added++;
      }
    }
    _ctrl.clear();
    if (added > 0) context.read<ResumeStore>().touch(r);
  }

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, widget.resumeId);
    if (r == null) return _missing();
    final c = context.clay;
    return _SectionPage(
      resume: r,
      title: 'Keahlian',
      sectionId: 'skills',
      children: [
        const _Tip(
          'Pakai istilah persis seperti di lowongan (mis. "React.js", "Google Analytics"). ATS mencocokkan kata, bukan makna.',
        ),
        ClayField(
          controller: _ctrl,
          label: 'Tambah keahlian',
          placeholder: 'Figma, SQL, Stakeholder Management',
          hint: 'Pisahkan beberapa sekaligus dengan koma.',
          textInputAction: TextInputAction.done,
          capitalization: TextCapitalization.words,
          onSubmitted: (_) => _add(r),
          trailing: IconButton(
            tooltip: 'Tambah',
            onPressed: () => _add(r),
            icon: Hi(HugeIcons.strokeRoundedAdd01, color: c.primary),
          ),
        ),
        const SizedBox(height: 20),
        if (r.data.skills.isEmpty)
          const _EmptyHint('Target 8–15 keahlian: campuran hard skill, tools, dan beberapa soft skill.')
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in r.data.skills)
                SkillChip(
                  label: s,
                  onRemove: () {
                    r.data.skills.remove(s);
                    context.read<ResumeStore>().touch(r);
                  },
                ),
            ],
          ),
        const SizedBox(height: 12),
        Text('${r.data.skills.length} keahlian', style: context.text.bodySmall),
      ],
    );
  }
}

class SkillChip extends StatelessWidget {
  const SkillChip({super.key, required this.label, this.onRemove, this.tone = Tone.success, this.onTap});
  final String label;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final (bg, fg) = switch (tone) {
      Tone.error => (c.dangerSoft, context.isDark ? Colors.white : Palette.scarletDeep),
      Tone.warning => (context.isDark ? c.surfaceRaised : Palette.lemon, c.ink),
      _ => (c.successSoft, context.isDark ? Palette.willow : Palette.turfDeep),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: EdgeInsets.fromLTRB(14, 6, onRemove == null ? 14 : 4, 6),
          decoration: Clay.box(context, color: bg, radius: 16, depth: 0.35),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(label, style: context.text.labelLarge!.copyWith(color: fg)),
              ),
              if (onRemove != null)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Hapus $label',
                    onPressed: onRemove,
                    icon: Hi(HugeIcons.strokeRoundedCancel01, size: 16, color: fg),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ projects ---

class ProjectsSection extends StatelessWidget {
  const ProjectsSection({super.key, required this.resumeId});
  final String resumeId;

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, resumeId);
    if (r == null) return _missing();
    final store = context.read<ResumeStore>();
    return _SectionPage(
      resume: r,
      title: 'Proyek',
      sectionId: 'projects',
      bottom: ClayButton(
        label: 'Tambah proyek',
        icon: HugeIcons.strokeRoundedAdd01,
        expand: true,
        onPressed: () {
          final p = Project();
          r.data.projects.insert(0, p);
          store.touch(r);
          push(context, ProjectEditor(resumeId: resumeId, entry: p));
        },
      ),
      children: [
        const _Tip(
          'Proyek kuat untuk fresh graduate dan career switcher. Tulis masalahnya, apa yang kamu bangun, dan hasilnya.',
        ),
        if (r.data.projects.isEmpty) const _EmptyHint('Belum ada proyek.'),
        for (final p in r.data.projects)
          _EntryCard(
            title: p.name.isEmpty ? 'Proyek tanpa nama' : p.name,
            subtitle: '${p.bullets.length} poin',
            onTap: () => push(context, ProjectEditor(resumeId: resumeId, entry: p)),
          ),
      ],
    );
  }
}

class ProjectEditor extends StatelessWidget {
  const ProjectEditor({super.key, required this.resumeId, required this.entry});
  final String resumeId;
  final Project entry;

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, resumeId);
    if (r == null) return _missing();
    final store = context.read<ResumeStore>();
    final p = entry;
    void save() => store.touch(r);
    return _SectionPage(
      resume: r,
      title: 'Proyek',
      actions: [
        IconButton(
          tooltip: 'Hapus proyek',
          onPressed: () async {
            if (!await _confirmDelete(context, 'proyek')) return;
            r.data.projects.remove(p);
            save();
            if (context.mounted) Navigator.pop(context);
          },
          icon: Hi(HugeIcons.strokeRoundedDelete02, color: context.clay.danger),
        ),
      ],
      children: [
        ClayField(
          label: 'Nama proyek',
          initialValue: p.name,
          placeholder: 'Inventory App for SMEs',
          onChanged: (v) {
            p.name = v;
            save();
          },
        ),
        _gap,
        ClayField(
          label: 'Link (opsional)',
          initialValue: p.link,
          placeholder: 'github.com/kamu/proyek',
          keyboardType: TextInputType.url,
          capitalization: TextCapitalization.none,
          onChanged: (v) {
            p.link = v;
            save();
          },
        ),
        const SectionTitle('Poin'),
        BulletsEditor(bullets: p.bullets, onChanged: save, role: p.name),
      ],
    );
  }
}

// ------------------------------------------------------ certifications ---

class CertificationsSection extends StatelessWidget {
  const CertificationsSection({super.key, required this.resumeId});
  final String resumeId;

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, resumeId);
    if (r == null) return _missing();
    final store = context.read<ResumeStore>();
    void save() => store.touch(r);
    return _SectionPage(
      resume: r,
      title: 'Sertifikasi',
      sectionId: 'certifications',
      bottom: ClayButton(
        label: 'Tambah sertifikat',
        icon: HugeIcons.strokeRoundedAdd01,
        expand: true,
        onPressed: () {
          r.data.certifications.add(Certification());
          save();
        },
      ),
      children: [
        if (r.data.certifications.isEmpty)
          const _EmptyHint('Sertifikat resmi (Google, AWS, TOEFL/IELTS, BNSP) menambah kata kunci yang dicari ATS.'),
        for (final cert in r.data.certifications)
          Container(
            key: ObjectKey(cert),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: Clay.box(context, color: context.clay.paper, radius: Clay.radiusL, depth: 0.6),
            child: Column(
              children: [
                ClayField(
                  label: 'Nama sertifikat',
                  initialValue: cert.name,
                  placeholder: 'Google Data Analytics',
                  onChanged: (v) {
                    cert.name = v;
                    save();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ClayField(
                        label: 'Penerbit',
                        initialValue: cert.issuer,
                        placeholder: 'Coursera',
                        onChanged: (v) {
                          cert.issuer = v;
                          save();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ClayField(
                        label: 'Tahun',
                        initialValue: cert.year,
                        placeholder: '2024',
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          cert.year = v;
                          save();
                        },
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      r.data.certifications.remove(cert);
                      save();
                    },
                    icon: Hi(HugeIcons.strokeRoundedDelete02, size: 18, color: context.clay.danger),
                    label: Text('Hapus', style: context.text.labelMedium!.copyWith(color: context.clay.danger)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------- languages ---

class LanguagesSection extends StatelessWidget {
  const LanguagesSection({super.key, required this.resumeId});
  final String resumeId;

  static const levels = ['Native', 'Fluent', 'Professional', 'Intermediate', 'Basic'];

  @override
  Widget build(BuildContext context) {
    final r = _watch(context, resumeId);
    if (r == null) return _missing();
    final store = context.read<ResumeStore>();
    void save() => store.touch(r);
    return _SectionPage(
      resume: r,
      title: 'Bahasa',
      sectionId: 'languages',
      bottom: ClayButton(
        label: 'Tambah bahasa',
        icon: HugeIcons.strokeRoundedAdd01,
        expand: true,
        onPressed: () {
          r.data.languages.add(LanguageSkill(level: 'Professional'));
          save();
        },
      ),
      children: [
        const _Tip(
          'Untuk lamaran internasional, cantumkan bahasa Inggris beserta level atau skor tes (mis. IELTS 7.0).',
        ),
        if (r.data.languages.isEmpty) const _EmptyHint('Belum ada bahasa.'),
        for (final l in r.data.languages)
          Container(
            key: ObjectKey(l),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: Clay.box(context, color: context.clay.paper, radius: Clay.radiusL, depth: 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClayField(
                        initialValue: l.name,
                        placeholder: 'English',
                        onChanged: (v) {
                          l.name = v;
                          save();
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus bahasa',
                      onPressed: () {
                        r.data.languages.remove(l);
                        save();
                      },
                      icon: Hi(HugeIcons.strokeRoundedDelete02, size: 20, color: context.clay.inkMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final lv in levels)
                      ChoiceChip(
                        label: Text(lv),
                        selected: l.level == lv,
                        showCheckmark: false,
                        selectedColor: context.clay.primary,
                        labelStyle: context.text.labelMedium!.copyWith(
                          color: l.level == lv ? context.clay.onPrimary : context.clay.ink,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: context.clay.line),
                        onSelected: (_) {
                          l.level = lv;
                          save();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Small helper so other screens can deep-link into a section editor.
void openSection(BuildContext context, String section, String resumeId) =>
    push(context, sectionPageFor(section, resumeId));
