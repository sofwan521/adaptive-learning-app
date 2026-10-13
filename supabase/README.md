# Backend Supabase AdaptiLearn

Folder ini berisi SQL yang dijalankan di **Supabase SQL Editor**.
File dijalankan berurutan: `schema.sql` → `rls.sql` → `seed.sql`.

## 1. Buat proyek Supabase

1. Buka <https://supabase.com> dan buat proyek baru.
2. Catat **Project URL** dan **anon public key** dari
   *Project Settings → Data API* (dulu *API*).
3. Biarkan *Confirm email* aktif untuk keamanan, atau matikan sementara
   di *Authentication → Sign In / Sign Up* saat pengembangan.

## 2. Jalankan SQL berurutan

Di dashboard proyek, buka **SQL Editor → New query**, lalu untuk tiap file:

| Urutan | File | Isi |
| ------ | ---- | --- |
| 1 | `schema.sql` | 14 tabel, indeks, trigger pendaftaran (`profiles` + `gamification` + `student_ability` otomatis) |
| 2 | `rls.sql` | RLS semua tabel, kebijakan siswa/guru/admin, fungsi `join_class(kode)` |
| 3 | `seed.sql` | 8 konsep Matematika dasar, 8 edge prasyarat, 8 materi, 64 soal, 4 lencana |

Tempel isi file → **Run**. Tiap file aman diulang (idempotent).
Harus muncul *Success. No rows returned* tanpa galat.

## 3. Verifikasi cepat

```sql
-- Jumlah data: 8 konsep, 8 edge, 8 materi, 64 soal
select (select count(*) from concepts) as konsep,
       (select count(*) from concept_edges) as edge,
       (select count(*) from materials) as materi,
       (select count(*) from items) as soal;

-- Soal per konsep: harus 8 semua
select c.code, count(i.id) as soal
from concepts c left join items i on i.concept_id = c.id
group by c.code order by c.code;

-- Deteksi siklus graf: harus 0 baris
with recursive reach(start_id, node_id) as (
  select prerequisite_id, concept_id from concept_edges
  union
  select r.start_id, e.concept_id
  from reach r join concept_edges e on e.prerequisite_id = r.node_id
)
select * from reach where start_id = node_id;
```

## 4. Isi kredensial ke aplikasi

Jangan commit kunci asli. Pilih salah satu cara:

```bash
# Cara A — disarankan: --dart-define
flutter run \
  --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=isi-anon-key-di-sini

# Cara B — file .env lokal (sudah di-gitignore)
cp .env.example .env   # lalu isi nilainya
```

Lihat `.env.example` di root untuk formatnya.

## 5. Buat akun admin pertama

Daftar lewat aplikasi sebagai *teacher*, lalu di SQL Editor:

```sql
update profiles set role = 'admin' where id = (
  select id from profiles order by created_at limit 1
);
```

Hanya admin yang boleh menulis katalog
(`concepts`, `concept_edges`, `materials`, `items`, `badges`).

## 6. Alur peran

- **Siswa**: daftar (pilih *Siswa*) → profil + gamifikasi dibuat otomatis
  oleh trigger → gabung kelas via kode (`join_class`) → kerjakan kuis.
- **Guru**: daftar (pilih *Guru*) → buat kelas di aplikasi → bagikan
  `join_code` → pantau kemampuan dan status konsep muridnya.
