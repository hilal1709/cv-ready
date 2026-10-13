import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'palette.dart';

class AppTheme {
  static const display = 'Bricolage';
  static const body = 'Figtree';

  static TextTheme _text(Color ink, Color muted) {
    TextStyle d(double size, FontWeight w, {double h = 1.1, double ls = -0.5}) =>
        TextStyle(fontFamily: display, fontSize: size, fontWeight: w, height: h, letterSpacing: ls, color: ink);
    TextStyle b(double size, FontWeight w, {double h = 1.45, Color? color, double ls = 0}) =>
        TextStyle(fontFamily: body, fontSize: size, fontWeight: w, height: h, letterSpacing: ls, color: color ?? ink);
    return TextTheme(
      displayLarge: d(52, FontWeight.w800, ls: -1.6),
      displayMedium: d(42, FontWeight.w800, ls: -1.2),
      displaySmall: d(34, FontWeight.w800, ls: -1.0),
      headlineLarge: d(30, FontWeight.w700, ls: -0.8),
      headlineMedium: d(26, FontWeight.w700, ls: -0.6),
      headlineSmall: d(22, FontWeight.w700, ls: -0.4, h: 1.2),
      titleLarge: b(19, FontWeight.w700, h: 1.3, ls: -0.2),
      titleMedium: b(16, FontWeight.w700, h: 1.3),
      titleSmall: b(14, FontWeight.w600, h: 1.3),
      bodyLarge: b(16, FontWeight.w400),
      bodyMedium: b(14.5, FontWeight.w400),
      bodySmall: b(13, FontWeight.w400, color: muted),
      labelLarge: b(15, FontWeight.w700, h: 1.2, ls: 0.1),
      labelMedium: b(13, FontWeight.w600, h: 1.2, color: muted),
      labelSmall: b(11.5, FontWeight.w600, h: 1.2, color: muted, ls: 0.2),
    );
  }

  static ThemeData material(Brightness brightness) {
    final c = brightness == Brightness.dark ? ClayColors.dark : ClayColors.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.successSoft,
      onPrimaryContainer: c.ink,
      secondary: Palette.willow,
      onSecondary: Palette.coffee,
      secondaryContainer: brightness == Brightness.dark ? c.surfaceRaised : Palette.turfSoft,
      onSecondaryContainer: c.ink,
      tertiary: Palette.lemon,
      onTertiary: Palette.coffee,
      error: c.danger,
      onError: Colors.white,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.ink,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.ground,
      surfaceContainerLow: c.ground,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceRaised,
      surfaceContainerHighest: c.surfaceRaised,
      outline: c.line,
      outlineVariant: c.line,
      shadow: c.shadow,
      scrim: Palette.coffee,
      inverseSurface: c.ink,
      onInverseSurface: c.ground,
      inversePrimary: Palette.willow,
    );
    final text = _text(c.ink, c.inkMuted);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.ground,
      fontFamily: body,
      textTheme: text,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: Palette.willow.withValues(alpha: 0.45),
        selectionHandleColor: c.primary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.ground,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceRaised,
        indicatorColor: brightness == Brightness.dark ? c.slab : Palette.lemon,
        height: 72,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium!.copyWith(
            color: s.contains(WidgetState.selected) ? c.ink : c.inkMuted,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder()},
      ),
    );
  }

  /// shadcn_ui theme mapped onto the same palette so Shad inputs, selects
  /// and tabs read as part of the clay world.
  static ShadThemeData shad(Brightness brightness) {
    final c = brightness == Brightness.dark ? ClayColors.dark : ClayColors.light;
    return ShadThemeData(
      brightness: brightness,
      radius: BorderRadius.circular(18),
      colorScheme: ShadColorScheme(
        background: c.ground,
        foreground: c.ink,
        card: c.surfaceRaised,
        cardForeground: c.ink,
        popover: c.surfaceRaised,
        popoverForeground: c.ink,
        primary: c.primary,
        primaryForeground: c.onPrimary,
        secondary: c.successSoft,
        secondaryForeground: c.ink,
        muted: c.surface,
        mutedForeground: c.inkMuted,
        accent: brightness == Brightness.dark ? c.slab : Palette.lemon,
        accentForeground: c.ink,
        destructive: c.danger,
        destructiveForeground: Colors.white,
        border: c.line,
        input: c.line,
        ring: c.primary,
        selection: Palette.willow.withValues(alpha: 0.45),
      ),
      textTheme: ShadTextTheme(family: body),
    );
  }
}
