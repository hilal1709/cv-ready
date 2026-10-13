import 'package:flutter/material.dart';

import '../core/motion.dart';

/// Fade-through for top-level swaps (splash → auth → home).
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 480),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (context, a, _, child) {
    if (Motion.reduced(context)) return child;
    final curved = CurvedAnimation(parent: a, curve: Motion.expoOut);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(curved), child: child),
    );
  },
);

/// Forward navigation; uses the theme's predictive-back transition on Android.
Future<T?> push<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

/// Wizard-style hop to the next step: the new page slides in from the right
/// while the old one eases away. Replaces the current route so Back returns
/// to the screen the user started from, not to the step they just left.
Future<T?> pushStep<T, R>(BuildContext context, Widget page) => Navigator.of(context).pushReplacement<T, R>(
  PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, a, secondary, child) {
      if (Motion.reduced(context)) return child;
      final curved = CurvedAnimation(parent: a, curve: Motion.expoOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  ),
);
