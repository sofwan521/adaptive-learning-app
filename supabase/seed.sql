-- =====================================================================
-- AdaptiLearn — data awal (FILE 3 dari 3, jalankan setelah rls.sql)
-- Jalankan di Supabase SQL Editor. Aman diulang (idempotent).
--
-- Graf Matematika dasar (8 konsep):
--   K01 Bilangan Bulat
--   K02 Operasi Aljabar            (prasyarat: K01)
--   K03 Persamaan Linear Satu Variabel (prasyarat: K02)
--   K04 Pertidaksamaan Linear      (prasyarat: K03)
--   K05 Sistem Persamaan Linear Dua Variabel (prasyarat: K03)
--   K06 Pecahan                    (prasyarat: K01)
--   K07 Perbandingan dan Skala     (prasyarat: K06)
--   K08 Fungsi Linear              (prasyarat: K05, K07)
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. Konsep (id tetap agar edge stabil)
-- ---------------------------------------------------------------------
insert into public.concepts (id, code, title, description, topic, tau, order_index) values
('a1b2c3d4-0001-4000-8000-000000000001', 'K01', 'Bilangan Bulat', 'Operasi hitung bilangan bulat: tambah, kurang, kali, bagi, dan urutan bilangan.', 'Bilangan', 0, 1),
('a1b2c3d4-0002-4000-8000-000000000002', 'K02', 'Operasi Aljabar', 'Suku sejenis, distributif, perkalian dan pembagian bentuk aljabar.', 'Aljabar', 0, 2),
('a1b2c3d4-0003-4000-8000-000000000003', 'K03', 'Persamaan Linear Satu Variabel', 'Menentukan nilai variabel yang memenuhi persamaan linear satu variabel.', 'Aljabar', 0, 3),
('a1b2c3d4-0004-4000-8000-000000000004', 'K04', 'Pertidaksamaan Linear', 'Himpunan penyelesaian pertidaksamaan linear satu variabel.', 'Aljabar', 0, 4),
('a1b2c3d4-0005-4000-8000-000000000005', 'K05', 'Sistem Persamaan Linear Dua Variabel', 'Penyelesaian SPLDV dengan eliminasi, substitusi, dan campuran.', 'Aljabar', 0, 5),
('a1b2c3d4-0006-4000-8000-000000000006', 'K06', 'Pecahan', 'Penjumlahan, pengurangan, perkalian, dan pembagian pecahan.', 'Bilangan', 0, 6),
('a1b2c3d4-0007-4000-8000-000000000007', 'K07', 'Perbandingan dan Skala', 'Perbandingan senilai dan berbalik nilai, skala peta, serta penerapan.', 'Bilangan', 0, 7),
('a1b2c3d4-0008-4000-8000-000000000008', 'K08', 'Fungsi Linear', 'Nilai fungsi, gradien, dan persamaan garis lurus.', 'Aljabar', 0, 8)
on conflict (code) do nothing;

-- ---------------------------------------------------------------------
-- 2. Relasi prasyarat (8 edge, graf asiklik)
-- ---------------------------------------------------------------------
insert into public.concept_edges (prerequisite_id, concept_id)
select p.id, c.id
from (values
  ('K01', 'K02'),
  ('K02', 'K03'),
  ('K03', 'K04'),
  ('K03', 'K05'),
  ('K01', 'K06'),
  ('K06', 'K07'),
  ('K05', 'K08'),
  ('K07', 'K08')
) as e(pre, post)
join public.concepts p on p.code = e.pre
join public.concepts c on c.code = e.post
on conflict do nothing;

-- ---------------------------------------------------------------------
-- 3. Materi ringkas (1 per konsep)
-- ---------------------------------------------------------------------
insert into public.materials (concept_id, title, body_markdown)
select id, 'Bilangan Bulat', '## Bilangan Bulat
Bilangan bulat terdiri dari bilangan negatif, nol, dan bilangan positif:
..., -3, -2, -1, 0, 1, 2, 3, ...

### Aturan tanda
- Positif tambah positif hasilnya positif.
- Kurangi bilangan negatif artinya menambah: 5 - (-2) = 7.
- Negatif dikali negatif hasilnya positif: (-3) x (-4) = 12.
- Negatif dibagi positif hasilnya negatif: -12 : 4 = -3.

### Contoh
Hitung -8 + 15.
Jawab: 15 - 8 = 7.

### Ingat
Gunakan garis bilangan untuk memeriksa jawabanmu.'
from public.concepts where code = 'K01'
on conflict (concept_id) do update set title = excluded.title, body_markdown = excluded.body_markdown;

insert into public.materials (concept_id, title, body_markdown)
select id, 'Operasi Aljabar', '## Operasi Aljabar
Bentuk aljabar tersusun dari variabel, koefisien, dan konstanta.
Contoh: pada 3x + 5, x adalah variabel, 3 adalah koefisien, 5 konstanta.

### Aturan penting
- Suku sejenis (variabel dan pangkat sama) bisa dijumlahkan: 3x + 5x = 8x.
- Sifat distributif: a(b + c) = ab + ac.
- Perkalian variabel: y x y = y^2.
- Kurung dengan minus membalik tanda: 5m - (2m + 3) = 3m - 3.

### Contoh
Sederhanakan (x + 2)(x + 3).
Jawab: x^2 + 3x + 2x + 6 = x^2 + 5x + 6.

### Ingat
Teliti tanda minus sebelum kurung.'
from public.concepts where code = 'K02'
on conflict (concept_id) do update set title = excluded.title, body_markdown = excluded.body_markdown;

insert into public.materials (concept_id, title, body_markdown)
select id, 'Persamaan Linear Satu Variabel', '## Persamaan Linear Satu Variabel
PLSV adalah kalimat terbuka dengan satu variabel berpangkat satu.
Bentuk umum: ax + b = c dengan a tidak nol.

### Cara menyelesaikan
- Pindahkan suku dengan lawan operasinya.
- Tambah atau kurangi kedua ruas dengan bilangan yang sama.
- Kali atau bagi kedua ruas dengan bilangan yang sama.

### Contoh
Selesaikan 2x - 6 = 10.
Jawab: 2x = 16, jadi x = 8.

### Ingat
Selalu periksa jawaban dengan memasukkan kembali ke persamaan.'
from public.concepts where code = 'K03'
on conflict (concept_id) do update set title = excluded.title, body_markdown = excluded.body_markdown;

insert into public.materials (concept_id, title, body_markdown)
select id, 'Pertidaksamaan Linear', '## Pertidaksamaan Linear
Pertidaksamaan memakai tanda <, >, <=, atau >=.
Penyelesaiannya berupa rentang nilai, bukan satu nilai.

### Aturan penting
- Tambah atau kurang kedua ruas bebas, tanda tetap.
- Kali atau bagi dengan bilangan negatif: tanda dibalik.
- Contoh: -2x > -4 menjadi x < 2.

### Contoh
Selesaikan 4x - 3 <= 2x + 9.
Jawab: 2x <= 12, jadi x <= 6.

### Ingat
Kata tidak lebih dari artinya <=, tidak kurang dari artinya >=.'
from public.concepts where code = 'K04'
on conflict (concept_id) do update set title = excluded.title, body_markdown = excluded.body_markdown;

insert into public.materials (concept_id, title, body_markdown)
select id, 'Sistem Persamaan Linear Dua Variabel', '## Sistem Persamaan Linear Dua Variabel
SPLDV terdiri dari dua persamaan dengan dua variabel yang sama.
Contoh: x + y = 10 dan x - y = 2.

### Metode penyelesaian
- Eliminasi: jumlahkan atau kurangkan agar satu variabel hilang.
- Substitusi: nyatakan satu variabel lalu masukkan ke persamaan lain.
- Campuran: eliminasi dulu, lalu substitusi.

### Contoh
Selesaikan x + y = 10 dan x - y = 2.
Jawab: jumlahkan kedua ruas, 2x = 12, jadi x = 6 dan y = 4.

### Ingat
Periksa pasangan jawaban ke kedua persamaan.'
from public.concepts where code = 'K05'
on conflict (concept_id) do update set title = excluded.title, body_markdown = excluded.body_markdown;

insert into public.materials (concept_id, title, body_markdown)
select id, 'Pecahan', '## Pecahan
Pecahan a/b menyatakan a bagian dari b bagian sama besar.
Pecahan campuran seperti 2 1/3 sama dengan 7/3.

### Operasi pecahan
- Tambah atau kurang: samakan penyebut dulu.
- Kali: pembilang kali pembilang, penyebut kali penyebut.
- Bagi: kalikan dengan kebalikannya, contoh 3/4 : 1/2 = 3/4 x 2/1.

### Contoh
Hitung 1/2 + 1/3.
Jawab: 3/6 + 2/6 = 5/6.

### Ingat
Sederhanakan jawaban akhir bila masih bisa.'
from public.concepts where code = 'K06'
on conflict (concept_id) do update set title = excluded.title, body_markdown = excluded.body_markdown;

insert into public.materials (concept_id, title, body_markdown)
select id, 'Perbandingan dan Skala', '## Perbandingan dan Skala
Perbandingan a : b menyatakan hubungan dua besaran sejenis.

### Jenis perbandingan
- Senilai: satu naik, yang lain naik. Contoh harga beras per kg.
- Berbalik nilai: satu naik, yang lain turun. Contoh pekerja dan waktu.
- Skala = jarak peta : jarak sebenarnya. Samakan satuannya.

### Contoh
Skala 1 : 200 dan jarak peta 5 cm.
Jawab: 5 x 200 = 1.000 cm = 10 m.

### Ingat
Ubah semua satuan ke satuan yang sama sebelum menghitung.'
from public.concepts where code = 'K07'
on conflict (concept_id) do update set title = excluded.title, body_markdown = excluded.body_markdown;

insert into public.materials (concept_id, title, body_markdown)
select id, 'Fungsi Linear', '## Fungsi Linear
Fungsi linear memasangkan tiap x ke tepat satu nilai f(x) = mx + c.
Grafiknya garis lurus dengan gradien m.

### Konsep kunci
- Nilai fungsi: ganti x lalu hitung, contoh f(3) untuk f(x) = 2x + 1.
- Gradien dari y = mx + c adalah m.
- Gradien dari dua titik: (y2 - y1) : (x2 - x1).
- Garis memotong sumbu-Y saat x = 0.

### Contoh
Persamaan garis bergradien 2 melalui (3, 7).
Jawab: y - 7 = 2(x - 3), jadi y = 2x + 1.

### Ingat
Uji titik dengan memasukkan ke persamaan garis.'
from public.concepts where code = 'K08'
on conflict (concept_id) do update set title = excluded.title, body_markdown = excluded.body_markdown;

-- ---------------------------------------------------------------------
-- 4. Bank soal: 8 soal per konsep (64 total).
--    a di antara 0.8 dan 2.0; b naik seiring sulitnya soal.
-- ---------------------------------------------------------------------

-- ===== K01 Bilangan Bulat =====
insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 15 + 28 adalah ...', '["41", "42", "43", "44"]'::jsonb, 2, '15 + 28 = 43.', 1.1, -2.0
from public.concepts where code = 'K01'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 7 x 8 adalah ...', '["54", "56", "58", "60"]'::jsonb, 1, '7 x 8 = 56.', 1.0, -1.5
from public.concepts where code = 'K01'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari -5 + 12 adalah ...', '["-7", "-5", "7", "17"]'::jsonb, 2, '-5 + 12 = 7.', 1.3, -1.0
from public.concepts where code = 'K01'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari (-6) x (-4) adalah ...', '["-24", "24", "-10", "10"]'::jsonb, 1, 'Negatif dikali negatif hasilnya positif: 6 x 4 = 24.', 1.2, -0.5
from public.concepts where code = 'K01'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari -48 : 6 adalah ...', '["8", "-8", "6", "-6"]'::jsonb, 1, 'Negatif dibagi positif hasilnya negatif: -(48 : 6) = -8.', 0.9, 0.0
from public.concepts where code = 'K01'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 12 - (-7) + (-5) adalah ...', '["14", "10", "24", "4"]'::jsonb, 0, '12 - (-7) + (-5) = 12 + 7 - 5 = 14.', 1.4, 0.7
from public.concepts where code = 'K01'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Urutan bilangan -3, 0, -7, 5 dari yang terkecil adalah ...', '["-7, -3, 0, 5", "-3, -7, 0, 5", "5, 0, -3, -7", "0, -3, -7, 5"]'::jsonb, 0, '-7 < -3 < 0 < 5.', 1.5, 1.4
from public.concepts where code = 'K01'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari [8 - (-2)] x [(-3) + 5] adalah ...', '["20", "-20", "12", "30"]'::jsonb, 0, '[8 - (-2)] x [(-3) + 5] = 10 x 2 = 20.', 1.7, 2.0
from public.concepts where code = 'K01'
on conflict (concept_id, question) do nothing;

-- ===== K02 Operasi Aljabar =====
insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 3x + 5x adalah ...', '["8x", "8x^2", "15x", "2x"]'::jsonb, 0, 'Suku sejenis dijumlahkan koefisiennya: 3 + 5 = 8.', 1.1, -2.0
from public.concepts where code = 'K02'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 7a - 2a + 4a adalah ...', '["9a", "5a", "9a^2", "13a"]'::jsonb, 0, '7 - 2 + 4 = 9, jadi hasilnya 9a.', 1.0, -1.5
from public.concepts where code = 'K02'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Bentuk sederhana dari 2(x + 3) adalah ...', '["2x + 3", "2x + 6", "x + 6", "2x + 5"]'::jsonb, 1, 'Kalikan 2 ke tiap suku: 2x + 6.', 1.3, -1.0
from public.concepts where code = 'K02'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari (4y)(3y) adalah ...', '["7y", "12y", "12y^2", "7y^2"]'::jsonb, 2, '4 x 3 = 12 dan y x y = y^2.', 1.2, -0.5
from public.concepts where code = 'K02'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Bentuk sederhana dari 5m - (2m + 3) adalah ...', '["3m - 3", "3m + 3", "7m - 3", "3m^2 - 3"]'::jsonb, 0, '5m - 2m - 3 = 3m - 3.', 1.0, 0.0
from public.concepts where code = 'K02'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari (x + 2)(x + 3) adalah ...', '["x^2 + 5x + 6", "x^2 + 6x + 5", "2x + 5", "x^2 + 5x + 5"]'::jsonb, 0, 'x^2 + 3x + 2x + 6 = x^2 + 5x + 6.', 1.4, 0.7
from public.concepts where code = 'K02'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 12x^2 : 4x adalah ...', '["3x", "3x^2", "8x", "3"]'::jsonb, 0, '12 : 4 = 3 dan x^2 : x = x.', 1.2, 1.4
from public.concepts where code = 'K02'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Bentuk sederhana dari 3(2x - 5) - 2(x + 4) adalah ...', '["4x - 23", "4x - 7", "8x - 23", "4x - 11"]'::jsonb, 0, '6x - 15 - 2x - 8 = 4x - 23.', 1.6, 2.0
from public.concepts where code = 'K02'
on conflict (concept_id, question) do nothing;

-- ===== K03 Persamaan Linear Satu Variabel =====
insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Jika x + 5 = 12, nilai x adalah ...', '["5", "6", "7", "8"]'::jsonb, 2, 'x = 12 - 5 = 7.', 1.2, -2.0
from public.concepts where code = 'K03'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Jika x - 9 = 4, nilai x adalah ...', '["5", "13", "-5", "-13"]'::jsonb, 1, 'x = 4 + 9 = 13.', 1.0, -1.5
from public.concepts where code = 'K03'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Selesaikan: 2x - 6 = 10.', '["x = 6", "x = 7", "x = 8", "x = 9"]'::jsonb, 2, '2x = 16, jadi x = 8.', 1.4, -1.0
from public.concepts where code = 'K03'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Selesaikan: 5x + 3 = 28.', '["x = 4", "x = 5", "x = 6", "x = 7"]'::jsonb, 1, '5x = 25, jadi x = 5.', 1.1, -0.5
from public.concepts where code = 'K03'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Selesaikan: 4(x - 2) = 20.', '["x = 5", "x = 6", "x = 7", "x = 3"]'::jsonb, 2, 'x - 2 = 5, jadi x = 7.', 1.3, 0.0
from public.concepts where code = 'K03'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Selesaikan: 3x - 7 = 2x + 5.', '["x = 2", "x = 12", "x = -12", "x = 6"]'::jsonb, 1, '3x - 2x = 5 + 7, jadi x = 12.', 1.5, 0.7
from public.concepts where code = 'K03'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Selesaikan: x/3 + x/4 = 7.', '["x = 6", "x = 84", "x = 12", "x = 7"]'::jsonb, 2, 'Samakan penyebut 12: 4x + 3x = 84, jadi x = 12.', 1.6, 1.4
from public.concepts where code = 'K03'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Selesaikan: 0,5x + 2,5 = 9.', '["x = 11", "x = 13", "x = 12", "x = 6,5"]'::jsonb, 1, '0,5x = 6,5, jadi x = 13.', 1.8, 2.0
from public.concepts where code = 'K03'
on conflict (concept_id, question) do nothing;

-- ===== K04 Pertidaksamaan Linear =====
insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Himpunan penyelesaian dari x + 3 > 7 adalah ...', '["x > 4", "x < 4", "x >= 4", "x = 4"]'::jsonb, 0, 'x > 7 - 3 = 4.', 1.1, -2.0
from public.concepts where code = 'K04'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Himpunan penyelesaian dari 2x <= 10 adalah ...', '["x >= 5", "x <= 5", "x < 5", "x = 5"]'::jsonb, 1, 'x <= 10 : 2 = 5.', 1.0, -1.5
from public.concepts where code = 'K04'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Himpunan penyelesaian dari x - 4 >= 1 adalah ...', '["x > 5", "x < 5", "x >= 5", "x <= 5"]'::jsonb, 2, 'x >= 1 + 4 = 5.', 1.2, -1.0
from public.concepts where code = 'K04'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Himpunan penyelesaian dari 3x + 2 < 17 adalah ...', '["x > 5", "x < 5", "x <= 5", "x >= 5"]'::jsonb, 1, '3x < 15, jadi x < 5.', 1.3, -0.5
from public.concepts where code = 'K04'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Himpunan penyelesaian dari 5 - 2x > 1 adalah ...', '["x > 2", "x < 2", "x >= 2", "x <= 2"]'::jsonb, 1, '-2x > -4, tanda berbalik saat dibagi negatif: x < 2.', 1.4, 0.0
from public.concepts where code = 'K04'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Himpunan penyelesaian dari (x + 4)/2 >= 5 adalah ...', '["x >= 6", "x <= 6", "x > 6", "x >= 2"]'::jsonb, 0, 'x + 4 >= 10, jadi x >= 6.', 1.5, 0.7
from public.concepts where code = 'K04'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Himpunan penyelesaian dari 4x - 3 <= 2x + 9 adalah ...', '["x >= 6", "x <= 6", "x < 6", "x = 6"]'::jsonb, 1, '2x <= 12, jadi x <= 6.', 1.6, 1.4
from public.concepts where code = 'K04'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Tiga kali suatu bilangan dikurangi 5 tidak lebih dari 16. Batasan bilangan itu adalah ...', '["x <= 7", "x >= 7", "x < 7", "x = 7"]'::jsonb, 0, '3x - 5 <= 16, jadi 3x <= 21 dan x <= 7.', 1.7, 2.0
from public.concepts where code = 'K04'
on conflict (concept_id, question) do nothing;

-- ===== K05 Sistem Persamaan Linear Dua Variabel =====
insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Diketahui x + y = 10 dan x - y = 2. Nilai x adalah ...', '["4", "5", "6", "8"]'::jsonb, 2, 'Jumlahkan kedua persamaan: 2x = 12, jadi x = 6.', 1.2, -2.0
from public.concepts where code = 'K05'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Diketahui 2x + y = 11 dan x + y = 7. Nilai x adalah ...', '["3", "4", "5", "7"]'::jsonb, 1, 'Kurangkan kedua persamaan: x = 4.', 1.1, -1.5
from public.concepts where code = 'K05'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Pasangan (3, 2) memenuhi sistem persamaan ...', '["x + y = 5 dan 2x - y = 4", "x + y = 6 dan x - y = 1", "2x + y = 7 dan x + y = 6", "x - y = 2 dan x + y = 4"]'::jsonb, 0, '3 + 2 = 5 dan 2(3) - 2 = 4.', 1.3, -1.0
from public.concepts where code = 'K05'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Dari 3x + 2y = 16 dan x + 2y = 8, dengan eliminasi diperoleh x = ...', '["2", "4", "6", "8"]'::jsonb, 1, 'Kurangkan kedua persamaan: 2x = 8, jadi x = 4.', 1.2, -0.5
from public.concepts where code = 'K05'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Diketahui x + 2y = 12 dan 3x - 2y = 4. Nilai y adalah ...', '["2", "3", "4", "6"]'::jsonb, 2, 'Jumlahkan: 4x = 16 maka x = 4, lalu 4 + 2y = 12 maka y = 4.', 1.4, 0.0
from public.concepts where code = 'K05'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Penyelesaian dari x - y = 1 dan 2x + 3y = 22 adalah ...', '["x = 4, y = 5", "x = 5, y = 4", "x = 6, y = 5", "x = 5, y = 5"]'::jsonb, 1, 'Substitusi x = y + 1: 2y + 2 + 3y = 22, jadi y = 4 dan x = 5.', 1.5, 0.7
from public.concepts where code = 'K05'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, '2 buku dan 1 pensil Rp12.000, sedangkan 1 buku dan 2 pensil Rp9.000. Harga 1 buku adalah ...', '["Rp4.000", "Rp5.000", "Rp6.000", "Rp7.000"]'::jsonb, 1, 'Jumlahkan: 3 buku + 3 pensil = Rp21.000. Selisih: 1 buku - 1 pensil = Rp3.000. Jadi 1 buku = Rp5.000.', 1.6, 1.4
from public.concepts where code = 'K05'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Diketahui 4x + 5y = 41 dan 3x + 2y = 22. Nilai y adalah ...', '["3", "4", "5", "6"]'::jsonb, 2, 'Tiga kali persamaan pertama kurang empat kali persamaan kedua: 7y = 35, jadi y = 5.', 1.8, 2.0
from public.concepts where code = 'K05'
on conflict (concept_id, question) do nothing;

-- ===== K06 Pecahan =====
insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 3/4 + 1/4 adalah ...', '["1/2", "3/4", "1", "7/8"]'::jsonb, 2, '4/4 = 1.', 1.1, -2.0
from public.concepts where code = 'K06'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 1/2 + 1/3 adalah ...', '["2/5", "5/6", "1/6", "2/6"]'::jsonb, 1, 'Samakan penyebut 6: 3/6 + 2/6 = 5/6.', 1.0, -1.5
from public.concepts where code = 'K06'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 5/6 - 1/3 adalah ...', '["1/2", "1/3", "2/3", "4/3"]'::jsonb, 0, '5/6 - 2/6 = 3/6 = 1/2.', 1.2, -1.0
from public.concepts where code = 'K06'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 2/3 x 9/10 adalah ...', '["3/5", "11/30", "18/10", "2/5"]'::jsonb, 0, '18/30 disederhanakan menjadi 3/5.', 1.3, -0.5
from public.concepts where code = 'K06'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 3/4 : 1/2 adalah ...', '["3/8", "3/2", "1/2", "2/3"]'::jsonb, 1, '3/4 x 2/1 = 6/4 = 3/2.', 1.2, 0.0
from public.concepts where code = 'K06'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari 2 1/3 + 1 3/4 adalah ...', '["4 1/12", "3 1/12", "4 1/7", "3 7/12"]'::jsonb, 0, '7/3 + 7/4 = 28/12 + 21/12 = 49/12 = 4 1/12.', 1.5, 0.7
from public.concepts where code = 'K06'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, '5/8 dari 96 adalah ...', '["40", "56", "60", "64"]'::jsonb, 2, '5 x 96 : 8 = 60.', 1.4, 1.4
from public.concepts where code = 'K06'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Hasil dari (2/5 + 1/10) : (3/4 - 1/2) adalah ...', '["1/2", "1", "2", "4"]'::jsonb, 2, '(1/2) : (1/4) = 2.', 1.7, 2.0
from public.concepts where code = 'K06'
on conflict (concept_id, question) do nothing;

-- ===== K07 Perbandingan dan Skala =====
insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Jika 2 : 3 = 4 : x, nilai x adalah ...', '["5", "6", "7", "8"]'::jsonb, 1, '2x = 12, jadi x = 6.', 1.1, -2.0
from public.concepts where code = 'K07'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Skala 1 : 200 dan jarak pada peta 5 cm. Jarak sebenarnya adalah ...', '["5 m", "10 m", "20 m", "100 m"]'::jsonb, 1, '5 x 200 = 1.000 cm = 10 m.', 1.0, -1.5
from public.concepts where code = 'K07'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Rp60.000 dibagi dengan perbandingan 2 : 3. Bagian terkecil adalah ...', '["Rp20.000", "Rp24.000", "Rp30.000", "Rp36.000"]'::jsonb, 1, '2/5 x Rp60.000 = Rp24.000.', 1.2, -1.0
from public.concepts where code = 'K07'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, '4 kg beras harganya Rp48.000. Harga 7 kg beras adalah ...', '["Rp72.000", "Rp80.000", "Rp84.000", "Rp96.000"]'::jsonb, 2, 'Rp48.000 : 4 x 7 = Rp84.000.', 1.3, -0.5
from public.concepts where code = 'K07'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Bus melaju 60 km/jam selama 2,5 jam. Jarak yang ditempuh adalah ...', '["120 km", "140 km", "150 km", "180 km"]'::jsonb, 2, '60 x 2,5 = 150 km.', 1.2, 0.0
from public.concepts where code = 'K07'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, '6 pekerja selesai dalam 12 hari. Dengan 9 pekerja selesai dalam ...', '["6 hari", "8 hari", "9 hari", "18 hari"]'::jsonb, 1, 'Berbanding terbalik: (6 x 12) : 9 = 8 hari.', 1.5, 0.7
from public.concepts where code = 'K07'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Skala 1 : 500.000 dan jarak sebenarnya 25 km. Jarak pada peta adalah ...', '["2,5 cm", "5 cm", "12,5 cm", "25 cm"]'::jsonb, 1, '25 km = 2.500.000 cm. 2.500.000 : 500.000 = 5 cm.', 1.6, 1.4
from public.concepts where code = 'K07'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'A : B = 2 : 3 dan B : C = 4 : 5. Jika jumlah ketiganya 350, nilai A adalah ...', '["60", "70", "80", "120"]'::jsonb, 2, 'A : B : C = 8 : 12 : 15 (35 bagian). A = 8/35 x 350 = 80.', 1.8, 2.0
from public.concepts where code = 'K07'
on conflict (concept_id, question) do nothing;

-- ===== K08 Fungsi Linear =====
insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Diketahui f(x) = 2x + 1. Nilai f(3) adalah ...', '["5", "6", "7", "9"]'::jsonb, 2, '2(3) + 1 = 7.', 1.1, -2.0
from public.concepts where code = 'K08'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Gradien garis y = 3x - 2 adalah ...', '["-2", "2", "3", "5"]'::jsonb, 2, 'Gradien adalah koefisien x, yaitu 3.', 1.0, -1.5
from public.concepts where code = 'K08'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Diketahui f(x) = 4x - 7. Nilai fungsi saat x = 0 adalah ...', '["-7", "-3", "4", "7"]'::jsonb, 0, '4(0) - 7 = -7.', 1.2, -1.0
from public.concepts where code = 'K08'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Grafik y = -x + 4 memotong sumbu-Y di titik ...', '["(4, 0)", "(0, 4)", "(-4, 0)", "(0, -4)"]'::jsonb, 1, 'Saat x = 0, y = 4.', 1.3, -0.5
from public.concepts where code = 'K08'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Diketahui f(x) = 3x - 5 dan f(a) = 10. Nilai a adalah ...', '["3", "4", "5", "15"]'::jsonb, 2, '3a = 15, jadi a = 5.', 1.4, 0.0
from public.concepts where code = 'K08'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Gradien garis melalui (1, 2) dan (4, 11) adalah ...', '["2", "3", "4", "9"]'::jsonb, 1, '(11 - 2) : (4 - 1) = 9 : 3 = 3.', 1.5, 0.7
from public.concepts where code = 'K08'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Persamaan garis bergradien 2 melalui (3, 7) adalah ...', '["y = 2x + 1", "y = 2x + 7", "y = 2x - 1", "y = x + 4"]'::jsonb, 0, 'y - 7 = 2(x - 3), jadi y = 2x + 1.', 1.6, 1.4
from public.concepts where code = 'K08'
on conflict (concept_id, question) do nothing;

insert into public.items (concept_id, question, options, correct_index, explanation, a, b)
select id, 'Grafik f(x) = 2x + k melalui (4, 3). Nilai k adalah ...', '["-5", "-3", "5", "11"]'::jsonb, 0, '2(4) + k = 3, jadi k = -5.', 1.8, 2.0
from public.concepts where code = 'K08'
on conflict (concept_id, question) do nothing;

-- ---------------------------------------------------------------------
-- 5. Lencana awal
-- ---------------------------------------------------------------------
insert into public.badges (code, name, description) values
('penjelajah-1', 'Penjelajah', 'Menuntaskan 1 konsep pertama.'),
('konsisten-3', 'Konsisten', 'Belajar 3 hari berturut-turut.'),
('teliti', 'Teliti', 'Menjawab 5 soal berturut-turut dengan benar.'),
('master-8', 'Master Matematika Dasar', 'Menguasai seluruh 8 konsep.'),
('langkah-pertama', 'Langkah Pertama', 'Menyelesaikan sesi kuis pertama.'),
('beruntun-3', '3 Hari Beruntun', 'Belajar 3 hari berturut-turut.'),
('konsep-pertama', 'Konsep Pertama Dikuasai', 'Menguasai 1 konsep pertama.'),
('pahlawan-remedial', 'Pahlawan Remedial', 'Menguasai konsep lewat jalur remedial.')
on conflict (code) do nothing;

commit;
