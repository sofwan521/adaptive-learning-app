-- =====================================================================
-- AdaptiLearn — Row Level Security (FILE 2 dari 3, jalankan setelah schema.sql)
-- Jalankan di Supabase SQL Editor. Aman diulang (idempotent).
--
-- Model akses:
-- - Siswa: membaca/menulis data miliknya sendiri.
-- - Guru: membaca data siswa yang ada di kelasnya (+ kelola kelasnya).
-- - concepts, concept_edges, materials, items: dibaca semua pengguna login,
--   hanya ditulis admin.
-- - Admin: akses penuh semua tabel.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Aktifkan RLS pada semua tabel aplikasi
-- ---------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.class_members enable row level security;
alter table public.concepts enable row level security;
alter table public.concept_edges enable row level security;
alter table public.materials enable row level security;
alter table public.items enable row level security;
alter table public.quiz_sessions enable row level security;
alter table public.responses enable row level security;
alter table public.student_ability enable row level security;
alter table public.student_concept_state enable row level security;
alter table public.gamification enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;

-- ---------------------------------------------------------------------
-- 2. Hak dasar: peran authenticated boleh menyentuh tabel (RLS tetap
--    yang menentukan baris mana yang boleh). Anon tidak diberi apa pun.
-- ---------------------------------------------------------------------
revoke all on all tables in schema public from anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on all functions in schema public to authenticated;

-- =====================================================================
-- 3. PROFILES
-- =====================================================================
drop policy if exists "Profil: baca milik sendiri" on public.profiles;
create policy "Profil: baca milik sendiri"
  on public.profiles for select to authenticated
  using (auth.uid() = id);

drop policy if exists "Profil: guru baca murid di kelasnya" on public.profiles;
create policy "Profil: guru baca murid di kelasnya"
  on public.profiles for select to authenticated
  using (
    exists (
      select 1 from public.classes c
      join public.class_members m on m.class_id = c.id
      where c.teacher_id = auth.uid() and m.student_id = profiles.id
    )
  );

drop policy if exists "Profil: buat baris sendiri" on public.profiles;
create policy "Profil: buat baris sendiri"
  on public.profiles for insert to authenticated
  with check (auth.uid() = id);

drop policy if exists "Profil: ubah milik sendiri" on public.profiles;
create policy "Profil: ubah milik sendiri"
  on public.profiles for update to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Profil: admin kelola semua" on public.profiles;
create policy "Profil: admin kelola semua"
  on public.profiles for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 4. CLASSES
-- =====================================================================
drop policy if exists "Kelas: guru baca kelasnya" on public.classes;
create policy "Kelas: guru baca kelasnya"
  on public.classes for select to authenticated
  using (teacher_id = auth.uid());

drop policy if exists "Kelas: siswa baca kelas yang diikuti" on public.classes;
create policy "Kelas: siswa baca kelas yang diikuti"
  on public.classes for select to authenticated
  using (
    exists (
      select 1 from public.class_members
      where class_id = classes.id and student_id = auth.uid()
    )
  );

drop policy if exists "Kelas: guru buat kelas sendiri" on public.classes;
create policy "Kelas: guru buat kelas sendiri"
  on public.classes for insert to authenticated
  with check (teacher_id = auth.uid());

drop policy if exists "Kelas: guru ubah kelasnya" on public.classes;
create policy "Kelas: guru ubah kelasnya"
  on public.classes for update to authenticated
  using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

drop policy if exists "Kelas: guru hapus kelasnya" on public.classes;
create policy "Kelas: guru hapus kelasnya"
  on public.classes for delete to authenticated
  using (teacher_id = auth.uid());

drop policy if exists "Kelas: admin kelola semua" on public.classes;
create policy "Kelas: admin kelola semua"
  on public.classes for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 5. CLASS_MEMBERS
-- =====================================================================
drop policy if exists "Anggota: baca keanggotaan sendiri" on public.class_members;
create policy "Anggota: baca keanggotaan sendiri"
  on public.class_members for select to authenticated
  using (student_id = auth.uid());

drop policy if exists "Anggota: guru baca anggota kelasnya" on public.class_members;
create policy "Anggota: guru baca anggota kelasnya"
  on public.class_members for select to authenticated
  using (
    exists (
      select 1 from public.classes
      where id = class_members.class_id and teacher_id = auth.uid()
    )
  );

drop policy if exists "Anggota: gabung sendiri" on public.class_members;
create policy "Anggota: gabung sendiri"
  on public.class_members for insert to authenticated
  with check (student_id = auth.uid());

drop policy if exists "Anggota: guru tambah murid ke kelasnya" on public.class_members;
create policy "Anggota: guru tambah murid ke kelasnya"
  on public.class_members for insert to authenticated
  with check (
    exists (
      select 1 from public.classes
      where id = class_members.class_id and teacher_id = auth.uid()
    )
  );

drop policy if exists "Anggota: keluar sendiri" on public.class_members;
create policy "Anggota: keluar sendiri"
  on public.class_members for delete to authenticated
  using (student_id = auth.uid());

drop policy if exists "Anggota: guru keluarkan murid" on public.class_members;
create policy "Anggota: guru keluarkan murid"
  on public.class_members for delete to authenticated
  using (
    exists (
      select 1 from public.classes
      where id = class_members.class_id and teacher_id = auth.uid()
    )
  );

drop policy if exists "Anggota: admin kelola semua" on public.class_members;
create policy "Anggota: admin kelola semua"
  on public.class_members for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 6. KATALOG BELAJAR: concepts, concept_edges, materials, items
--    Baca: semua pengguna login. Tulis: hanya admin.
-- =====================================================================
drop policy if exists "Katalog: dibaca pengguna login" on public.concepts;
create policy "Katalog: dibaca pengguna login"
  on public.concepts for select to authenticated using (true);

drop policy if exists "Katalog: ditulis admin" on public.concepts;
create policy "Katalog: ditulis admin"
  on public.concepts for insert to authenticated
  with check (public.is_admin());

drop policy if exists "Katalog: diubah admin" on public.concepts;
create policy "Katalog: diubah admin"
  on public.concepts for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Katalog: dihapus admin" on public.concepts;
create policy "Katalog: dihapus admin"
  on public.concepts for delete to authenticated
  using (public.is_admin());

drop policy if exists "Edge: dibaca pengguna login" on public.concept_edges;
create policy "Edge: dibaca pengguna login"
  on public.concept_edges for select to authenticated using (true);

drop policy if exists "Edge: ditulis admin" on public.concept_edges;
create policy "Edge: ditulis admin"
  on public.concept_edges for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Materi: dibaca pengguna login" on public.materials;
create policy "Materi: dibaca pengguna login"
  on public.materials for select to authenticated using (true);

drop policy if exists "Materi: ditulis admin" on public.materials;
create policy "Materi: ditulis admin"
  on public.materials for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "Soal: dibaca pengguna login" on public.items;
create policy "Soal: dibaca pengguna login"
  on public.items for select to authenticated using (true);

drop policy if exists "Soal: ditulis admin" on public.items;
create policy "Soal: ditulis admin"
  on public.items for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 7. QUIZ_SESSIONS — siswa kelola sesinya; guru membaca sesi muridnya
-- =====================================================================
drop policy if exists "Sesi: siswa baca sesinya" on public.quiz_sessions;
create policy "Sesi: siswa baca sesinya"
  on public.quiz_sessions for select to authenticated
  using (student_id = auth.uid());

drop policy if exists "Sesi: siswa buat sesi" on public.quiz_sessions;
create policy "Sesi: siswa buat sesi"
  on public.quiz_sessions for insert to authenticated
  with check (student_id = auth.uid());

drop policy if exists "Sesi: siswa perbarui sesinya" on public.quiz_sessions;
create policy "Sesi: siswa perbarui sesinya"
  on public.quiz_sessions for update to authenticated
  using (student_id = auth.uid())
  with check (student_id = auth.uid());

drop policy if exists "Sesi: guru baca sesi muridnya" on public.quiz_sessions;
create policy "Sesi: guru baca sesi muridnya"
  on public.quiz_sessions for select to authenticated
  using (
    exists (
      select 1 from public.classes c
      join public.class_members m on m.class_id = c.id
      where c.teacher_id = auth.uid()
        and m.student_id = quiz_sessions.student_id
    )
  );

drop policy if exists "Sesi: admin kelola semua" on public.quiz_sessions;
create policy "Sesi: admin kelola semua"
  on public.quiz_sessions for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 8. RESPONSES — siswa kirim jawabannya; guru membaca jawaban muridnya
-- =====================================================================
drop policy if exists "Jawaban: siswa baca miliknya" on public.responses;
create policy "Jawaban: siswa baca miliknya"
  on public.responses for select to authenticated
  using (student_id = auth.uid());

drop policy if exists "Jawaban: siswa kirim jawaban" on public.responses;
create policy "Jawaban: siswa kirim jawaban"
  on public.responses for insert to authenticated
  with check (student_id = auth.uid());

drop policy if exists "Jawaban: guru baca jawaban muridnya" on public.responses;
create policy "Jawaban: guru baca jawaban muridnya"
  on public.responses for select to authenticated
  using (
    exists (
      select 1 from public.classes c
      join public.class_members m on m.class_id = c.id
      where c.teacher_id = auth.uid()
        and m.student_id = responses.student_id
    )
  );

drop policy if exists "Jawaban: admin kelola semua" on public.responses;
create policy "Jawaban: admin kelola semua"
  on public.responses for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 9. STUDENT_ABILITY — siswa baca/tulis miliknya; guru membaca
-- =====================================================================
drop policy if exists "Kemampuan: siswa baca miliknya" on public.student_ability;
create policy "Kemampuan: siswa baca miliknya"
  on public.student_ability for select to authenticated
  using (student_id = auth.uid());

drop policy if exists "Kemampuan: siswa simpan miliknya" on public.student_ability;
create policy "Kemampuan: siswa simpan miliknya"
  on public.student_ability for insert to authenticated
  with check (student_id = auth.uid());

drop policy if exists "Kemampuan: siswa perbarui miliknya" on public.student_ability;
create policy "Kemampuan: siswa perbarui miliknya"
  on public.student_ability for update to authenticated
  using (student_id = auth.uid())
  with check (student_id = auth.uid());

drop policy if exists "Kemampuan: guru baca muridnya" on public.student_ability;
create policy "Kemampuan: guru baca muridnya"
  on public.student_ability for select to authenticated
  using (
    exists (
      select 1 from public.classes c
      join public.class_members m on m.class_id = c.id
      where c.teacher_id = auth.uid()
        and m.student_id = student_ability.student_id
    )
  );

drop policy if exists "Kemampuan: admin kelola semua" on public.student_ability;
create policy "Kemampuan: admin kelola semua"
  on public.student_ability for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 10. STUDENT_CONCEPT_STATE — pola sama seperti student_ability
-- =====================================================================
drop policy if exists "State: siswa baca miliknya" on public.student_concept_state;
create policy "State: siswa baca miliknya"
  on public.student_concept_state for select to authenticated
  using (student_id = auth.uid());

drop policy if exists "State: siswa simpan miliknya" on public.student_concept_state;
create policy "State: siswa simpan miliknya"
  on public.student_concept_state for insert to authenticated
  with check (student_id = auth.uid());

drop policy if exists "State: siswa perbarui miliknya" on public.student_concept_state;
create policy "State: siswa perbarui miliknya"
  on public.student_concept_state for update to authenticated
  using (student_id = auth.uid())
  with check (student_id = auth.uid());

drop policy if exists "State: guru baca muridnya" on public.student_concept_state;
create policy "State: guru baca muridnya"
  on public.student_concept_state for select to authenticated
  using (
    exists (
      select 1 from public.classes c
      join public.class_members m on m.class_id = c.id
      where c.teacher_id = auth.uid()
        and m.student_id = student_concept_state.student_id
    )
  );

drop policy if exists "State: admin kelola semua" on public.student_concept_state;
create policy "State: admin kelola semua"
  on public.student_concept_state for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 11. GAMIFICATION — siswa baca/tulis miliknya; guru membaca
-- =====================================================================
drop policy if exists "Gamifikasi: siswa baca miliknya" on public.gamification;
create policy "Gamifikasi: siswa baca miliknya"
  on public.gamification for select to authenticated
  using (student_id = auth.uid());

drop policy if exists "Gamifikasi: siswa simpan miliknya" on public.gamification;
create policy "Gamifikasi: siswa simpan miliknya"
  on public.gamification for insert to authenticated
  with check (student_id = auth.uid());

drop policy if exists "Gamifikasi: siswa perbarui miliknya" on public.gamification;
create policy "Gamifikasi: siswa perbarui miliknya"
  on public.gamification for update to authenticated
  using (student_id = auth.uid())
  with check (student_id = auth.uid());

drop policy if exists "Gamifikasi: guru baca muridnya" on public.gamification;
create policy "Gamifikasi: guru baca muridnya"
  on public.gamification for select to authenticated
  using (
    exists (
      select 1 from public.classes c
      join public.class_members m on m.class_id = c.id
      where c.teacher_id = auth.uid()
        and m.student_id = gamification.student_id
    )
  );

drop policy if exists "Gamifikasi: admin kelola semua" on public.gamification;
create policy "Gamifikasi: admin kelola semua"
  on public.gamification for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 12. BADGES — dibaca semua pengguna login, ditulis admin
-- =====================================================================
drop policy if exists "Lencana: dibaca pengguna login" on public.badges;
create policy "Lencana: dibaca pengguna login"
  on public.badges for select to authenticated using (true);

drop policy if exists "Lencana: ditulis admin" on public.badges;
create policy "Lencana: ditulis admin"
  on public.badges for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 13. USER_BADGES — milik pengguna; guru membaca lencana muridnya
-- =====================================================================
drop policy if exists "LencanaKu: baca milik sendiri" on public.user_badges;
create policy "LencanaKu: baca milik sendiri"
  on public.user_badges for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "LencanaKu: simpan milik sendiri" on public.user_badges;
create policy "LencanaKu: simpan milik sendiri"
  on public.user_badges for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "LencanaKu: guru baca muridnya" on public.user_badges;
create policy "LencanaKu: guru baca muridnya"
  on public.user_badges for select to authenticated
  using (
    exists (
      select 1 from public.classes c
      join public.class_members m on m.class_id = c.id
      where c.teacher_id = auth.uid()
        and m.student_id = user_badges.user_id
    )
  );

drop policy if exists "LencanaKu: admin kelola semua" on public.user_badges;
create policy "LencanaKu: admin kelola semua"
  on public.user_badges for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- =====================================================================
-- 14. Fungsi gabung kelas via kode (SECURITY DEFINER agar siswa bisa
--     mendaftarkan dirinya tanpa hak tulis bebas ke tabel kelas)
-- =====================================================================
create or replace function public.join_class(p_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_class_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Harus masuk terlebih dahulu.';
  end if;

  select id into v_class_id
  from public.classes
  where join_code = upper(trim(p_code));

  if not found then
    raise exception 'Kode kelas tidak ditemukan.';
  end if;

  insert into public.class_members (class_id, student_id)
  values (v_class_id, auth.uid())
  on conflict do nothing;

  return v_class_id;
end;
$$;
