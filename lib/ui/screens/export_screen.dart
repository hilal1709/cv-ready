import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/motion.dart';
import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';
import '../../data/models.dart';
import '../../services/pdf_builder.dart';
import '../../state/resume_store.dart';
import '../kit/clay_widgets.dart';
import '../kit/feedback.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key, required this.resumeId});
  final String resumeId;

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  CvTemplate? _template;

  String _fileName(Resume r) {
    final name = r.data.contact.fullName.trim().isEmpty ? r.title : r.data.contact.fullName.trim();
    return '${name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_CV.pdf';
  }

  Future<void> _share(Resume r, CvTemplate t) async {
    try {
      final bytes = await withBusy(context, 'Menyiapkan PDF…', () => PdfBuilder.build(r, template: t));
      await Printing.sharePdf(bytes: bytes, filename: _fileName(r));
      if (!mounted) return;
      await showClayDialog<void>(
        context,
        title: 'PDF siap dikirim',
        lottie: 'assets/lottie/success.json',
        message: 'Kirim sebagai PDF (bukan foto/screenshot) dan beri nama file dengan namamu. Semoga lolos!',
        actions: (ctx) => [ClayButton(label: 'Oke', compact: true, onPressed: () => Navigator.pop(ctx))],
      );
    } catch (e) {
      if (mounted) Toast.show(context, 'Gagal membuat PDF. ${friendlyError(e)}', tone: Tone.error);
    }
  }

  Future<void> _print(Resume r, CvTemplate t) async {
    try {
      await Printing.layoutPdf(
        name: _fileName(r),
        onLayout: (_) => PdfBuilder.build(r, template: t),
      );
    } catch (e) {
      if (mounted) Toast.show(context, 'Dialog simpan tidak bisa dibuka. Coba tombol Bagikan.', tone: Tone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ResumeStore>();
    final r = store.byId(widget.resumeId);
    if (r == null)
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('CV tidak ditemukan.')),
      );
    final t = _template ?? r.template;
    final c = context.clay;

    return Scaffold(
      appBar: AppBar(title: const Text('Pratinjau PDF')),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              itemCount: CvTemplate.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final tp = CvTemplate.values[i];
                final sel = tp == t;
                return Semantics(
                  selected: sel,
                  button: true,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _template = tp);
                      r.template = tp;
                      store.touch(r);
                    },
                    child: AnimatedContainer(
                      duration: Motion.of(context, Motion.fast),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: sel
                          ? Clay.box(context, color: c.primary, radius: 18, depth: 0.6)
                          : Clay.well(context, radius: 18),
                      child: Text(tp.label, style: context.text.labelLarge!.copyWith(color: sel ? c.onPrimary : c.ink)),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: PdfPreview(
              key: ValueKey(t),
              build: (_) => PdfBuilder.build(r, template: t),
              useActions: false,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              maxPageWidth: 720,
              scrollViewDecoration: BoxDecoration(color: c.ground),
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Palette.coffee.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                    spreadRadius: -6,
                  ),
                ],
              ),
              loadingWidget: const Center(child: ClayLoader()),
              onError: (context, e) => Padding(
                padding: const EdgeInsets.all(24),
                child: ClayBanner(title: 'Pratinjau gagal dibuat', message: friendlyError(e), tone: Tone.error),
              ),
            ),
          ),
          Container(
            decoration: Clay.box(
              context,
              color: c.surfaceRaised,
              radius: 0,
              depth: 0.8,
            ).copyWith(borderRadius: const BorderRadius.vertical(top: Radius.circular(Clay.radiusXL))),
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12 + MediaQuery.paddingOf(context).bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Hi(HugeIcons.strokeRoundedDocumentValidation, color: c.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Teks asli, satu kolom, tanpa tabel & gambar. Aman dibaca ATS.',
                        style: context.text.bodySmall!.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClayButton(
                        label: 'Simpan',
                        tone: ClayButtonTone.soft,
                        icon: HugeIcons.strokeRoundedDownload04,
                        onPressed: () => _print(r, t),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClayButton(
                        label: 'Bagikan',
                        icon: HugeIcons.strokeRoundedShare01,
                        onPressed: () => _share(r, t),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
