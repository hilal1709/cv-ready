import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../core/theme/palette.dart';
import '../../state/resume_store.dart';
import '../../state/session.dart';
import '../kit/brand.dart';
import '../routes.dart';
import 'auth_screen.dart';
import 'home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go());
  }

  Future<void> _go() async {
    final session = context.read<Session>();
    final store = context.read<ResumeStore>();
    final binding = session.signedIn ? store.bind(session.user!.id) : Future<void>.value();
    await Future.wait([binding, Future.delayed(const Duration(milliseconds: 1500))]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(session.signedIn ? const HomeShell() : const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    return Scaffold(
      backgroundColor: c.slab,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoMark(size: 120, animate: true, lineColor: Palette.lemon),
            const SizedBox(height: 18),
            Wordmark(color: Palette.lemon, size: 34)
                .animate(delay: 900.ms)
                .fadeIn(duration: Motion.of(context, Motion.medium))
                .slideY(begin: 0.3, curve: Motion.expoOut),
          ],
        ),
      ),
    );
  }
}
