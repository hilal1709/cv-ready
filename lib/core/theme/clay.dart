import 'package:flutter/material.dart';

import 'palette.dart';

/// Claymorphism material: a soft extruded body lit from the top-left.
/// Depth = a coffee-tinted drop shadow with a real offset + a tight contact
/// shadow; volume = a diagonal light→base→shade gradient; rim = a faint
/// highlight on the top edge.
class Clay {
  static const radiusS = 16.0;
  static const radiusM = 22.0;
  static const radiusL = 28.0;
  static const radiusXL = 36.0;

  static BoxDecoration box(
    BuildContext context, {
    required Color color,
    double radius = radiusL,
    double depth = 1,
    bool pressed = false,
    bool flat = false,
  }) {
    final c = context.clay;
    final dark = context.isDark;
    // Saturated/dark fills carry text, so their sheen stays subtle (keeps labels >= 4.5:1).
    final strongFill = color.computeLuminance() < 0.35;
    final light = Color.lerp(color, c.highlight, dark || strongFill ? 0.08 : 0.30)!;
    final shade = Color.lerp(color, c.shadow, dark ? 0.22 : 0.10)!;
    final d = pressed ? depth * 0.35 : depth;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: pressed ? [shade, color, light] : [light, color, shade],
        stops: const [0, 0.55, 1],
      ),
      boxShadow: flat
          ? null
          : [
              if (!pressed)
                BoxShadow(
                  color: c.highlight.withValues(alpha: dark ? 0.06 : 0.75),
                  offset: Offset(-4 * d, -4 * d),
                  blurRadius: 12 * d,
                  spreadRadius: -2,
                ),
              BoxShadow(
                color: c.shadow.withValues(alpha: (dark ? 0.45 : 0.16) * d.clamp(0, 1.4)),
                offset: Offset(0, 12 * d),
                blurRadius: 28 * d,
                spreadRadius: -6,
              ),
              BoxShadow(
                color: c.shadow.withValues(alpha: (dark ? 0.35 : 0.10) * d.clamp(0, 1.4)),
                offset: Offset(0, 3 * d),
                blurRadius: 6 * d,
                spreadRadius: -1,
              ),
            ],
    );
  }

  /// A recessed well (inputs, tracks): darker at the top edge, as if pressed in.
  static BoxDecoration well(BuildContext context, {double radius = radiusM, bool focused = false, bool error = false}) {
    final c = context.clay;
    final dark = context.isDark;
    final base = dark ? Color.lerp(c.ground, Colors.black, 0.15)! : Color.lerp(c.ground, Palette.willow, 0.10)!;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(base, c.shadow, dark ? 0.25 : 0.07)!, base, base],
        stops: const [0, 0.22, 1],
      ),
      border: Border.all(
        color: error
            ? c.danger
            : focused
            ? c.primary
            : c.line.withValues(alpha: dark ? 0.6 : 0.9),
        width: focused || error ? 1.6 : 1,
      ),
    );
  }
}
