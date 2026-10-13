import 'package:flutter/widgets.dart';

/// GSAP-style easing and timing, expressed for Flutter.
/// (GSAP itself is web-only; these curves mirror its named eases.)
class Motion {
  static const expoOut = Cubic(0.16, 1, 0.3, 1); // gsap "expo.out"
  static const power3Out = Cubic(0.215, 0.61, 0.355, 1); // "power3.out"
  static const power2InOut = Cubic(0.645, 0.045, 0.355, 1); // "power2.inOut"
  static const backOut = Cubic(0.34, 1.56, 0.64, 1); // "back.out(1.7)"

  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 560);
  static const stagger = Duration(milliseconds: 55);

  /// Respect the system "Remove animations" setting.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}
