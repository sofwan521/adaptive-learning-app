# Laporan Pengujian Tahap 4

Perintah terakhir: `flutter analyze` (**0 masalah**) dan `flutter test`
(**249/249 lulus**) pada 29 Okt 2026.

| Kode | Kelompok | Berkas uji | Hasil |
|------|----------|------------|-------|
| T-01 | Auth & redirect peran | `auth_controller_test`, `auth_flow_test` | Lulus (masuk/daftar/keluar, validasi form, guru→kelas, siswa→placement) |
| T-02 | Tes penempatan adaptif | `placement_controller_test` | Lulus (12 soal, soal pertama b≈0, simpan respons, status peta, tanpa-ulang) |
| T-03 | Kuis adaptif + remedial | `quiz_controller_test`, `quiz_question_test` | Lulus (lulus/gagal+remedial, lanjutkan sesi, komputasi < 2 dtk; tombol Jawab nonaktif sebelum memilih) |
| T-04 | Mesin IRT 2PL | `irt_engine_test` | Lulus (P(θ), informasi Fisher, EAP, `selectNextItem`, aturan berhenti) |
| T-05 | Knowledge graph | `graph_engine_test`, `knowledge_map_layout_test`, `knowledge_map_test` | Lulus (topologi, status, remedial, layout tanpa tumpang, ketuk node) |
| T-06 | Widget inti + layar 360 dp | `login_screen_test`, `quiz_question_test`, `concept_status_chip_test`, `small_screen_test`, `design_system_test` | Lulus; 21 skenario 360 dp mencakup quiz/hasil, placement, empty/error, detail kelas/siswa |
| T-07 | Gamifikasi + pengingat | `gamification_rules_test`, `reminder_test`, `recommendation_test`, `profile_screen_test` | Lulus (6 kasus streak, jadwal/izin/batal, rekomendasi 1×/hari, profil tanpa XP/level) |
| T-08 | Guru + kelas | `teacher_report_test`, `teacher_screens_test` | Lulus (ranking gagal, daftar/buat/detail kelas, detail siswa, gabung via kode, galat + coba lagi) |
| T-09 | Dasbor progres | `progress_dashboard_test`, `progress_screen_test` | Lulus (skor persen, ringkasan, bar konsep, riwayat, empty state, tarik-segarkan) |
| T-10 | Integrasi alur utama | `student_flow_integration_test` | Lulus (login→placement→hasil→beranda; login→kuis→hasil) |
| T-11 | Integrasi galat | `student_flow_integration_test`, `teacher_screens_test`, `small_screen_test` | Lulus (placement gagal lalu coba lagi; kelas/progres/gamifikasi galat) |

Cakupan tambahan yang ikut lulus: `validators_test` (surel, sandi, nama,
kode kelas), `progress_queue_test` (antrean luring), `home_providers_test`,
`student_shell_test` (4 tab + 1 ketukan ke kuis), `widget_test` (splash),
`simple_markdown_test`, dan `score_scale_test`.

## Temuan dan perbaikan

1. **BUG-001** — Hasil placement terlewat karena router dibangun ulang
   setelah status placement berubah; pengguna langsung ke Beranda.
   Diperbaiki pada `c1725c3`, diuji lewat `student_flow_integration_test`.
   Rincian ada di `docs/bug-list.md` dan `docs/fix-log.md`.
2. Overflow lama yang sudah diperbaiki sebelumnya: baris
   "Belum punya akun?/Daftar" (login/register), tombol `Ulangi <konsep>`
   untuk nama panjang, grid lencana profil, dan dispose dialog buat kelas.

Tidak ada overflow baru yang terdeteksi pada 21 skenario 360 x 740 dp.

## Build rilis

- Perintah: `flutter build apk --release` (29 Okt 2026).
- Hasil: **berhasil**, `build/app/outputs/flutter-apk/app-release.apk`,
  ukuran **57,3 MB** (60.126.234 byte).
- Peringatan build: font `CupertinoIcons` tidak ditemukan saat
  tree-shake ikon; `MaterialIcons` berhasil di-tree-shake
  (1.645.184 → 8.764 byte, −99,5%). Build tetap selesai dan APK terbentuk.

## Catatan jujur

- User testing dan SUS **belum dilaksanakan**; formulir tersedia di
  `docs/user-testing-form.md` dan belum diisi.
- Pengujian perangkat fisik dan notifikasi nyata di luar cakupan
  otomatisasi ini.
