import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';
import '../../state/resume_store.dart';
import '../../state/session.dart';
import '../kit/brand.dart';
import '../kit/clay_widgets.dart';
import '../kit/feedback.dart';
import '../routes.dart';
import 'auth_screen.dart';
import 'update_flow.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  static const _guide = [
    (
      'Satu kolom, tanpa tabel atau gambar',
      'Parser ATS membaca dari kiri ke kanan, atas ke bawah. Kolom ganda, tabel, ikon, dan foto sering membuat teks tertukar atau hilang.',
    ),
    (
      'Pakai judul bagian standar',
      'Experience, Education, Skills. Judul kreatif seperti "My Journey" tidak dikenali sebagai bagian pengalaman.',
    ),
    (
      'Samakan kata kunci dengan lowongan',
      'ATS mencocokkan kata persis. Jika lowongan menulis "Project Management", jangan hanya tulis "mengelola proyek".',
    ),
    (
      'Hasil, bukan tugas',
      'Ganti "bertanggung jawab atas media sosial" dengan "Grew Instagram followers 3x in 6 months by…".',
    ),
    ('Kirim sebagai PDF teks', 'Bukan foto atau hasil scan. Beri nama file dengan namamu, misalnya Hilal_Andi_CV.pdf.'),
  ];

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user;
    final c = context.clay;
    final count = context.watch<ResumeStore>().items.length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          Text('Akun', style: context.text.headlineLarge),
          const SizedBox(height: 18),
          Container(
            decoration: Clay.box(context, color: c.paper, radius: Clay.radiusXL),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: Clay.box(context, color: Palette.scarlet, radius: 30, depth: 0.6),
                  alignment: Alignment.center,
                  child: Text(
                    (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : '?',
                    style: context.text.headlineMedium!.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? '-', style: context.text.titleLarge),
                      Text(user?.email ?? '', style: context.text.bodySmall),
                      const SizedBox(height: 4),
                      Text('$count CV tersimpan', style: context.text.labelMedium),
                    ],
                  ),
                ),
                ClayIconButton(
                  icon: HugeIcons.strokeRoundedEdit02,
                  tooltip: 'Ubah nama',
                  onPressed: () => _rename(context, session),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const ClayBanner(
            title: 'Asisten AI siap dipakai',
            message:
                'Teks hanya dikirim ke layanan AI saat kamu menekan tombol AI. Hindari menulis data sensitif seperti nomor KTP atau kata sandi.',
            tone: Tone.success,
          ),
          const SectionTitle('Panduan CV ATS'),
          Container(
            decoration: Clay.box(context, color: c.surfaceRaised, radius: Clay.radiusL, depth: 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ShadAccordion<int>(
              children: [
                for (var i = 0; i < _guide.length; i++)
                  ShadAccordionItem<int>(
                    value: i,
                    separator: i == _guide.length - 1 ? const SizedBox.shrink() : null,
                    title: Text(_guide[i].$1, style: context.text.titleSmall),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_guide[i].$2, style: context.text.bodyMedium!.copyWith(color: c.inkMuted)),
                    ),
                  ),
              ],
            ),
          ),
          const SectionTitle('Pembaruan'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snap) => Container(
              decoration: Clay.box(context, color: c.surfaceRaised, radius: Clay.radiusL, depth: 0.7),
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(snap.hasData ? 'Versi ${snap.data!.version}' : 'Versi', style: context.text.titleMedium),
                        const SizedBox(height: 2),
                        Text('Pembaruan diunduh langsung dari aplikasi.', style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  ClayButton(
                    label: 'Cek',
                    compact: true,
                    tone: ClayButtonTone.soft,
                    icon: HugeIcons.strokeRoundedRefresh,
                    onPressed: () => checkForUpdate(context, manual: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          ClayButton(
            label: 'Keluar',
            icon: HugeIcons.strokeRoundedLogout01,
            tone: ClayButtonTone.soft,
            expand: true,
            onPressed: () async {
              final ok = await confirmClay(
                context,
                title: 'Keluar dari akun?',
                message: 'CV-mu tetap tersimpan di server. Masuk lagi kapan saja dengan email yang sama.',
                confirmLabel: 'Keluar',
              );
              if (!ok || !context.mounted) return;
              await context.read<ResumeStore>().bind(null);
              await session.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(fadeRoute(const AuthScreen()), (_) => false);
              }
            },
          ),
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                const LogoMark(size: 30),
                const SizedBox(height: 6),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snap) => Text(
                    snap.hasData ? 'CV Ready ${snap.data!.version}' : 'CV Ready',
                    style: context.text.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, Session session) async {
    final ctrl = TextEditingController(text: session.user?.fullName);
    final ok = await showClayDialog<bool>(
      context,
      title: 'Ubah nama',
      body: ClayField(controller: ctrl, placeholder: 'Nama lengkap', capitalization: TextCapitalization.words),
      actions: (d) => [
        ClayButton(label: 'Batal', tone: ClayButtonTone.ghost, onPressed: () => Navigator.pop(d, false)),
        ClayButton(label: 'Simpan', compact: true, onPressed: () => Navigator.pop(d, true)),
      ],
    );
    if (ok != true || ctrl.text.trim().length < 2) return;
    try {
      await session.rename(ctrl.text);
      if (context.mounted) Toast.show(context, 'Nama diperbarui.', tone: Tone.success);
    } catch (e) {
      if (context.mounted) Toast.show(context, friendlyError(e), tone: Tone.error);
    }
  }
}
