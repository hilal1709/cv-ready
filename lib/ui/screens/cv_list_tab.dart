import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';
import '../../data/models.dart';
import '../../state/resume_store.dart';
import '../../state/session.dart';
import '../format.dart';
import '../kit/brand.dart';
import '../kit/clay_widgets.dart';
import '../kit/feedback.dart';
import '../routes.dart';
import 'editor_screen.dart';
import 'score_screen.dart';

class CvListTab extends StatelessWidget {
  const CvListTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ResumeStore>();
    final user = context.watch<Session>().user;
    final items = store.items;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: items.isEmpty
            ? null
            : _NewCvFab(onPressed: () => startNewCv(context))
                  .animate()
                  .scale(delay: 300.ms, duration: Motion.of(context, Motion.slow), curve: Motion.backOut),
        body: RefreshIndicator(
          onRefresh: store.refresh,
          color: context.clay.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(name: user?.firstName ?? '', items: items, store: store),
              ),
              if (store.error != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: ClayBanner(
                      title: 'CV tidak bisa dimuat',
                      message: store.error,
                      tone: Tone.error,
                      action: ClayButton(
                        label: 'Coba lagi',
                        compact: true,
                        tone: ClayButtonTone.soft,
                        onPressed: store.refresh,
                      ),
                    ),
                  ),
                ),
              if (store.loading && items.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: Center(child: ClayLoader()))
              else if (items.isEmpty && store.error == null)
                SliverFillRemaining(hasScrollBody: false, child: _Empty(onCreate: () => startNewCv(context)))
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionTitle(
                      'Semua CV',
                      trailing: Text(
                        '${items.length}',
                        style: context.text.titleMedium!.copyWith(color: context.clay.inkMuted),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) =>
                        _CvSheet(resume: items[i])
                            .animate(delay: Motion.stagger * i)
                            .fadeIn(duration: Motion.of(context, Motion.medium))
                            .slideY(begin: 0.12, curve: Motion.expoOut, duration: Motion.of(context, Motion.slow)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NewCvFab extends StatelessWidget {
  const _NewCvFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      ClayButton(label: 'CV baru', icon: HugeIcons.strokeRoundedAdd01, onPressed: onPressed);
}

/// Turf clay slab: greeting + the most recent CV's Readiness Stamp.
class _Header extends StatelessWidget {
  const _Header({required this.name, required this.items, required this.store});
  final String name;
  final List<Resume> items;
  final ResumeStore store;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final latest = items.isEmpty ? null : items.first;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: Clay.box(
        context,
        color: c.slab,
        radius: 0,
        depth: 1.1,
      ).copyWith(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Clay.radiusXL + 4))),
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LogoMark(size: 28, lineColor: Palette.lemon),
              const SizedBox(width: 8),
              Wordmark(size: 18, color: Palette.lemon),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Halo!' : 'Halo, $name.',
                      style: context.text.headlineLarge!.copyWith(color: c.onSlab),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latest == null
                          ? 'Mulai dari satu CV. Kami bantu sampai siap kirim.'
                          : '“${latest.title}” ${store.scoreOf(latest) >= 85 ? 'sudah siap dikirim.' : 'butuh beberapa sentuhan lagi.'}',
                      style: context.text.bodyLarge!.copyWith(color: c.onSlab),
                    ),
                    if (latest != null) ...[
                      const SizedBox(height: 14),
                      ClayButton(
                        label: 'Lihat saran',
                        compact: true,
                        tone: ClayButtonTone.soft,
                        icon: HugeIcons.strokeRoundedIdea01,
                        onPressed: () => push(context, ScoreScreen(resumeId: latest.id)),
                      ),
                    ],
                  ],
                ),
              ),
              if (latest != null) ...[
                const SizedBox(width: 12),
                ReadinessStamp(score: store.scoreOf(latest), size: 116, label: 'siap ATS'),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CvSheet extends StatelessWidget {
  const _CvSheet({required this.resume});
  final Resume resume;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final store = context.read<ResumeStore>();
    final score = store.scoreOf(resume);
    final headline = resume.data.contact.headline.trim();
    return ClayPressable(
      color: c.paper,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      semanticLabel: 'Buka ${resume.title}',
      onTap: () => push(context, EditorScreen(resumeId: resume.id)),
      onLongPress: () => showCvActions(context, resume),
      child: Row(
        children: [
          _MiniPage(score: score),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resume.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                const SizedBox(height: 3),
                Text(
                  headline.isEmpty ? 'Belum ada headline' : headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium!.copyWith(color: headline.isEmpty ? c.inkMuted : c.ink),
                ),
                const SizedBox(height: 8),
                Text('${resume.template.label} · ${relativeTime(resume.updatedAt)}', style: context.text.labelMedium),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '$score',
                style: context.text.headlineSmall!.copyWith(
                  color: ReadinessStamp.colorFor(score) == Palette.willow && !context.isDark
                      ? Palette.turf
                      : ReadinessStamp.colorFor(score),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text('skor', style: context.text.labelSmall),
            ],
          ),
          IconButton(
            tooltip: 'Opsi',
            onPressed: () => showCvActions(context, resume),
            icon: Hi(HugeIcons.strokeRoundedMoreVertical, color: c.inkMuted, size: 20),
          ),
        ],
      ),
    );
  }
}

/// A tiny clay page echoing the logo: lines + a full stop tinted by score.
class _MiniPage extends StatelessWidget {
  const _MiniPage({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    Widget line(double w, double o) => Container(
      width: w,
      height: 5,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Palette.turf.withValues(alpha: o),
        borderRadius: BorderRadius.circular(3),
      ),
    );
    return Container(
      width: 52,
      height: 64,
      padding: const EdgeInsets.fromLTRB(9, 12, 9, 8),
      decoration: Clay.box(context, color: Colors.white, radius: 12, depth: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line(30, 0.9),
          line(22, 0.5),
          line(26, 0.3),
          Row(
            children: [
              line(14, 0.3),
              const SizedBox(width: 4),
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(color: ReadinessStamp.colorFor(score), shape: BoxShape.circle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Illustration('empty_cvs', height: 170),
        const SizedBox(height: 20),
        Text('Belum ada CV', style: context.text.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Buat satu CV utama dulu. Nanti kamu bisa menduplikatnya untuk setiap posisi yang kamu lamar.',
          textAlign: TextAlign.center,
          style: context.text.bodyLarge!.copyWith(color: context.clay.inkMuted),
        ),
        const SizedBox(height: 22),
        ClayButton(label: 'Buat CV pertama', icon: HugeIcons.strokeRoundedFileAdd, onPressed: onCreate),
      ],
    ),
  );
}

// ------------------------------------------------------------- actions ---

Future<void> startNewCv(BuildContext context) async {
  final user = context.read<Session>().user;
  final store = context.read<ResumeStore>();
  final title = TextEditingController(text: store.items.isEmpty ? 'CV Utama' : '');
  var template = CvTemplate.harvard;
  var busy = false;

  final created = await showClaySheet<Resume>(
    context,
    title: 'CV baru',
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClayField(
            label: 'Nama CV',
            controller: title,
            placeholder: 'Contoh: Product Designer – Singapore',
            hint: 'Hanya untukmu, tidak tercetak di PDF.',
          ),
          const SizedBox(height: 18),
          Text('Template', style: ctx.text.titleSmall),
          const SizedBox(height: 10),
          for (final t in CvTemplate.values)
            TemplateTile(template: t, selected: t == template, onTap: () => setState(() => template = t)),
          const SizedBox(height: 10),
          ClayButton(
            label: 'Buat & mulai isi',
            expand: true,
            loading: busy,
            icon: HugeIcons.strokeRoundedArrowRight01,
            onPressed: () async {
              setState(() => busy = true);
              try {
                final r = await store.create(
                  title: title.text.trim().isEmpty ? 'CV tanpa judul' : title.text.trim(),
                  template: template,
                  data: ResumeData(
                    contact: Contact(fullName: user?.fullName ?? '', email: user?.email ?? ''),
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx, r);
              } catch (e) {
                setState(() => busy = false);
                if (ctx.mounted) Toast.show(ctx, friendlyError(e), tone: Tone.error);
              }
            },
          ),
        ],
      ),
    ),
  );
  if (created != null && context.mounted) {
    push(context, EditorScreen(resumeId: created.id));
  }
}

class TemplateTile extends StatelessWidget {
  const TemplateTile({super.key, required this.template, required this.selected, required this.onTap});
  final CvTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        selected: selected,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          decoration: selected
              ? Clay.box(context, color: context.isDark ? c.slab : Palette.lemon, radius: Clay.radiusM, depth: 0.6)
              : Clay.well(context, radius: Clay.radiusM),
          child: InkWell(
            borderRadius: BorderRadius.circular(Clay.radiusM),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _TemplateGlyph(template: template, selected: selected),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(template.label, style: context.text.titleSmall),
                        const SizedBox(height: 2),
                        Text(template.description, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: Motion.of(context, Motion.medium),
                    curve: Motion.backOut,
                    child: Hi(HugeIcons.strokeRoundedCheckmarkCircle02, color: c.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tiny page sketch per template so the choice is visual, not just a name.
/// Each variant mirrors the real PDF's structure (alignment, density, order).
class _TemplateGlyph extends StatelessWidget {
  const _TemplateGlyph({required this.template, required this.selected});
  final CvTemplate template;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? Palette.turf : context.clay.inkMuted;
    Widget bar(double w, {double h = 4, double o = 0.55, AlignmentGeometry a = Alignment.centerLeft}) => Align(
      alignment: a,
      child: Container(
        width: w,
        height: h,
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: ink.withValues(alpha: o),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
    final lines = switch (template) {
      CvTemplate.harvard => [
        bar(20, h: 6, o: 0.95, a: Alignment.center),
        bar(28, a: Alignment.center),
        bar(30),
        bar(24),
        bar(30),
      ],
      CvTemplate.modern => [bar(22, h: 6, o: 0.95), bar(14, o: 0.35), bar(30), bar(26), bar(30)],
      CvTemplate.compact => [
        bar(18, h: 5, o: 0.95),
        bar(30, h: 3),
        bar(30, h: 3),
        bar(26, h: 3),
        bar(30, h: 3),
        bar(22, h: 3),
      ],
      CvTemplate.executive => [bar(20, h: 6, o: 0.95), bar(30, h: 8, o: 0.28), bar(30), bar(24), bar(30)],
    };
    return Container(
      width: 42,
      height: 58,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
      decoration: Clay.box(context, color: Colors.white, radius: 10, depth: 0.35),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines),
    );
  }
}

Future<void> showCvActions(BuildContext context, Resume r) async {
  final store = context.read<ResumeStore>();
  await showClaySheet<void>(
    context,
    title: r.title,
    builder: (ctx) {
      Widget action(IconData2 icon, String label, VoidCallback onTap, {bool danger = false}) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        minTileHeight: 56,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Hi(icon, color: danger ? ctx.clay.danger : ctx.clay.ink),
        title: Text(label, style: ctx.text.titleSmall!.copyWith(color: danger ? ctx.clay.danger : null)),
        onTap: onTap,
      );
      return Column(
        children: [
          action(HugeIcons.strokeRoundedEdit02, 'Ubah nama', () async {
            Navigator.pop(ctx);
            final ctrl = TextEditingController(text: r.title);
            final ok = await showClayDialog<bool>(
              context,
              title: 'Ubah nama CV',
              body: ClayField(controller: ctrl, placeholder: 'Nama CV'),
              actions: (d) => [
                ClayButton(label: 'Batal', tone: ClayButtonTone.ghost, onPressed: () => Navigator.pop(d, false)),
                ClayButton(label: 'Simpan', compact: true, onPressed: () => Navigator.pop(d, true)),
              ],
            );
            if (ok == true && ctrl.text.trim().isNotEmpty) {
              r.title = ctrl.text.trim();
              store.touch(r);
            }
          }),
          action(HugeIcons.strokeRoundedCopy01, 'Duplikat untuk posisi lain', () async {
            Navigator.pop(ctx);
            try {
              await store.duplicate(r);
              if (context.mounted) Toast.show(context, 'Salinan dibuat.', tone: Tone.success);
            } catch (e) {
              if (context.mounted) Toast.show(context, friendlyError(e), tone: Tone.error);
            }
          }),
          action(HugeIcons.strokeRoundedDelete02, 'Hapus', danger: true, () async {
            Navigator.pop(ctx);
            final ok = await confirmClay(
              context,
              title: 'Hapus “${r.title}”?',
              message: 'CV ini akan dihapus permanen dari akunmu.',
              confirmLabel: 'Hapus',
              destructive: true,
            );
            if (!ok) return;
            try {
              await store.delete(r);
              if (context.mounted) Toast.show(context, 'CV dihapus.', tone: Tone.info);
            } catch (e) {
              if (context.mounted) Toast.show(context, friendlyError(e), tone: Tone.error);
            }
          }),
        ],
      );
    },
  );
}
