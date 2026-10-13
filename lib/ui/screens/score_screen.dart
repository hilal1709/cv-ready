import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';
import '../../services/ats_scorer.dart';
import '../../state/resume_store.dart';
import '../kit/brand.dart';
import '../kit/clay_widgets.dart';
import 'sections.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key, required this.resumeId});
  final String resumeId;

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final r = context.watch<ResumeStore>().byId(widget.resumeId);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('CV tidak ditemukan.')),
      );
    }
    final report = AtsScorer.score(r.data);
    final todo = report.todo..sort((a, b) => a.status.index.compareTo(b.status.index) * -1);
    final done = report.checks.where((c) => c.status == CheckStatus.pass).toList();
    final c = context.clay;

    return Scaffold(
      appBar: AppBar(title: const Text('Skor ATS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          Container(
            decoration: Clay.box(context, color: c.slab, radius: Clay.radiusXL),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                ReadinessStamp(score: report.percent, size: 170, label: 'dari 100'),
                const SizedBox(height: 16),
                Text(report.verdict, style: context.text.headlineMedium!.copyWith(color: c.onSlab)),
                const SizedBox(height: 6),
                Text(
                  todo.isEmpty
                      ? 'Semua cek lolos. Sekarang cocokkan dengan lowongan yang kamu incar.'
                      : 'Perbaiki ${todo.length} hal di bawah, mulai dari yang paling berdampak.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge!.copyWith(color: c.onSlab),
                ),
              ],
            ),
          ),
          if (todo.isNotEmpty) const SectionTitle('Yang perlu diperbaiki'),
          for (var i = 0; i < todo.length; i++)
            _CheckCard(check: todo[i], resumeId: r.id)
                .animate(delay: Motion.stagger * i)
                .fadeIn(duration: Motion.of(context, Motion.medium))
                .slideY(begin: 0.1, curve: Motion.expoOut, duration: Motion.of(context, Motion.slow)),
          if (done.isNotEmpty) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              minTileHeight: 52,
              title: Text('Sudah beres (${done.length})', style: context.text.titleMedium),
              trailing: AnimatedRotation(
                turns: _showDone ? 0.25 : 0,
                duration: Motion.of(context, Motion.fast),
                child: Hi(HugeIcons.strokeRoundedArrowRight01, color: c.inkMuted),
              ),
              onTap: () => setState(() => _showDone = !_showDone),
            ),
            AnimatedSize(
              duration: Motion.of(context, Motion.medium),
              curve: Motion.expoOut,
              child: _showDone
                  ? Column(
                      children: [for (final d in done) _CheckCard(check: d, resumeId: r.id)],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Skor ini adalah perkiraan berdasarkan praktik umum sistem ATS dan recruiter, bukan jaminan lolos. '
            'Untuk hasil terbaik, cocokkan juga CV dengan lowongan spesifik di tab Cocokkan.',
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({required this.check, required this.resumeId});
  final AtsCheck check;
  final String resumeId;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final (icon, color) = switch (check.status) {
      CheckStatus.pass => (HugeIcons.strokeRoundedCheckmarkCircle02, c.success),
      CheckStatus.partial => (
        HugeIcons.strokeRoundedInformationCircle,
        context.isDark ? Palette.willow : Palette.turfDeep,
      ),
      CheckStatus.fail => (HugeIcons.strokeRoundedAlert02, c.danger),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: Clay.box(
          context,
          color: check.status == CheckStatus.pass ? c.surfaceRaised : c.paper,
          radius: Clay.radiusL,
          depth: 0.7,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hi(icon, color: color),
                const SizedBox(width: 12),
                Expanded(child: Text(check.title, style: context.text.titleMedium)),
                Text(
                  '${check.points}/${check.maxPoints}',
                  style: context.text.labelLarge!.copyWith(
                    color: c.inkMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(check.tip, style: context.text.bodyMedium),
            ),
            if (check.maxPoints > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(34, 12, 0, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: check.points / check.maxPoints),
                    duration: Motion.of(context, Motion.slow),
                    curve: Motion.expoOut,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v.clamp(0.0, 1.0),
                      minHeight: 6,
                      color: color,
                      backgroundColor: c.line,
                    ),
                  ),
                ),
              ),
            if (check.status != CheckStatus.pass && check.section != null)
              Align(
                alignment: Alignment.centerRight,
                child: ClayButton(
                  label: 'Perbaiki',
                  tone: ClayButtonTone.ghost,
                  compact: true,
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  onPressed: () => openSection(context, check.section!, resumeId),
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
