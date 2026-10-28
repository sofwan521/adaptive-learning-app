# Log Pengembangan per Minggu

Catatan jujur sesuai riwayat git (`git log`). MVP dibangun intensif
dalam dua pekan Oktober 2026.

## Minggu ke-1 (8–10 Okt 2026)

Fondasi proyek.

- `91b27e6` Initial commit.
- `4e3756a` docs: aturan main di `AGENTS.md` (stack, arsitektur, rumus
  IRT, kriteria selesai).
- `0e9394b` chore: struktur proyek Flutter + Riverpod + go_router +
  Supabase + fl_chart + notifikasi.

## Minggu ke-2 (11–13 Okt 2026)

Implementasi fitur inti, semuanya pada 13 Okt 2026.

- `6ca332c` feat(ui): tema (tombol min. 48 dp) dan widget bersama.
- `36a924d` feat(db): skema 14 tabel + RLS + `join_class` + seed
  (8 konsep, 64 soal, 8 lencana).
- `88d6704` feat(domain): mesin IRT 2PL + unit test.
- `de2f1a3` feat(domain): knowledge graph + remedial + unit test.
- `2f46b59` feat(data): repository Supabase + antrean luring.
- `75fb0be` feat(auth): login/register + router peran.
- `b5559cb` feat(home): shell + beranda siswa.
- `327cb09` feat(placement): tes penempatan adaptif.
- `b1cb684` feat(map): peta graph interaktif.
- `3accc5d` feat(quiz): kuis adaptif + materi + remedial.
- `f4ec033` feat(progress): dasbor siswa.
- `904256f` feat(gamification): XP/streak/lencana + pengingat.
- `90cb422` feat(teacher): kelas + laporan + gabung kelas.

Perbaikan lintas langkah yang dicatat saat pengembangan:

- Dialog buat kelas dijadikan StatefulWidget mandiri (dispose controller
  saat animasi tutup merusak tree pada uji widget).
- `_load()` repository pada `initState` wajib `async` agar kegagalan
  provider menjadi state galat, bukan crash.
- `SharedPreferences.getInstance()` tanpa mock menggantung di uji
  widget → mock awal + timeout pengaman di store.
- Baris teks + tombol yang bisa overflow (login/register, `Ulangi
  <konsep>`) diubah ke Wrap/tata vertikal; grid lencana diberi tinggi
  cukup (temuan audit 360 dp).

## Tahap 4 (29 Okt 2026)

Penguatan pengujian dan kesiapan rilis.

- `98b115c` refactor(score): hapus XP/level dan tampilkan skor persen;
  theta tetap dipakai internal untuk IRT dan aturan berhenti.
- `c1725c3` fix(navigation): tampilkan hasil placement sebelum ke
  beranda; router tidak lagi dibangun ulang saat status placement
  berubah.
- Menambah uji integrasi alur siswa dan perluasan 360 dp untuk
  empty/error, hasil kuis, placement, detail kelas, dan detail siswa.
- `flutter analyze` bersih; `flutter test` 249/249 lulus; APK rilis
  terbentuk (57,3 MB) dengan peringatan font CupertinoIcons yang dicatat
  di `docs/test-report.md`.
- Dokumen baru: `docs/test-plan.md`, `docs/bug-list.md`,
  `docs/fix-log.md`, `docs/user-testing-form.md`.

## Berikutnya (di luar MVP)

- KF-15 panel admin bank soal di aplikasi.
- Penjadwalan ulang pengingat setelah reboot (BOOT_COMPLETED).
- Mode gelap dan lokalisasi zona waktu pengingat per perangkat.
