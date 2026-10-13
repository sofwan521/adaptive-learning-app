# Changelog

Semua perubahan penting proyek dicatat di sini, terbaru di atas.
Format mengikuti [Conventional Commits](https://www.conventionalcommits.org/).

## [Unreleased]

## 1.0.0-mvp — 2026-10-13

### Ditambahkan

- `feat(ui)`: tema dan widget bersama (tombol min. 48 dp, kartu, chip
  status, lencana XP/level, status loading/error/kosong).
- `feat(db)`: skema Supabase (14 tabel), RLS semua tabel, fungsi
  `join_class`, seed 8 konsep + 64 soal + 8 lencana.
- `feat(domain)`: mesin IRT 2PL (peluang, informasi Fisher, EAP grid
  −4..4, aturan berhenti) beserta unit test.
- `feat(domain)`: knowledge graph (topologi, status, rencana remedial,
  newly-unlocked) beserta unit test.
- `feat(data)`: repository Supabase + antrean luring (respons, potret
  sesi, pengingat).
- `feat(auth)`: layar masuk/daftar, validator, router berbasis peran.
- `feat(home)`: shell + beranda siswa (sapaan, XP/streak/level, lanjutan,
  target harian, lencana).
- `feat(placement)`: tes penempatan adaptif 12 soal (pengantar, tes,
  hasil Pemula/Menengah/Mahir).
- `feat(map)`: peta knowledge graph interaktif (lapisan, panah, ketuk,
  legenda).
- `feat(quiz)`: kuis adaptif + materi markdown + hasil + remedial +
  lanjutkan sesi (pemilihan soal & update θ < 2 detik).
- `feat(progress)`: dasbor siswa (grafik θ fl_chart, ringkasan, bar per
  konsep, riwayat + tarik-segarkan).
- `feat(gamification)`: XP/level/streak/lencana, animasi naik level,
  pengingat harian + rekomendasi (izin Android 13+).
- `feat(teacher)`: kelola kelas, laporan siswa, konsep gagal, gabung
  kelas via kode.
- `docs`: finalisasi MVP — README, CHANGELOG, docs/progress.md,
  docs/test-report.md; uji widget Login, kartu soal, ConceptStatusChip;
  audit UX 360 dp (perbaikan overflow), audit keamanan.
