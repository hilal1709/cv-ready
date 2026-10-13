import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/motion.dart';
import '../../core/theme/palette.dart';

/// The CV Ready mark: three lines of a CV ending in a full stop.
/// [animate] plays the assembly (lines grow, the dot drops and squashes).
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 64, this.animate = false, this.lineColor, this.dotColor});
  final double size;
  final bool animate;
  final Color? lineColor;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final u = size / 256;
    final line = lineColor ?? Palette.turf;
    final dot = dotColor ?? Palette.scarlet;
    final play = animate && !Motion.reduced(context);

    Widget bar(double left, double top, double w, int i) {
      Widget b = Container(
        width: w * u,
        height: 34 * u,
        decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(17 * u)),
      );
      if (play) {
        b = b
            .animate(delay: (120 * i).ms)
            .scaleX(begin: 0, alignment: Alignment.centerLeft, duration: 520.ms, curve: Motion.expoOut);
      }
      return Positioned(left: left * u, top: top * u, child: b);
    }

    Widget d = Container(
      width: 42 * u,
      height: 42 * u,
      decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
    );
    if (play) {
      d = d
          .animate(delay: 520.ms)
          .moveY(begin: -150 * u, duration: 380.ms, curve: Curves.easeIn)
          .scale(
            delay: 380.ms,
            begin: const Offset(1.3, 0.72),
            end: const Offset(1, 1),
            alignment: Alignment.bottomCenter,
            duration: 420.ms,
            curve: Motion.backOut,
          );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          bar(40, 62, 176, 0),
          bar(40, 111, 128, 1),
          bar(40, 160, 80, 2),
          Positioned(left: 139 * u, top: 156 * u, child: d),
        ],
      ),
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.color, this.size = 22});
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        const TextSpan(text: 'CV Ready'),
        TextSpan(
          text: '.',
          style: TextStyle(color: Palette.scarlet),
        ),
      ],
    ),
    style: TextStyle(
      fontFamily: 'Bricolage',
      fontWeight: FontWeight.w800,
      fontSize: size,
      letterSpacing: -0.6,
      height: 1,
      color: color ?? context.clay.ink,
    ),
  );
}

/// Static clay illustration that floats gently.
class Illustration extends StatelessWidget {
  const Illustration(this.name, {super.key, this.height = 180, this.semanticLabel});
  final String name;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final img = SvgPicture.asset('assets/illustrations/$name.svg', height: height, semanticsLabel: semanticLabel);
    if (Motion.reduced(context)) return img;
    return img
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 2400.ms, curve: Motion.power2InOut);
  }
}

/// The signature element: a clay disc whose "ink" rises to the score and
/// squashes like the logo's full stop whenever the score changes.
class ReadinessStamp extends StatefulWidget {
  const ReadinessStamp({super.key, required this.score, this.size = 132, this.label, this.onSurface});
  final int score;
  final double size;
  final String? label;

  /// Colour of the surface the stamp sits on (adjusts the rim).
  final Color? onSurface;

  static Color colorFor(int score) => score >= 80
      ? Palette.turf
      : score >= 50
      ? Palette.willow
      : Palette.scarlet;

  @override
  State<ReadinessStamp> createState() => _ReadinessStampState();
}

class _ReadinessStampState extends State<ReadinessStamp> with TickerProviderStateMixin {
  late final _fill = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final _squash = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final _wave = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  double _from = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Motion.reduced(context)) {
        _fill.value = 1;
      } else {
        _fill.forward();
        _squash.forward(from: 0);
        _wave.repeat();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ReadinessStamp old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _from = _current(old.score);
      if (Motion.reduced(context)) {
        _fill.value = 1;
      } else {
        _fill.forward(from: 0);
        _squash.forward(from: 0);
      }
    }
  }

  double _current(int oldScore) {
    final t = Motion.expoOut.transform(_fill.value);
    return _from + (oldScore - _from) * t;
  }

  @override
  void dispose() {
    _fill.dispose();
    _squash.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Skor kesiapan ATS ${widget.score} dari 100',
      child: AnimatedBuilder(
        animation: Listenable.merge([_fill, _squash, _wave]),
        builder: (context, _) {
          final t = Motion.expoOut.transform(_fill.value);
          final value = _from + (widget.score - _from) * t;
          final s = _squash.value;
          // squash curve: compress at 0.25, overshoot at 0.55, settle at 1
          final k = s == 0 || s == 1 ? 0.0 : math.sin(s * math.pi * 2) * (1 - s);
          return Transform.scale(
            scaleX: 1 + 0.10 * k,
            scaleY: 1 - 0.10 * k,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _StampPainter(
                  value: value / 100,
                  wave: _wave.value,
                  ink: ReadinessStamp.colorFor(value.round()),
                  dark: context.isDark,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${value.round()}',
                        style: TextStyle(
                          fontFamily: 'Bricolage',
                          fontWeight: FontWeight.w800,
                          fontSize: widget.size * 0.34,
                          height: 1,
                          letterSpacing: -1.5,
                          color: value >= 80 ? Palette.lemon : Palette.coffee,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (widget.label != null)
                        Text(
                          widget.label!,
                          style: TextStyle(
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.w700,
                            fontSize: math.max(11, widget.size * 0.095),
                            color: (value >= 80 ? Palette.lemon : Palette.coffee).withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  _StampPainter({required this.value, required this.wave, required this.ink, required this.dark});
  final double value;
  final double wave;
  final Color ink;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    // drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, r * 0.16), width: size.width * 0.94, height: size.height * 0.94),
      Paint()
        ..color = (dark ? Colors.black : Palette.coffee).withValues(alpha: dark ? 0.45 : 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.14),
    );
    final disc = Rect.fromCircle(center: c, radius: r);
    // lemon clay body
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 1.1,
          colors: [
            Color.lerp(Palette.lemon, Colors.white, 0.55)!,
            Palette.lemon,
            Color.lerp(Palette.lemon, Palette.coffee, 0.18)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(disc),
    );
    // rising ink with a soft wave surface
    final level = size.height * (1 - value.clamp(0, 1) * 0.92) - 2;
    final path = Path()..moveTo(0, level);
    for (double x = 0; x <= size.width; x += 4) {
      path.lineTo(x, level + math.sin((x / size.width * 2 + wave * 2) * math.pi) * r * 0.035);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.save();
    canvas.clipPath(Path()..addOval(disc.deflate(r * 0.06)));
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(ink, Colors.white, 0.25)!, ink],
        ).createShader(disc)
        ..color = ink.withValues(alpha: 0.85),
    );
    canvas.restore();
    // top-left highlight (clay sheen)
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(-r * 0.38, -r * 0.48), width: r * 0.62, height: r * 0.30),
      Paint()..color = Colors.white.withValues(alpha: 0.42),
    );
  }

  @override
  bool shouldRepaint(_StampPainter old) => old.value != value || old.wave != wave || old.ink != ink;
}
