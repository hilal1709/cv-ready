import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/motion.dart';
import '../../core/theme/palette.dart';
import '../../services/ats_scorer.dart' show CheckStatus;
import 'clay_widgets.dart';

/// Colour and spoken label for a section/check status, shared by the rail,
/// the glyph and the semantics so they never drift apart.
(Color, String) statusLook(BuildContext context, CheckStatus s, {bool optionalEmpty = false}) => optionalEmpty
    ? (context.clay.inkMuted, 'opsional')
    : switch (s) {
        CheckStatus.pass => (Palette.turf, 'lengkap'),
        CheckStatus.partial => (context.isDark ? Palette.willow : Palette.turfDeep, 'sebagian'),
        CheckStatus.fail => (Palette.scarlet, 'kosong'),
      };

/// A clay pebble that morphs between empty / half / done, the way a stepper
/// badge turns into a check mark once its step is finished.
class StatusGlyph extends StatelessWidget {
  const StatusGlyph({super.key, required this.status, this.optionalEmpty = false, this.size = 26});
  final CheckStatus status;
  final bool optionalEmpty;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (color, _) = statusLook(context, status, optionalEmpty: optionalEmpty);
    final done = status == CheckStatus.pass && !optionalEmpty;
    final half = status == CheckStatus.partial;
    return AnimatedContainer(
      duration: Motion.of(context, Motion.medium),
      curve: Motion.backOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : color.withValues(alpha: 0.14),
        border: Border.all(color: color, width: done ? 0 : 2),
      ),
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.medium),
        switchInCurve: Motion.backOut,
        transitionBuilder: (child, a) => ScaleTransition(
          scale: a,
          child: FadeTransition(opacity: a, child: child),
        ),
        child: done
            ? Hi(HugeIcons.strokeRoundedTick02, key: const ValueKey('done'), size: size * 0.64, color: Colors.white)
            : half
            ? Container(
                key: const ValueKey('half'),
                width: size * 0.34,
                height: size * 0.34,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            : Hi(HugeIcons.strokeRoundedAdd01, key: const ValueKey('empty'), size: size * 0.6, color: color),
      ),
    );
  }
}

/// One rounded segment per section. Segments fill in sequence with a spring
/// overshoot, so the rail reads as "N of M pressed into shape".
class SectionRail extends StatelessWidget {
  const SectionRail({super.key, required this.statuses, this.optionalEmpty = const []});
  final List<CheckStatus> statuses;

  /// Same length as [statuses]; true marks an empty optional section.
  final List<bool> optionalEmpty;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    bool opt(int i) => i < optionalEmpty.length && optionalEmpty[i];
    final done = [
      for (var i = 0; i < statuses.length; i++)
        if (statuses[i] == CheckStatus.pass && !opt(i)) i,
    ].length;
    return Semantics(
      label: '$done dari ${statuses.length} bagian CV lengkap',
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < statuses.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Expanded(
                    child: _Segment(status: statuses[i], index: i, optionalEmpty: opt(i)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(end: done.toDouble()),
            duration: Motion.of(context, Motion.slow),
            curve: Motion.expoOut,
            builder: (context, v, _) => Text(
              '${v.round()}/${statuses.length}',
              style: context.text.labelLarge!.copyWith(
                color: c.inkMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.status, required this.index, required this.optionalEmpty});
  final CheckStatus status;
  final bool optionalEmpty;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final (color, _) = statusLook(context, status, optionalEmpty: optionalEmpty);
    final fill = optionalEmpty
        ? 0.0
        : switch (status) {
            CheckStatus.pass => 1.0,
            CheckStatus.partial => 0.5,
            CheckStatus.fail => 0.0,
          };
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 10,
        color: c.line,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fill),
          duration: Motion.of(context, Motion.slow + Motion.stagger * index),
          curve: Motion.backOut,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v.clamp(0.0, 1.0),
            child: Container(color: color),
          ),
        ),
      ),
    );
  }
}
