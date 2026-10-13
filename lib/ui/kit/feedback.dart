import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';

import '../../core/motion.dart';
import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';
import 'clay_widgets.dart';

enum Tone { success, error, info, warning }

/// Turns any thrown error into copy a user can act on. Our own exceptions
/// already carry Indonesian messages; anything else gets a generic recovery.
String friendlyError(Object e) {
  final known = ['DbException', 'AuthException', 'AiException'];
  if (known.contains(e.runtimeType.toString())) return '$e';
  return 'Ada yang tidak beres. Cek koneksi internet, lalu coba lagi.';
}

extension on Tone {
  (Color bg, Color fg, IconData2 icon) colors(BuildContext context) {
    final c = context.clay;
    return switch (this) {
      Tone.success => (Palette.turf, Palette.lemon, HugeIcons.strokeRoundedCheckmarkCircle02),
      Tone.error => (Palette.scarlet, Colors.white, HugeIcons.strokeRoundedAlert02),
      Tone.warning => (Palette.lemon, Palette.coffee, HugeIcons.strokeRoundedInformationCircle),
      Tone.info => (context.isDark ? c.surfaceRaised : Palette.coffee, Palette.lemon, HugeIcons.strokeRoundedIdea01),
    };
  }
}

// ------------------------------------------------------------------ toast ---

/// Clay pill that drops in from the top, squashes on landing, and leaves.
class Toast {
  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    Tone tone = Tone.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _dismiss();
    if (tone == Tone.error) HapticFeedback.heavyImpact();
    final key = GlobalKey<_ToastViewState>();
    final entry = OverlayEntry(
      builder: (ctx) => _ToastView(
        key: key,
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
        onClosed: _dismiss,
      ),
    );
    _current = entry;
    overlay.insert(entry);
    SemanticsService.sendAnnouncement(View.of(context), message, TextDirection.ltr);
    _timer = Timer(Duration(milliseconds: tone == Tone.error ? 4200 : 2800), () => key.currentState?.close());
  }

  static void _dismiss() {
    _timer?.cancel();
    _current?.remove();
    _current = null;
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    super.key,
    required this.message,
    required this.tone,
    required this.onClosed,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final Tone tone;
  final VoidCallback onClosed;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status == AnimationStatus.dismissed) {
      Motion.reduced(context) ? _c.value = 1 : _c.forward();
    }
  }

  Future<void> close() async {
    if (!mounted) return;
    if (Motion.reduced(context)) return widget.onClosed();
    await _c.animateBack(0, duration: const Duration(milliseconds: 260), curve: Curves.easeIn);
    widget.onClosed();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = widget.tone.colors(context);
    final top = MediaQuery.paddingOf(context).top + 10;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value;
          final drop = Motion.expoOut.transform((t / 0.6).clamp(0, 1));
          // squash on landing (GSAP-like keyframes: 0.55→0.75 squash, →1 settle)
          final sq = t < 0.55 ? 0.0 : (t < 0.75 ? (t - 0.55) / 0.2 : 1 - (t - 0.75) / 0.25);
          return Opacity(
            opacity: drop.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, -90 * (1 - drop)),
              child: Transform.scale(scaleX: 1 + 0.04 * sq, scaleY: 1 - 0.06 * sq, child: child),
            ),
          );
        },
        child: Material(
          type: MaterialType.transparency,
          child: Dismissible(
            key: const ValueKey('toast'),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onClosed(),
            child: Container(
              decoration: Clay.box(context, color: bg, radius: 24),
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Row(
                children: [
                  Hi(icon, color: fg, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.message, style: context.text.titleSmall!.copyWith(color: fg)),
                  ),
                  if (widget.actionLabel != null)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: fg, minimumSize: const Size(48, 40)),
                      onPressed: () {
                        widget.onAction?.call();
                        close();
                      },
                      child: Text(widget.actionLabel!, style: context.text.labelLarge!.copyWith(color: fg)),
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

// ----------------------------------------------------------------- banner ---

class ClayBanner extends StatelessWidget {
  const ClayBanner({
    super.key,
    required this.title,
    this.message,
    this.tone = Tone.warning,
    this.action,
    this.illustration,
  });
  final String title;
  final String? message;
  final Tone tone;
  final Widget? action;
  final String? illustration;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = tone.colors(context);
    return Container(
      decoration: Clay.box(context, color: bg, radius: Clay.radiusL, depth: 0.7),
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Hi(icon, color: fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall!.copyWith(color: fg)),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(message!, style: context.text.bodyMedium!.copyWith(color: fg.withValues(alpha: 0.86))),
                ],
                if (action != null) ...[const SizedBox(height: 12), action!],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: Motion.of(context, Motion.medium)).slideY(begin: 0.15, curve: Motion.expoOut);
  }
}

// ------------------------------------------------------------------ modal ---

/// Clay dialog: pops up with a soft overshoot over a coffee-tinted scrim.
Future<T?> showClayDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  Widget? body,
  String? illustration,
  String? lottie,
  required List<Widget> Function(BuildContext ctx) actions,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup',
    barrierColor: Palette.coffee.withValues(alpha: 0.42),
    transitionDuration: Motion.of(context, const Duration(milliseconds: 420)),
    pageBuilder: (ctx, a, b) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: Clay.box(ctx, color: ctx.clay.surfaceRaised, radius: Clay.radiusXL, depth: 1.4),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lottie != null)
                      Center(child: Lottie.asset(lottie, height: 120, repeat: false, animate: !Motion.reduced(ctx))),
                    Text(title, style: ctx.text.headlineSmall),
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(message, style: ctx.text.bodyMedium!.copyWith(color: ctx.clay.inkMuted)),
                    ],
                    if (body != null) ...[const SizedBox(height: 16), body],
                    const SizedBox(height: 22),
                    Wrap(alignment: WrapAlignment.end, spacing: 10, runSpacing: 10, children: actions(ctx)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, a, b, child) {
      final curved = CurvedAnimation(parent: a, curve: Motion.backOut, reverseCurve: Curves.easeIn);
      return FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: ScaleTransition(scale: Tween(begin: 0.86, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

Future<bool> confirmClay(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showClayDialog<bool>(
    context,
    title: title,
    message: message,
    actions: (ctx) => [
      ClayButton(label: 'Batal', tone: ClayButtonTone.ghost, onPressed: () => Navigator.pop(ctx, false)),
      ClayButton(
        label: confirmLabel,
        tone: destructive ? ClayButtonTone.accent : ClayButtonTone.primary,
        compact: true,
        onPressed: () => Navigator.pop(ctx, true),
      ),
    ],
  );
  return ok ?? false;
}

/// Clay bottom sheet with a grab handle; follows the keyboard.
Future<T?> showClaySheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Palette.coffee.withValues(alpha: 0.38),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: Container(
        decoration: Clay.box(ctx, color: ctx.clay.surfaceRaised, radius: Clay.radiusXL, depth: 1.2),
        // Keep the sheet above the gesture/navigation bar.
        margin: EdgeInsets.fromLTRB(8, 0, 8, 8 + MediaQuery.viewPaddingOf(ctx).bottom),
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(color: ctx.clay.line, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              Text(title, style: ctx.text.headlineSmall),
              const SizedBox(height: 16),
              builder(ctx),
            ],
          ),
        ),
      ),
    ),
  );
}

// -------------------------------------------------------- busy overlay ---

/// Full-screen blocking loader for long actions (AI, PDF export).
Future<T> withBusy<T>(BuildContext context, String label, Future<T> Function() task) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final entry = OverlayEntry(
    builder: (ctx) => Positioned.fill(
      child: Material(
        color: Palette.coffee.withValues(alpha: 0.40),
        child: Center(
          child: Container(
            width: 240,
            decoration: Clay.box(ctx, color: ctx.clay.surfaceRaised, radius: Clay.radiusXL, depth: 1.3),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ClayLoader(size: 150),
                Text(label, textAlign: TextAlign.center, style: ctx.text.titleSmall),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9), curve: Motion.backOut),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    return await task();
  } finally {
    entry.remove();
  }
}
