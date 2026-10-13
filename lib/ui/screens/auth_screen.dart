import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../core/env.dart';
import '../../core/motion.dart';
import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';
import '../../state/resume_store.dart';
import '../../state/session.dart';
import '../kit/brand.dart';
import '../kit/clay_widgets.dart';
import '../kit/feedback.dart';
import '../routes.dart';
import 'home_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = false;
  bool _busy = false;
  bool _showPass = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String? _nameErr, _emailErr, _passErr;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameErr = _register && _name.text.trim().length < 2 ? 'Tulis nama lengkapmu.' : null;
      _emailErr = RegExp(r'^\S+@\S+\.\S+$').hasMatch(_email.text.trim()) ? null : 'Format email belum benar.';
      _passErr = _pass.text.length < 8 ? 'Minimal 8 karakter.' : null;
    });
    return _nameErr == null && _emailErr == null && _passErr == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _busy = true);
    final session = context.read<Session>();
    final store = context.read<ResumeStore>();
    try {
      if (_register) {
        await session.register(_name.text, _email.text, _pass.text);
      } else {
        await session.login(_email.text, _pass.text);
      }
      await store.bind(session.user!.id);
      if (!mounted) return;
      Toast.show(
        context,
        _register ? 'Akun dibuat. Selamat datang!' : 'Halo lagi, ${session.user!.firstName}!',
        tone: Tone.success,
      );
      Navigator.of(context).pushReplacement(fadeRoute(const HomeShell()));
    } catch (e) {
      if (mounted) Toast.show(context, friendlyError(e), tone: Tone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(children: [const LogoMark(size: 34), const SizedBox(width: 10), const Wordmark(size: 22)]),
            const SizedBox(height: 8),
            Center(child: Lottie.asset('assets/lottie/hero.json', height: 230, animate: !Motion.reduced(context))),
            Text(
              _register ? 'Bikin CV yang lolos\nsaringan ATS.' : 'Lanjutkan CV-mu,\nsampai siap kirim.',
              style: context.text.displaySmall,
            ).animate(key: ValueKey(_register)).fadeIn(duration: 300.ms).slideX(begin: -0.04, curve: Motion.expoOut),
            const SizedBox(height: 10),
            Text(
              'Template internasional satu kolom, skor ATS, pencocokan lowongan, dan bantuan AI untuk kalimatmu.',
              style: context.text.bodyLarge!.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: 24),
            _ModeSwitch(register: _register, onChanged: (v) => setState(() => _register = v)),
            const SizedBox(height: 20),
            if (!Env.hasDatabase) ...[
              const ClayBanner(
                title: 'Database belum terhubung',
                message: 'Versi app ini dibuat tanpa koneksi database, jadi akun belum bisa dibuat. Pasang ulang versi yang lengkap.',
                tone: Tone.error,
              ),
              const SizedBox(height: 16),
            ],
            AutofillGroup(
              child: Column(
                children: [
                  AnimatedSize(
                    duration: Motion.of(context, Motion.medium),
                    curve: Motion.expoOut,
                    child: _register
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ClayField(
                              label: 'Nama lengkap',
                              controller: _name,
                              placeholder: 'Contoh: Hilal Andi',
                              error: _nameErr,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              capitalization: TextCapitalization.words,
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  ClayField(
                    label: 'Email',
                    controller: _email,
                    placeholder: 'nama@email.com',
                    error: _emailErr,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    capitalization: TextCapitalization.none,
                  ),
                  const SizedBox(height: 16),
                  ClayField(
                    label: 'Kata sandi',
                    controller: _pass,
                    placeholder: 'Minimal 8 karakter',
                    error: _passErr,
                    obscure: !_showPass,
                    textInputAction: TextInputAction.done,
                    autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
                    capitalization: TextCapitalization.none,
                    onSubmitted: (_) => _submit(),
                    trailing: IconButton(
                      tooltip: _showPass ? 'Sembunyikan' : 'Tampilkan',
                      onPressed: () => setState(() => _showPass = !_showPass),
                      icon: Hi(
                        _showPass ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
                        size: 20,
                        color: c.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ClayButton(
              label: _register ? 'Buat akun' : 'Masuk',
              icon: HugeIcons.strokeRoundedArrowRight01,
              expand: true,
              loading: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-option segmented control with a sliding clay knob.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.register, required this.onChanged});
  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    Widget option(String label, bool value) => Expanded(
      child: Semantics(
        selected: register == value,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onChanged(value),
          child: SizedBox(
            height: 48,
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: Motion.of(context, Motion.fast),
                style: context.text.labelLarge!.copyWith(color: register == value ? c.onPrimary : c.inkMuted),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      decoration: Clay.well(context, radius: 22),
      padding: const EdgeInsets.all(5),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: register ? Alignment.centerRight : Alignment.centerLeft,
            duration: Motion.of(context, Motion.medium),
            curve: Motion.backOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(height: 48, decoration: Clay.box(context, color: c.primary, radius: 18, depth: 0.6)),
            ),
          ),
          Row(children: [option('Masuk', false), option('Daftar', true)]),
        ],
      ),
    );
  }
}
