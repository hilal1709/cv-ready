import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';
import '../../data/models.dart';
import '../../services/keyword_matcher.dart';
import '../../state/resume_store.dart';
import '../kit/brand.dart';
import '../kit/clay_widgets.dart';
import '../kit/feedback.dart';
import 'cv_list_tab.dart' show startNewCv;
import 'sections.dart';

class MatchTab extends StatefulWidget {
  const MatchTab({super.key});

  @override
  State<MatchTab> createState() => _MatchTabState();
}

class _MatchTabState extends State<MatchTab> {
  static String _jobText = '';
  static String? _resumeId;
  final _job = TextEditingController(text: _jobText);
  KeywordMatch? _result;
  final _resultKey = GlobalKey();

  @override
  void dispose() {
    _jobText = _job.text;
    _job.dispose();
    super.dispose();
  }

  void _run(Resume r) {
    FocusScope.of(context).unfocus();
    if (_job.text.trim().split(RegExp(r'\s+')).length < 25) {
      Toast.show(context, 'Tempel deskripsi lowongan yang lengkap (minimal beberapa kalimat).', tone: Tone.warning);
      return;
    }
    setState(() => _result = KeywordMatcher.match(_job.text, r.data.plainText));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, duration: Motion.of(context, Motion.slow), curve: Motion.expoOut);
    });
  }

  void _addSkill(Resume r, String k) {
    final store = context.read<ResumeStore>();
    final label = k
        .split(' ')
        .map((w) => w.length <= 3 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    if (r.data.skills.any((s) => s.toLowerCase() == k)) return;
    r.data.skills.add(label);
    store.touch(r);
    setState(() => _result = KeywordMatcher.match(_job.text, r.data.plainText));
    Toast.show(
      context,
      '"$label" masuk ke Keahlian.',
      tone: Tone.success,
      actionLabel: 'Batal',
      onAction: () {
        r.data.skills.remove(label);
        store.touch(r);
        if (mounted) setState(() => _result = KeywordMatcher.match(_job.text, r.data.plainText));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ResumeStore>();
    final items = store.items;
    final c = context.clay;
    final selected = items.where((r) => r.id == _resumeId).firstOrNull ?? items.firstOrNull;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cocokkan dengan lowongan', style: context.text.headlineLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Tempel deskripsi lowongan. Kami cari kata kunci yang belum ada di CV-mu.',
                      style: context.text.bodyLarge!.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
              const Illustration('job_match', height: 96),
            ],
          ),
          const SizedBox(height: 22),
          if (items.isEmpty)
            ClayBanner(
              title: 'Belum ada CV untuk dicocokkan',
              message: 'Buat CV dulu, lalu kembali ke sini.',
              action: ClayButton(
                label: 'Buat CV',
                compact: true,
                tone: ClayButtonTone.primary,
                onPressed: () => startNewCv(context),
              ),
            )
          else ...[
            Text('CV yang dicocokkan', style: context.text.titleSmall),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final r = items[i];
                  final sel = r.id == selected?.id;
                  return ChoiceChip(
                    label: Text(r.title),
                    selected: sel,
                    showCheckmark: false,
                    selectedColor: c.primary,
                    backgroundColor: c.surfaceRaised,
                    labelStyle: context.text.labelLarge!.copyWith(color: sel ? c.onPrimary : c.ink),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: sel ? Colors.transparent : c.line),
                    onSelected: (_) => setState(() {
                      _resumeId = r.id;
                      _result = null;
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            ClayField(
              controller: _job,
              label: 'Deskripsi lowongan',
              maxLines: 10,
              minLines: 7,
              placeholder: 'We are looking for a Frontend Engineer with 3+ years of experience in React, TypeScript…',
              onChanged: (v) => _jobText = v,
            ),
            const SizedBox(height: 16),
            ClayButton(
              label: 'Cocokkan sekarang',
              icon: HugeIcons.strokeRoundedSearch01,
              expand: true,
              onPressed: selected == null ? null : () => _run(selected),
            ),
            if (_result != null && selected != null)
              KeyedSubtree(
                key: _resultKey,
                child: _Results(
                  result: _result!,
                  resume: selected,
                  onAdd: (k) => _addSkill(selected, k),
                  job: _job.text,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.result, required this.resume, required this.onAdd, required this.job});
  final KeywordMatch result;
  final Resume resume;
  final ValueChanged<String> onAdd;
  final String job;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final store = context.read<ResumeStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 26),
        Container(
              decoration: Clay.box(context, color: c.slab, radius: Clay.radiusXL),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ReadinessStamp(score: result.percent, size: 104, label: 'cocok'),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.percent >= 70
                              ? 'Kecocokan kuat'
                              : result.percent >= 45
                              ? 'Lumayan cocok'
                              : 'Masih jauh',
                          style: context.text.headlineSmall!.copyWith(color: c.onSlab),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${result.matched.length} dari ${result.total} kata kunci lowongan ada di CV-mu.',
                          style: context.text.bodyMedium!.copyWith(color: c.onSlab),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: Motion.of(context, Motion.medium))
            .scale(begin: const Offset(0.96, 0.96), curve: Motion.backOut),
        if (result.missing.isNotEmpty) ...[
          SectionTitle('Belum ada di CV (${result.missing.length})'),
          Text(
            'Ketuk untuk menambahkannya ke Keahlian, hanya jika memang kamu kuasai. '
            'Lebih kuat lagi kalau juga disebut di poin pengalaman.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < result.missing.length; i++)
                SkillChip(label: '+ ${result.missing[i]}', tone: Tone.error, onTap: () => onAdd(result.missing[i]))
                    .animate(delay: (30 * i).ms)
                    .fadeIn(duration: Motion.of(context, Motion.fast))
                    .scale(begin: const Offset(0.8, 0.8), curve: Motion.backOut),
            ],
          ),
        ],
        if (result.matched.isNotEmpty) ...[
          SectionTitle('Sudah cocok (${result.matched.length})'),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final k in result.matched) SkillChip(label: k)]),
        ],
        const SizedBox(height: 24),
        ClayButton(
          label: 'Sesuaikan ringkasan dengan lowongan (AI)',
          icon: HugeIcons.strokeRoundedAiMagic,
          tone: ClayButtonTone.soft,
          expand: true,
          onPressed: () async {
            final out = await runAi(context, 'Menyesuaikan ringkasan…', (ai) => ai.tailorSummary(resume.data, job));
            if (out == null || !context.mounted) return;
            if (await reviewSuggestion(context, before: resume.data.summary, after: out)) {
              resume.data.summary = out;
              store.touch(resume);
              if (context.mounted) Toast.show(context, 'Ringkasan diperbarui.', tone: Tone.success);
            }
          },
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Tips: duplikat CV-mu untuk lowongan ini agar CV utama tetap utuh.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall!.copyWith(color: context.isDark ? Palette.nightMuted : c.inkMuted),
          ),
        ),
      ],
    );
  }
}
