# AGENTS.md — Konteks Wajib AdaptiLearn

> File ini WAJIB dipatuhi pada semua langkah berikutnya. Jangan menyimpang dari
> stack, arsitektur, aturan, rumus, dan kriteria selesai di bawah tanpa instruksi
> eksplisit pengguna.

## PROYEK

AdaptiLearn, aplikasi mobile pembelajaran adaptif untuk siswa SMP/SMA
(Matematika dasar) berbasis Knowledge Graph (relasi prasyarat antar-konsep) dan
Item Response Theory 2PL untuk estimasi kemampuan siswa (theta).

## STACK

- Flutter + Dart
- Riverpod
- go_router
- supabase_flutter
- fl_chart
- flutter_local_notifications
- shared_preferences
- Tanpa code generation (tanpa freezed/json_serializable/build_runner):
  gunakan class Dart biasa.

## ARSITEKTUR

```text
lib/
├── core/                          # util, theme, router, konstanta bersama
├── domain/                        # logika murni TANPA import Flutter
│   ├── irt/                       # IRT 2PL: P(theta), informasi, EAP, SE
│   ├── graph/                     # Knowledge Graph: prasyarat, sort, path
│   └── models/                    # model Dart biasa (Concept, Question, dsb.)
├── data/                          # repository + supabase service
└── features/<fitur>/
    ├── presentation/              # widget + screen (tanpa logika bisnis)
    └── application/               # provider Riverpod / use-case per fitur
```

## ATURAN

1. Bahasa UI: Bahasa Indonesia.
2. Null-safety: aktif di semua kode baru.
3. Tidak ada logika bisnis di widget — semua logika di `domain/` atau
   `features/<fitur>/application/`.
4. Semua logika IRT dan graf harus punya unit test (`test/`).
5. Satu commit per langkah dengan format Conventional Commits
   (mis. `feat: ...`, `fix: ...`, `docs: ...`, `test: ...`, `refactor: ...`).
6. Jangan commit kunci rahasia — gunakan file `.env` yang di-gitignore atau
   `--dart-define`.

## PERAN & STATUS

- Peran: `student`, `teacher`, `admin`.
- Status konsep: `locked`, `open`, `learning`, `mastered`.

## RUMUS & KEBIJAKAN ADAPTIF (Wajib sama persis)

- Peluang jawab benar (2PL): `P(theta) = 1 / (1 + exp(-a * (theta - b)))`
- Informasi item: `informasi = a^2 * P * (1 - P)`
- Theta diestimasi dengan EAP: grid `-4..4` langkah `0.1`, prior `N(0,1)`.
- Konsep dikuasai jika: minimal 4 soal, `theta_konsep >= tau` dan `SE <= 0.6`
  (atau 8 soal tercapai).
- Gagal dini (early-stop remedial): bila 3 salah berturut-turut.

## KRITERIA SELESAI UMUM (setiap langkah)

1. `flutter analyze` bersih (tidak ada error/warning).
2. `flutter test` lulus.
3. Aplikasi bisa dijalankan (`flutter run` / `flutter build apk`).
