# Daftar Bug Tahap 4

Semua temuan di bawah berasal dari pengujian yang benar-benar dijalankan.
Tidak ada bug yang dikarang atau dianggap diperbaiki sebelum diverifikasi.

| ID | Tanggal | Modul | Keparahan | Status |
|----|---------|-------|-----------|--------|
| BUG-001 | 29 Okt 2026 | Navigasi placement | Tinggi | Diperbaiki (`c1725c3`) |

## BUG-001 — Hasil placement terlewat, pengguna langsung ke Beranda

- **Langkah reproduksi**
  1. Masuk sebagai siswa baru.
  2. Selesaikan seluruh 12 soal placement.
  3. Amati layar setelah soal terakhir.
- **Hasil yang diharapkan**: layar `Hasil Tes` tampil lebih dulu, lalu
  tombol `Mulai Belajar` menuju Beranda.
- **Hasil aktual**: pengguna langsung diarahkan ke Beranda; layar hasil
  tidak sempat tampil.
- **Penyebab**: `routerProvider` ikut membuat ulang `GoRouter` setiap
  `placementCompletedProvider` berubah. Setelah hasil disimpan, router
  baru kembali ke `/splash` sehingga rute hasil ditinggalkan.
- **Perbaikan**: router dibuat sekali dan memakai `refreshListenable`
  untuk mengevaluasi ulang redirect; controller mengubah fase menjadi
  `done` sebelum invalidasi provider; rute hasil diizinkan saat status
  placement sedang dimuat ulang.
- **Verifikasi**: uji integrasi
  `siswa menyelesaikan placement lalu kembali ke beranda` lulus;
  `flutter analyze` bersih dan seluruh 249 tes lulus.
- **Commit**: `c1725c3` (`fix(navigation): tampilkan hasil placement
  sebelum ke beranda`).
