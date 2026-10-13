# CV Ready

Aplikasi Android (Flutter) untuk membuat CV ATS-friendly dengan template internasional: skor ATS, pencocokan kata kunci lowongan, bantuan AI untuk menulis/memperbaiki kalimat, dan ekspor PDF teks asli satu kolom.

## Menjalankan

1. Salin `.env.example.json` menjadi `.env.json` lalu isi kredensial (file ini di-gitignore):
   - `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`: database Neon PostgreSQL.
   - Fitur AI (opsional, isi salah satu): `GEMINI_API_KEY` (punya free tier, buat di https://aistudio.google.com/apikey) atau `ANTHROPIC_API_KEY` (Claude, berbayar). Jika keduanya diisi, Claude yang dipakai. `GEMINI_MODEL` default `gemini-flash-latest`.
2. Buat tabel (sekali saja): `dart run tool/migrate.dart`
3. Jalankan: `flutter run --dart-define-from-file=.env.json`
4. APK: `flutter build apk --release --dart-define-from-file=.env.json` → `build/app/outputs/flutter-apk/app-release.apk`

## Keamanan

Kredensial disuntik saat build, jadi **ikut tertanam di APK**. Siapa pun yang membongkar APK bisa membaca password database (akses owner) dan API key. Aman untuk pemakaian pribadi; **jangan sebarkan APK-nya**. Untuk dibagikan, pindahkan akses database & AI ke backend kecil.

## Struktur

- `lib/core` — tema clay, palet 5 warna, kurva animasi (padanan GSAP), konfigurasi env
- `lib/data` — model CV, koneksi Neon, repositori akun & CV (password: PBKDF2-SHA256)
- `lib/services` — skor ATS, pencocok kata kunci, AI (Claude Messages API), pembuat PDF
- `lib/state` — sesi login, daftar CV + autosave
- `lib/ui` — komponen clay (tombol, field shadcn, toast, banner, modal, loader Lottie, Readiness Stamp) dan layar
- `assets/lottie` — animasi (dibuat oleh `tool/gen_lottie.py`), `assets/illustrations` — ilustrasi clay SVG
- `design/logo` — konsep logo; `test/core_test.dart` — test skor, matcher, dan render PDF

## Catatan stack

- **shadcn_ui** (port Flutter) untuk input, accordion; **Hugeicons** untuk ikon; **Lottie** untuk animasi ilustrasi & loading.
- **GSAP** hanya ada di web, jadi perannya diisi `flutter_animate` + kurva bernama GSAP di `lib/core/motion.dart`.
- **graphify** terpasang untuk Claude Code (`CLAUDE.md`, `.claude/settings.json`); perbarui graph dengan `graphify update .`.
