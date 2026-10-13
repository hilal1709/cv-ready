import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/motion.dart';
import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';

typedef IconData2 = List<List<dynamic>>;

/// Hugeicons, one stroke weight everywhere.
class Hi extends StatelessWidget {
  const Hi(this.icon, {super.key, this.size = 22, this.color});
  final IconData2 icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => HugeIcon(
    icon: icon,
    size: size,
    strokeWidth: 1.8,
    color: color ?? IconTheme.of(context).color ?? context.clay.ink,
  );
}

/// A pressable clay body: squashes slightly and sinks its shadow on press.
class ClayPressable extends StatefulWidget {
  const ClayPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.radius = Clay.radiusL,
    this.padding = const EdgeInsets.all(18),
    this.depth = 1,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double depth;
  final String? semanticLabel;

  @override
  State<ClayPressable> createState() => _ClayPressableState();
}

class _ClayPressableState extends State<ClayPressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.clay.surfaceRaised;
    final d = Motion.of(context, Motion.fast);
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!();
              },
        child: AnimatedScale(
          scale: _down ? 0.975 : 1,
          duration: d,
          curve: Motion.power3Out,
          child: AnimatedContainer(
            duration: d,
            curve: Motion.power3Out,
            decoration: Clay.box(context, color: color, radius: widget.radius, depth: widget.depth, pressed: _down),
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

enum ClayButtonTone { primary, accent, soft, ghost }

class ClayButton extends StatelessWidget {
  const ClayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.tone = ClayButtonTone.primary,
    this.loading = false,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData2? icon;
  final ClayButtonTone tone;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final (bg, fg) = switch (tone) {
      ClayButtonTone.primary => (c.primary, c.onPrimary),
      ClayButtonTone.accent => (c.accent, c.onAccent),
      ClayButtonTone.soft => (context.isDark ? c.surfaceRaised : Palette.lemon, c.ink),
      ClayButtonTone.ghost => (Colors.transparent, c.primary),
    };
    final disabled = onPressed == null || loading;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(height: 22, width: 44, child: ClayLoader(size: 44, tint: fg))
        else ...[
          if (icon != null) ...[Hi(icon!, size: 20, color: fg), const SizedBox(width: 10)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelLarge!.copyWith(color: fg),
            ),
          ),
        ],
      ],
    );
    final padding = EdgeInsets.symmetric(horizontal: compact ? 16 : 22, vertical: compact ? 12 : 16);
    if (tone == ClayButtonTone.ghost) {
      return TextButton(
        onPressed: disabled ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          padding: padding,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Clay.radiusM)),
        ),
        child: content,
      );
    }
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
        child: ClayPressable(
          onTap: disabled ? null : onPressed,
          color: bg,
          radius: Clay.radiusM,
          depth: 0.8,
          padding: padding,
          semanticLabel: label,
          child: content,
        ),
      ),
    );
  }
}

/// Round clay icon button (48dp target).
class ClayIconButton extends StatelessWidget {
  const ClayIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.iconColor,
  });
  final IconData2 icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      width: 48,
      height: 48,
      child: ClayPressable(
        onTap: onPressed,
        color: color ?? context.clay.surfaceRaised,
        radius: 16,
        depth: 0.55,
        padding: EdgeInsets.zero,
        semanticLabel: tooltip,
        child: Center(child: Hi(icon, size: 21, color: iconColor ?? context.clay.ink)),
      ),
    ),
  );
}

/// Text field: shadcn_ui ShadInput dressed as a recessed clay well.
class ClayField extends StatelessWidget {
  const ClayField({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.placeholder,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscure = false,
    this.maxLines = 1,
    this.minLines,
    this.error,
    this.hint,
    this.trailing,
    this.autofillHints,
    this.capitalization = TextCapitalization.sentences,
    this.onSubmitted,
  });

  final String? label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscure;
  final int? maxLines;
  final int? minLines;
  final String? error;
  final String? hint;
  final Widget? trailing;
  final Iterable<String>? autofillHints;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final well = Clay.well(context);
    final radius = BorderRadius.circular(Clay.radiusM);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label!, style: context.text.titleSmall),
          ),
        ShadInput(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          placeholder: placeholder == null ? null : Text(placeholder!),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: maxLines != 1 ? TextInputType.multiline : keyboardType,
          textInputAction: textInputAction,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          minLines: minLines,
          autofillHints: autofillHints,
          textCapitalization: capitalization,
          trailing: trailing,
          style: context.text.bodyLarge,
          placeholderStyle: context.text.bodyLarge!.copyWith(color: c.inkMuted.withValues(alpha: 0.75)),
          inputPadding: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: ShadDecoration(
            gradient: well.gradient,
            border: ShadBorder.all(color: error != null ? c.danger : c.line, width: 1, radius: radius),
            focusedBorder: ShadBorder.all(color: error != null ? c.danger : c.primary, width: 1.8, radius: radius),
            secondaryFocusedBorder: ShadBorder.none,
            secondaryBorder: ShadBorder.none,
          ),
        ),
        if (error != null || hint != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 6),
            child: Text(
              error ?? hint!,
              style: context.text.bodySmall!.copyWith(color: error != null ? c.danger : c.inkMuted),
            ),
          ),
      ],
    );
  }
}

/// Three clay pebbles hopping (Lottie). Used for every loading state.
class ClayLoader extends StatelessWidget {
  const ClayLoader({super.key, this.size = 120, this.tint});
  final double size;

  /// When set (e.g. on a coloured button) the pebbles take this single colour.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final anim = Lottie.asset(
      'assets/lottie/loading.json',
      width: size,
      height: size * 0.7,
      fit: BoxFit.contain,
      animate: !Motion.reduced(context),
      delegates: tint == null
          ? null
          : LottieDelegates(
              values: [
                ValueDelegate.gradientColor(const ['**'], value: [tint!, tint!, tint!]),
                ValueDelegate.color(const ['**'], value: tint!.withValues(alpha: 0.4)),
              ],
            ),
    );
    return Semantics(label: 'Memuat', child: anim);
  }
}

/// Section heading used across screens (no eyebrow labels by design).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 28, 4, 12),
    child: Row(
      children: [
        Expanded(child: Text(text, style: context.text.headlineSmall)),
        ?trailing,
      ],
    ),
  );
}
