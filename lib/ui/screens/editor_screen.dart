import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';
import '../../data/models.dart';
import '../../services/ats_scorer.dart';
import '../../state/resume_store.dart';
import '../kit/brand.dart';
import '../kit/clay_widgets.dart';
import '../kit/feedback.dart';
import '../kit/progress.dart';
import '../routes.dart';
import 'cv_list_tab.dart' show TemplateTile;
import 'export_screen.dart';
import 'score_screen.dart';
import 'sections.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key, required this.resumeId});
  final String resumeId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ResumeStore>();
    final r = store.byId(resumeId);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('CV tidak ditemukan.')),
      );
    }
    final report = AtsScorer.score(r.data);
    final sections = sectionsFor(r.data, report);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) store.flush(r.id);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            SaveIndicator(resume: r),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          children: [
            _ScoreCard(resume: r, report: report),
            const SizedBox(height: 14),
            _TemplateRow(resume: r),
            const SectionTitle('Isi CV'),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
              child: SectionRail(
                statuses: [for (final s in sections) s.status],
                optionalEmpty: [for (final s in sections) s.optionalEmpty],
              ),
            ),
            for (var i = 0; i < sections.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SectionRow(info: sections[i], resume: r)
                    .animate(delay: Motion.stagger * i)
                    .fadeIn(duration: Motion.of(context, Motion.medium))
                    .slideY(begin: 0.1, curve: Motion.expoOut, duration: Motion.of(context, Motion.slow)),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ClayButton(
            label: 'Pratinjau & ekspor PDF',
            icon: HugeIcons.strokeRoundedPdf01,
            expand: true,
            onPressed: () async {
              await store.flush(r.id);
              if (context.mounted) push(context, ExportScreen(resumeId: r.id));
            },
          ),
        ),
      ),
    );
  }
}

class SaveIndicator extends StatelessWidget {
  const SaveIndicator({super.key, required this.resume});
  final Resume resume;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ResumeStore>();
    final s = store.saveStateOf(resume.id);
    final c = context.clay;
    final (label, color) = switch (s) {
      SaveState.saving => ('Menyimpan…', c.inkMuted),
      SaveState.saved => ('Tersimpan', c.success),
      SaveState.failed => ('Gagal simpan · ulangi', c.danger),
      SaveState.idle => ('', c.inkMuted),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.fast),
      child: TextButton(
        key: ValueKey(s),
        onPressed: s == SaveState.failed ? () => store.retrySave(resume) : null,
        style: TextButton.styleFrom(minimumSize: const Size(48, 40)),
        child: Text(label, style: context.text.labelMedium!.copyWith(color: color)),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.resume, required this.report});
  final Resume resume;
  final AtsReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final todo = report.todo.length;
    return ClayPressable(
      color: c.slab,
      semanticLabel: 'Lihat detail skor ATS',
      onTap: () => push(context, ScoreScreen(resumeId: resume.id)),
      child: Row(
        children: [
          ReadinessStamp(score: report.percent, size: 96),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.verdict, style: context.text.headlineSmall!.copyWith(color: c.onSlab)),
                const SizedBox(height: 4),
                Text(
                  todo == 0 ? 'Semua cek ATS lolos.' : '$todo hal bisa ditingkatkan. Ketuk untuk melihat.',
                  style: context.text.bodyMedium!.copyWith(color: c.onSlab),
                ),
              ],
            ),
          ),
          Hi(HugeIcons.strokeRoundedArrowRight01, color: c.onSlab),
        ],
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.resume});
  final Resume resume;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ResumeStore>();
    return ClayPressable(
      color: context.clay.surfaceRaised,
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      semanticLabel: 'Ganti template',
      onTap: () => showClaySheet<void>(
        context,
        title: 'Template',
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => Column(
            children: [
              for (final t in CvTemplate.values)
                TemplateTile(
                  template: t,
                  selected: resume.template == t,
                  onTap: () {
                    setState(() => resume.template = t);
                    store.touch(resume);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
      child: Row(
        children: [
          Hi(HugeIcons.strokeRoundedLayout01, color: context.clay.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Template: ${resume.template.label}', style: context.text.titleSmall),
                Text('Semua template satu kolom & ramah ATS', style: context.text.bodySmall),
              ],
            ),
          ),
          Text('Ganti', style: context.text.labelLarge!.copyWith(color: context.clay.primary)),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.info, required this.resume});
  final SectionInfo info;
  final Resume resume;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final (_, dotLabel) = statusLook(context, info.status, optionalEmpty: info.optionalEmpty);
    return ClayPressable(
      color: c.paper,
      padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
      semanticLabel: '${info.title}, $dotLabel',
      onTap: () => push(context, info.builder(resume.id)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: Clay.box(
              context,
              color: context.isDark ? c.surfaceRaised : Colors.white,
              radius: 14,
              depth: 0.4,
            ),
            child: Center(child: Hi(info.icon, color: c.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(info.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
              ],
            ),
          ),
          Tooltip(
            message: dotLabel,
            child: StatusGlyph(status: info.status, optionalEmpty: info.optionalEmpty),
          ),
          const SizedBox(width: 6),
          Hi(HugeIcons.strokeRoundedArrowRight01, color: c.inkMuted, size: 18),
        ],
      ),
    );
  }
}
