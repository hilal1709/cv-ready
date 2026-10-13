import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:ota_update/ota_update.dart';

import '../../core/theme/palette.dart';
import '../../services/updater.dart';
import '../kit/clay_widgets.dart';
import '../kit/feedback.dart';

/// Checks for a newer release and walks the user through installing it.
/// [manual] = the user tapped "Cek pembaruan": report "up to date" and errors;
/// otherwise (launch-time check) stay silent unless there is something new.
Future<void> checkForUpdate(BuildContext context, {bool manual = false}) async {
  final updater = Updater();
  UpdateInfo? info;
  try {
    info = manual ? await withBusy(context, 'Memeriksa pembaruan', updater.check) : await updater.check();
  } catch (_) {
    if (manual && context.mounted) {
      Toast.show(context, 'Tidak bisa memeriksa pembaruan. Cek koneksi internet.', tone: Tone.error);
    }
    return;
  }
  if (!context.mounted) return;
  if (info == null) {
    if (manual) Toast.show(context, 'Kamu sudah memakai versi terbaru.', tone: Tone.success);
    return;
  }
  final available = info;
  final go = await showClayDialog<bool>(
    context,
    title: 'Versi ${available.version} tersedia',
    message: available.notes.isEmpty
        ? 'Pembaruan siap dipasang${available.sizeLabel.isEmpty ? '' : ' (${available.sizeLabel})'}. CV-mu tetap aman.'
        : available.notes.length > 360
        ? '${available.notes.substring(0, 360)}…'
        : available.notes,
    actions: (ctx) => [
      ClayButton(label: 'Nanti', tone: ClayButtonTone.ghost, onPressed: () => Navigator.pop(ctx, false)),
      ClayButton(
        label: 'Perbarui',
        compact: true,
        icon: HugeIcons.strokeRoundedDownload01,
        onPressed: () => Navigator.pop(ctx, true),
      ),
    ],
  );
  if (go != true || !context.mounted) return;
  await showClayDialog<void>(
    context,
    title: 'Mengunduh pembaruan',
    body: _DownloadProgress(updater: updater, info: available),
    actions: (ctx) => [ClayButton(label: 'Tutup', tone: ClayButtonTone.ghost, onPressed: () => Navigator.pop(ctx))],
  );
}

class _DownloadProgress extends StatefulWidget {
  const _DownloadProgress({required this.updater, required this.info});
  final Updater updater;
  final UpdateInfo info;

  @override
  State<_DownloadProgress> createState() => _DownloadProgressState();
}

class _DownloadProgressState extends State<_DownloadProgress> {
  // Created once: rebuilding must not restart the download.
  late final Stream<OtaEvent> _events = widget.updater.install(widget.info);

  static String _message(OtaStatus s) => switch (s) {
    OtaStatus.PERMISSION_NOT_GRANTED_ERROR =>
      'Izinkan "Pasang aplikasi tidak dikenal" untuk CV Ready di pengaturan, lalu coba lagi.',
    OtaStatus.DOWNLOAD_ERROR => 'Unduhan gagal. Cek koneksi internet lalu coba lagi.',
    OtaStatus.CHECKSUM_ERROR => 'Berkas rusak. Coba perbarui lagi.',
    OtaStatus.ALREADY_RUNNING_ERROR => 'Pembaruan sedang berjalan.',
    OtaStatus.INSTALLATION_ERROR => 'Pemasangan gagal. Coba lagi.',
    _ => 'Terjadi masalah saat memperbarui.',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.clay;
    final error = context.text.bodyMedium!.copyWith(color: c.danger);
    return StreamBuilder<OtaEvent>(
      stream: _events,
      builder: (context, snap) {
        if (snap.hasError) return Text('Terjadi masalah saat memperbarui.', style: error);
        final e = snap.data;
        if (e == null) return const LinearProgressIndicator();
        switch (e.status) {
          case OtaStatus.DOWNLOADING:
            final pct = int.tryParse(e.value ?? '') ?? 0;
            final size = widget.info.sizeLabel;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 10,
                    color: c.primary,
                    backgroundColor: c.line,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$pct%${size.isEmpty ? '' : ' · $size'}', style: context.text.labelMedium),
              ],
            );
          case OtaStatus.INSTALLING:
          case OtaStatus.INSTALLATION_DONE:
            return Text('Unduhan selesai. Ikuti layar pemasangan Android.', style: context.text.bodyMedium);
          default:
            return Text(_message(e.status), style: error);
        }
      },
    );
  }
}
