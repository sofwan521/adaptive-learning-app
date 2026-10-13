# AdaptiLearn

Aplikasi mobile pembelajaran adaptif (SMP/SMA, Matematika dasar) berbasis
Knowledge Graph dan IRT 2PL. Bahasa UI: Bahasa Indonesia.

Lihat `AGENTS.md` untuk konteks wajib (stack, arsitektur, rumus, kriteria selesai).

## Stack

Flutter + Dart, Riverpod, go_router, supabase_flutter, fl_chart,
flutter_local_notifications, shared_preferences. Tanpa code generation.

## Struktur

```text
lib/
├── app.dart
├── main.dart
├── core/ (constants, theme, router, utils)
├── domain/ (irt, graph, models — murni Dart, tanpa Flutter)
├── data/ (datasources, repositories)
└── features/home/ (presentation, application)
```

Kode lama (`lib/core/models`, `lib/core/services`, dst.) dipertahankan
sementara untuk migrasi bertahap.

## Cara menjalankan

```bash
flutter pub get

# Tanpa backend (layar kosong tetap tampil)
flutter run

# Dengan Supabase (disarankan via --dart-define)
flutter run \
  --dart-define=SUPABASE_URL=https://contoh.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=isi-anon-key-di-sini
```

Salin `.env.example` menjadi `.env` bila perlu simpan kunci lokal
(file `.env` sudah di-gitignore — jangan commit kunci asli).

## Cek kualitas

```bash
flutter analyze
flutter test
```

## Tim

Kelompok 2 — UIN Maulana Malik Ibrahim Malang (2026).
