# AdaptiLearn

Aplikasi mobile pembelajaran adaptif untuk siswa SMP/SMA (Matematika dasar)
yang menyesuaikan tingkat kesulitan soal dengan kemampuan tiap siswa.
Dua mesin adaptif bekerja bersama: **Knowledge Graph** (relasi prasyarat
antar-konsep, status `locked`/`open`/`learning`/`mastered`) dan **Item
Response Theory 2PL** (estimasi kemampuan θ / theta). Bahasa UI: Bahasa
Indonesia.

Kelompok 2 — UIN Maulana Malik Ibrahim Malang (2026).

## Fitur

- **Autentikasi & peran**: masuk/daftar/keluar sebagai siswa atau guru;
  redirect router berbasis peran.
- **Tes penempatan adaptif**: 12 soal lintas konsep, mulai dari soal dengan
  `b` mendekati 0, lalu adaptif lewat informasi Fisher; status awal konsep
  dihitung dari θ awal.
- **Kuis adaptif per konsep**: soal dipilih via `selectNextItem`, umpan
  balik benar/salah + pembahasan tiap soal, aturan berhenti
  (min. 4 soal, SE ≤ 0,6 atau 8 soal, gagal dini 3 salah beruntun),
  lanjutkan sesi yang terputus.
- **Materi per konsep**: markdown sederhana (judul, tebal/miring, daftar,
  gambar) + tombol Mulai Kuis.
- **Peta konsep interaktif**: CustomPainter dalam InteractiveViewer
  (zoom/geser), tata letak berlapis, ketuk node untuk detail, legenda.
- **Remedial**: kartu `Akar masalah: <konsep>` + jalur berurutan dengan
  tombol `Ulangi <konsep>`; lulus remedial menawarkan kembali ke konsep awal.
- **Gamifikasi**: XP (benar +10, lulus +50, konsep baru +100),
  level `floor(sqrt(xp/100))+1`, streak harian, 4 lencana, animasi naik level.
- **Pengingat**: notifikasi harian pada jam pilihan (izin Android 13+
  ditangani) + rekomendasi konsep Terbuka sekali sehari.
- **Dasbor progres**: grafik garis θ (fl_chart), ringkasan angka, bar
  penguasaan per konsep, riwayat kuis dengan tarik-segarkan.
- **Kelas guru**: buat kelas (kode 6 karakter otomatis), daftar siswa
  (θ, dikuasai, terakhir aktif), konsep paling sering gagal, detail siswa;
  siswa bergabung via kode di Profil (RPC `join_class`).
- **Tahan luring**: respons masuk antrean lokal dan disinkronkan saat
  koneksi pulih.

## Arsitektur

```
lib/
├── app.dart                 Root MaterialApp.router
├── main.dart                Entry point (Supabase + jadwal pengingat)
├── core/                    theme, router, widgets, validators, error
├── domain/                  LOGIKA MURNI tanpa import Flutter
│   ├── irt/                 peluang 2PL, informasi Fisher, EAP, aturan sesi
│   ├── graph/               knowledge graph, status, remedial
│   ├── gamification/        aturan XP/level/streak, katalog lencana
│   ├── models/              entitas immutable (tanpa code generation)
│   └── repositories/        kontrak repository
├── data/                    implementasi Supabase + SharedPreferences
│   ├── datasources/         service, antrean, potret sesi, pengingat
│   └── repositories/        *repository_impl.dart
└── features/<fitur>/        tiap fitur: application/ + presentation/
    ├── auth/                login, register, splash, auth_controller
    ├── placement/           tes penempatan 12 soal
    ├── quiz/                kuis adaptif + hasil + remedial
    ├── concept/             halaman materi (markdown sederhana)
    ├── knowledge_map/       layout + painter + legenda + sheet
    ├── student/             shell, beranda, peta, progres, profil
    ├── progress/            agregasi dasbor (grafik, ringkasan, riwayat)
    ├── gamification/        reminder controller + notification scheduler
    └── teacher/             daftar/buat/detail kelas + detail siswa
```

Aturan main (lihat `AGENTS.md`): null-safety, tanpa code generation
(tanpa freezed/json_serializable/build_runner), tanpa logika bisnis di
widget, logika IRT/graf wajib punya unit test, commit Conventional Commits.

Rumus inti: `P(θ)=1/(1+exp(-a·(θ-b)))`, informasi `a²P(1-P)`, θ diestimasi
EAP (grid −4..4 langkah 0,1, prior N(0,1)).

## Cara menjalankan

```bash
flutter pub get

# Tanpa backend (sebagian layar tampil kosong, tetap jalan)
flutter run

# Dengan Supabase (disarankan, via --dart-define)
flutter run \
  --dart-define=SUPABASE_URL=https://contoh.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=isi-anon-key-di-sini
```

Jangan commit kunci asli: salin `.env.example` menjadi `.env` untuk
penyimpanan lokal (`.env` sudah di-gitignore).

## Cara setup Supabase

1. Buat proyek di [supabase.com](https://supabase.com), salin URL dan
   `anon key` proyek tersebut.
2. Di SQL Editor jalankan berurutan (idempoten, aman diulang):
   `supabase/schema.sql` → `supabase/rls.sql` → `supabase/seed.sql`.
   Seed mengisi 8 konsep (K01–K08), relasi prasyarat, materi, 64 soal
   (8 per konsep), dan 8 lencana.
3. RLS aktif di semua 14 tabel: guru hanya membaca murid di kelasnya,
   siswa hanya data miliknya/kelas yang diikuti; gabung kelas lewat
   fungsi `join_class(kode)` (SECURITY DEFINER).
4. Jalankan aplikasi dengan `--dart-define` di atas.

## Menjalankan tes

```bash
flutter analyze   # harus bersih
flutter test      # 229 tes: unit domain + controller + widget
```

Ringkasan hasil ada di `docs/test-report.md`, log pengembangan di
`docs/progress.md`, riwayat rilis di `CHANGELOG.md`.

## Status kebutuhan fungsional (KF-01..KF-15)

| Kode  | Kebutuhan | Status |
|-------|-----------|--------|
| KF-01 | Registrasi, masuk, keluar; peran siswa/guru | Selesai |
| KF-02 | Tes penempatan adaptif 12 soal lintas konsep | Selesai |
| KF-03 | Kuis adaptif per konsep + pembahasan tiap soal | Selesai |
| KF-04 | Estimasi kemampuan IRT 2PL (EAP) | Selesai |
| KF-05 | Knowledge graph + status konsep | Selesai |
| KF-06 | Peta konsep interaktif (zoom, geser, ketuk) | Selesai |
| KF-07 | Materi pembelajaran per konsep | Selesai |
| KF-08 | Jalur remedial + kembali ke konsep awal | Selesai |
| KF-09 | Gamifikasi (XP, level, streak, lencana) | Selesai |
| KF-10 | Pengingat harian + rekomendasi konsep Terbuka | Selesai |
| KF-11 | Dasbor progres (grafik θ, ringkasan, riwayat) | Selesai |
| KF-12 | Kelas guru: buat, daftar siswa, konsep gagal | Selesai |
| KF-13 | Gabung kelas via kode 6 karakter + validasi | Selesai |
| KF-14 | Antrean luring + lanjutkan sesi terputus | Selesai |
| KF-15 | Panel admin bank soal di aplikasi | Ditunda (dikelola via seed SQL + dashboard Supabase) |
