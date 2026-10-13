# Laporan Pengujian (T-01..T-09)

Perintah: `flutter analyze` (bersih, 0 masalah) dan `flutter test`
(**229/229 lulus**). Rincian per kelompok kasus uji:

| Kode | Kelompok | Berkas uji | Hasil |
|------|----------|------------|-------|
| T-01 | Auth & redirect peran | `auth_controller_test`, `auth_flow_test` | Lulus (masuk/daftar/keluar, validasi form, guru→kelas, siswa→placement) |
| T-02 | Tes penempatan adaptif | `placement_controller_test` | Lulus (12 soal, soal pertama b≈0, simpan respons, status peta, tanpa-ulang) |
| T-03 | Kuis adaptif + remedial | `quiz_controller_test`, `quiz_question_test` | Lulus (lulus/gagal+remedial, lanjutkan sesi, komputasi < 2 dtk; tombol Jawab nonaktif sebelum memilih) |
| T-04 | Mesin IRT 2PL | `irt_engine_test` | Lulus (P(θ), informasi Fisher, EAP, `selectNextItem`, aturan berhenti) |
| T-05 | Knowledge graph | `graph_engine_test`, `knowledge_map_layout_test`, `knowledge_map_test` | Lulus (topologi, status, remedial, layout tanpa tumpang, ketuk node) |
| T-06 | Widget inti + layar 360 dp | `login_screen_test`, `quiz_question_test`, `concept_status_chip_test`, `small_screen_test`, `design_system_test` | Lulus (validasi + galat login, kartu soal, label/ikon/kontras chip ≥ 4,5, 8 layar tanpa overflow) |
| T-07 | Gamifikasi + pengingat | `gamification_rules_test`, `reminder_test`, `recommendation_test`, `profile_screen_test` | Lulus (level ambang + bulat-balik, 6 kasus streak, jadwal/izin/batal, rekomendasi 1×/hari, layar profil) |
| T-08 | Guru + kelas | `teacher_report_test`, `teacher_screens_test` | Lulus (ranking gagal, daftar/buat/detail kelas, detail siswa, gabung via kode + validasi 6 karakter) |
| T-09 | Dasbor progres | `progress_dashboard_test`, `progress_screen_test` | Lulus (titik θ 30 terakhir + fallback sesi, ringkasan, skor riwayat, empty state, tarik-segarkan) |

Cakupan tambahan yang ikut lulus: `validators_test` (surel, sandi, nama,
kode kelas), `progress_queue_test` (antrean luring), `home_providers_test`,
`student_shell_test` (4 tab + 1 ketukan ke kuis), `widget_test` (splash),
`simple_markdown_test`, `knowledge_map_layout_test`.

Temuan selama pengujian (sudah diperbaiki, lihat `docs/progress.md`):

1. Overflow kanan 39 px pada baris "Belum punya akun?/Daftar" (login) —
   diganti `Wrap`; pola sama di register.
2. Tombol `Ulangi <konsep>` overflow untuk nama panjang — disusun
   vertikal (nama di atas, tombol penuh di bawah).
3. Grid lencana profil overflow 16 px — tinggi sel 132 → 152 dp.
4. Dialog buat kelas dispose controller terlalu dini — dijadikan
   StatefulWidget mandiri.

## Build rilis

- Perintah: `flutter build apk --release` (13 Okt 2026).
- Hasil: `build/app/outputs/flutter-apk/app-release.apk`, **57,4 MB**.
- Catatan: ikon font di-tree-shake (CupertinoIcons −99,7%,
  MaterialIcons −99,5%).
