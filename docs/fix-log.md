# Log Perbaikan Tahap 4

Setiap entri mewakili satu bug dari `docs/bug-list.md` dan satu commit
perbaikan terpisah.

## BUG-001 — Hasil placement terlewat

- **Commit**: `c1725c3` — `fix(navigation): tampilkan hasil placement
  sebelum ke beranda`
- **Akar masalah**: `routerProvider` mengubah dependensi dengan `watch`,
  sehingga setiap perubahan status placement membangun ulang `GoRouter`
  dan mengembalikan posisi ke `/splash`.
- **Perubahan**
  - `lib/core/router/app_router.dart`: router dibuat sekali;
    `_RouterRefresh` memberi sinyal `refreshListenable` saat status auth
    atau placement berubah; redirect membaca state terbaru dengan
    `ref.read`; rute `/placement/result` diizinkan saat status placement
    dimuat ulang.
  - `lib/features/placement/application/placement_controller.dart`:
    fase `done` ditetapkan sebelum `placementCompletedProvider`
    diinvalidasi agar layar hasil sempat menerima perubahan.
  - `test/features/student_flow_integration_test.dart`: uji alur
    login -> placement -> hasil -> beranda dan alur kuis sampai hasil.
  - `test/features/small_screen_test.dart`: perluasan cakupan 360 dp
    untuk quiz/hasil, placement, empty/error, detail kelas, dan detail
    siswa.
  - `test/features/teacher_screens_test.dart`: uji galat daftar kelas
    dan tombol coba lagi.
- **Verifikasi**
  - `flutter analyze`: 0 masalah.
  - `flutter test`: 249 tes lulus.
- **Dampak**: navigasi tidak lagi membangun ulang router pada setiap
  perubahan status; hasil placement tampil sebelum pengguna ke Beranda.
