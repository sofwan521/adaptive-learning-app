# Rencana Pengujian Tahap 4

## Tujuan dan lingkup

Memastikan AdaptiLearn memenuhi kebutuhan KF-01..KF-14, stabil pada alur
utama dan kondisi galat, aman dipakai pada layar 360 dp, serta siap diuji
ke pengguna dan dibangun menjadi APK rilis. KF-15 (panel admin di aplikasi)
tetap ditunda dan dikelola lewat Supabase.

Di luar lingkup otomatisasi: pengujian perangkat fisik, kualitas suara
notifikasi, dan penilaian kegunaan oleh pengguna (dilakukan manual dengan
`docs/user-testing-form.md`).

## Lingkungan dan perintah

- Flutter/Dart sesuai `pubspec.yaml`; target utama Android.
- `flutter analyze` harus **0 masalah**.
- `flutter test` harus lulus seluruhnya.
- Pemeriksaan visual otomatis memakai ukuran 360 x 740 dp.
- Data uji memakai fake repository; tidak memakai data produksi.

## Strategi

| Lapis | Fokus | Bukti |
|-------|-------|-------|
| Unit | IRT 2PL, EAP, aturan sesi, knowledge graph, konversi skor, validasi, agregasi progres | `test/domain/**`, `test/core/**`, `test/features/*_test.dart` |
| Widget | Validasi form, empty/error/loading, tombol, navigasi tab, tampilan 360 dp | `test/features/**` |
| Integrasi | Login siswa -> placement -> hasil -> beranda; kuis sampai hasil; galat dapat dicoba lagi | `test/features/student_flow_integration_test.dart` |
| Manual | User testing tugas + SUS, build APK, cek perangkat nyata | `docs/user-testing-form.md` |

## Kasus uji

Kode `TP-xx` dipakai sebagai acuan lintas dokumen. Status pelaksanaan dan
hasil nyata dicatat di `docs/test-report.md`.

| Kode | Kategori | Skenario | Hasil yang diharapkan |
|------|----------|----------|------------------------|
| TP-01 | Fungsi/auth | Masuk sebagai siswa/guru, daftar, keluar | Diarahkan sesuai peran; sesi tersimpan/terhapus benar |
| TP-02 | Validasi | Surel, sandi, nama, konfirmasi, kode kelas kosong/tidak valid | Pesan Bahasa Indonesia tampil; tidak ada request backend |
| TP-03 | Galat/auth | Kredensial salah, backend gagal | SnackBar/ErrorView ramah; aplikasi tidak crash |
| TP-04 | Fungsi/placement | 12 soal, soal pertama b≈0, pemilihan adaptif | Progres dan soal sesuai; jawaban tersimpan |
| TP-05 | Data/placement | Selesai 12 soal | Theta/SE, status awal konsep, sesi tersimpan; hasil tampil sebelum beranda |
| TP-06 | Galat/placement | Bank soal gagal dimuat, lalu coba lagi | Pesan galat tampil; tombol mulai dapat mengulang |
| TP-07 | Fungsi/kuis | Mulai dari Beranda, jawab, umpan balik + pembahasan | Soal berjalan adaptif; jawaban benar/salah terlihat |
| TP-08 | Aturan/kuis | 3 salah berturut-turut; SE ≤ 0,6; maksimal 8 soal | Berhenti sesuai aturan; hasil/remedial tepat |
| TP-09 | Data/kuis | Keluar di tengah sesi lalu buka lagi | Tawaran lanjutkan/ulangi bekerja; data tidak hilang |
| TP-10 | Fungsi/materi & peta | Buka materi, peta, ketuk node terbuka/terkunci | Materi tampil; status dan prasyarat dijelaskan |
| TP-11 | Fungsi/remedial | Gagal kuis, jalankan jalur remedial | Jalur berurutan; kembali ke konsep awal setelah lulus |
| TP-12 | Fungsi/progres | Buka dasbor dengan data | Ringkasan, grafik skor %, bar konsep, riwayat tampil |
| TP-13 | Empty/progres | Siswa baru tanpa data | Empty state jelas dan tidak overflow |
| TP-14 | Galat/progres & profil | Gagal memuat progres/gamifikasi | ErrorView + coba lagi; teks tidak terpotong |
| TP-15 | Fungsi/gamifikasi | Aktivitas harian, buka profil | Streak dan lencana sesuai; tanpa XP/level |
| TP-16 | Fungsi/pengingat | Aktifkan pengingat, izin ditolak/diterima | Jadwal disimpan; pesan izin jelas |
| TP-17 | Fungsi/guru | Buat kelas, lihat daftar/detail, gabung via kode | Kelas dan kode 6 karakter benar; daftar siswa tampil |
| TP-18 | Galat/guru | Daftar/detail kelas gagal dimuat | Pesan galat + coba lagi; data lama tidak menyesatkan |
| TP-19 | Empty/guru | Guru belum punya kelas; kelas tanpa siswa | Ajakan membuat kelas / membagikan kode |
| TP-20 | Navigasi | Tab Beranda, Peta, Progres, Profil | Perpindahan tab stabil; satu ketukan ke kuis |
| TP-21 | Tampilan | Semua layar utama pada 360 x 740 dp | Tidak ada overflow; teks panjang membungkus |
| TP-22 | Tampilan | Skala teks 1,3 pada profil | Konten tetap terbaca dan tidak overflow |
| TP-23 | Integrasi | Login siswa -> placement -> hasil -> beranda | Alur utama selesai tanpa jalan buntu |
| TP-24 | Integrasi | Login -> kuis -> hasil | Skor kemampuan persen tampil |
| TP-25 | Nonfungsi | Waktu komputasi pemilihan soal + theta | Di bawah 2 detik pada data uji |
| TP-26 | Rilis | `flutter build apk --release` | APK terbentuk; ukuran/peringatan dicatat apa adanya |

## Ketertelusuran kebutuhan

| Kebutuhan | Kasus uji utama |
|-----------|-----------------|
| KF-01 | TP-01..TP-03 |
| KF-02 | TP-04..TP-06, TP-23 |
| KF-03..KF-05 | TP-07..TP-09, TP-24 |
| KF-06..KF-08 | TP-10..TP-11 |
| KF-09..KF-10 | TP-15..TP-16 |
| KF-11 | TP-12..TP-14 |
| KF-12..KF-13 | TP-17..TP-19 |
| KF-14 | TP-09, TP-25 |
| KF-15 | Ditunda; tidak diuji di aplikasi |

## Kriteria lulus

1. `flutter analyze` bersih dan `flutter test` lulus 100%.
2. Tidak ada overflow pada seluruh kasus 360 dp.
3. Alur utama dan jalur galat dapat diselesaikan tanpa crash.
4. Setiap bug yang ditemukan tercatat di `docs/bug-list.md` dan
   perbaikannya dicatat di `docs/fix-log.md`.
5. Build APK rilis berhasil, atau kegagalannya dilaporkan apa adanya.
6. Hasil user testing tidak boleh diklaim sebelum sesi benar-benar dilakukan.
