import 'package:flutter/material.dart';

/// The five brand colours (Coolors export), plus tones derived from them.
/// Every UI colour in the app resolves back to one of these five.
class Palette {
  static const scarlet = Color(0xFFDA2C38); // Scarlet Rush
  static const turf = Color(0xFF226F54); // Turf Green
  static const willow = Color(0xFF87C38F); // Willow Green
  static const lemon = Color(0xFFF4F0BB); // Lemon Chiffon
  static const coffee = Color(0xFF43291F); // Dark Coffee

  // Derived tones (mixes of the five with white / each other).
  static const ground = Color(0xFFE9F1E4); // light app ground (willow-tinted)
  static final groundDeep = Color.lerp(willow, Colors.white, 0.62)!;
  static final paper = Color.lerp(lemon, Colors.white, 0.35)!; // cards / CV sheets
  static final turfDeep = Color.lerp(turf, coffee, 0.35)!;
  static final turfSoft = Color.lerp(turf, Colors.white, 0.86)!;
  static final scarletSoft = Color.lerp(scarlet, Colors.white, 0.86)!;
  static final scarletDeep = Color.lerp(scarlet, coffee, 0.30)!;
  static final coffeeMuted = Color.lerp(coffee, Colors.white, 0.38)!;
  static final coffeeLine = Color.lerp(coffee, Colors.white, 0.84)!;

  // Dark theme grounds: Dark Coffee family.
  static final night = Color.lerp(coffee, Colors.black, 0.45)!;
  static final nightRaised = Color.lerp(coffee, Colors.black, 0.18)!;
  static final nightHigh = coffee;
  static final nightInk = Color.lerp(lemon, Colors.white, 0.4)!;
  static final nightMuted = Color.lerp(lemon, coffee, 0.42)!;
}

/// Semantic colours that flip between light and dark.
@immutable
class ClayColors extends ThemeExtension<ClayColors> {
  const ClayColors({
    required this.ground,
    required this.surface,
    required this.surfaceRaised,
    required this.paper,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.shadow,
    required this.highlight,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.successSoft,
    required this.danger,
    required this.dangerSoft,
    required this.slab,
    required this.onSlab,
  });

  final Color ground;
  final Color surface;
  final Color surfaceRaised;
  final Color paper;
  final Color ink;
  final Color inkMuted;
  final Color line;
  final Color shadow;
  final Color highlight;
  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color successSoft;
  final Color danger;
  final Color dangerSoft;
  final Color slab;
  final Color onSlab;

  static final light = ClayColors(
    ground: Palette.ground,
    surface: Color.lerp(Palette.ground, Colors.white, 0.55)!,
    surfaceRaised: Color.lerp(Palette.lemon, Colors.white, 0.70)!,
    paper: Palette.paper,
    ink: Palette.coffee,
    inkMuted: Palette.coffeeMuted,
    line: Palette.coffeeLine,
    shadow: Palette.coffee,
    highlight: Colors.white,
    primary: Palette.turf,
    onPrimary: Palette.lemon,
    accent: Palette.scarlet,
    onAccent: Colors.white,
    success: Palette.turf,
    successSoft: Palette.turfSoft,
    danger: Palette.scarlet,
    dangerSoft: Palette.scarletSoft,
    slab: Palette.turf,
    onSlab: Palette.lemon,
  );

  static final dark = ClayColors(
    ground: Palette.night,
    surface: Palette.nightRaised,
    surfaceRaised: Palette.nightHigh,
    paper: Color.lerp(Palette.coffee, Palette.lemon, 0.10)!,
    ink: Palette.nightInk,
    inkMuted: Palette.nightMuted,
    line: Color.lerp(Palette.coffee, Palette.lemon, 0.18)!,
    shadow: Colors.black,
    highlight: Color.lerp(Palette.coffee, Palette.lemon, 0.22)!,
    primary: Palette.willow,
    onPrimary: Palette.coffee,
    accent: Color.lerp(Palette.scarlet, Colors.white, 0.12)!,
    onAccent: Colors.white,
    success: Palette.willow,
    successSoft: Color.lerp(Palette.coffee, Palette.willow, 0.22)!,
    danger: Color.lerp(Palette.scarlet, Colors.white, 0.18)!,
    dangerSoft: Color.lerp(Palette.coffee, Palette.scarlet, 0.28)!,
    slab: Color.lerp(Palette.turf, Colors.black, 0.25)!,
    onSlab: Palette.lemon,
  );

  @override
  ClayColors copyWith() => this;

  @override
  ClayColors lerp(ClayColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ClayColors(
      ground: l(ground, other.ground),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      paper: l(paper, other.paper),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      line: l(line, other.line),
      shadow: l(shadow, other.shadow),
      highlight: l(highlight, other.highlight),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      slab: l(slab, other.slab),
      onSlab: l(onSlab, other.onSlab),
    );
  }
}

extension ClayContext on BuildContext {
  ClayColors get clay => Theme.of(this).extension<ClayColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
