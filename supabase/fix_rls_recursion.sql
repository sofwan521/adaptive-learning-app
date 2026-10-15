-- =====================================================================
-- AdaptiLearn — perbaikan infinite recursion 42P17 pada RLS
-- Penyebab: policy profiles/classes/class_members saling query tabel
-- lain yang juga ber-RLS (profiles -> classes -> class_members ->
-- classes ...). Postgres membatalkan dengan:
--   infinite recursion detected in policy for relation "classes"
-- Perbaikan: cek keanggotaan lewat fungsi SECURITY DEFINER (bypass RLS)
-- lalu policy memanggil fungsi tersebut, bukan subquery langsung.
-- Cara pakai: jalankan file ini sekali di Supabase SQL Editor.
-- Aman diulang (idempotent).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Fungsi pembantu (SECURITY DEFINER = bypass RLS, cegah rekursi)
-- ---------------------------------------------------------------------
create or replace function public.is_class_teacher(p_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.classes
    where id = p_class_id and teacher_id = auth.uid()
  );
$$;

create or replace function public.is_class_member(p_class_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.class_members
    where class_id = p_class_id and student_id = auth.uid()
  );
$$;

create or replace function public.is_teacher_of(p_student_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.classes c
    join public.class_members m on m.class_id = c.id
    where c.teacher_id = auth.uid()
      and m.student_id = p_student_id
  );
$$;

grant execute on function public.is_class_teacher(uuid) to authenticated;
grant execute on function public.is_class_member(uuid) to authenticated;
grant execute on function public.is_teacher_of(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- 2. PROFILES — guru baca murid di kelasnya
-- ---------------------------------------------------------------------
drop policy if exists "Profil: guru baca murid di kelasnya" on public.profiles;
create policy "Profil: guru baca murid di kelasnya"
  on public.profiles for select to authenticated
  using (public.is_teacher_of(profiles.id));

-- ---------------------------------------------------------------------
-- 3. CLASSES — siswa baca kelas yang diikuti
-- ---------------------------------------------------------------------
drop policy if exists "Kelas: siswa baca kelas yang diikuti" on public.classes;
create policy "Kelas: siswa baca kelas yang diikuti"
  on public.classes for select to authenticated
  using (public.is_class_member(classes.id));

-- ---------------------------------------------------------------------
-- 4. CLASS_MEMBERS — 3 policy guru yang query tabel classes
-- ---------------------------------------------------------------------
drop policy if exists "Anggota: guru baca anggota kelasnya" on public.class_members;
create policy "Anggota: guru baca anggota kelasnya"
  on public.class_members for select to authenticated
  using (public.is_class_teacher(class_members.class_id));

drop policy if exists "Anggota: guru tambah murid ke kelasnya" on public.class_members;
create policy "Anggota: guru tambah murid ke kelasnya"
  on public.class_members for insert to authenticated
  with check (public.is_class_teacher(class_members.class_id));

drop policy if exists "Anggota: guru keluarkan murid" on public.class_members;
create policy "Anggota: guru keluarkan murid"
  on public.class_members for delete to authenticated
  using (public.is_class_teacher(class_members.class_id));

-- ---------------------------------------------------------------------
-- 5. QUIZ_SESSIONS / RESPONSES / ABILITY / STATE / GAMIFIKASI / BADGES
--    Semua policy "guru baca muridnya" yang join classes+members
--    diganti memanggil is_teacher_of() agar tidak rekursi.
-- ---------------------------------------------------------------------
drop policy if exists "Sesi: guru baca sesi muridnya" on public.quiz_sessions;
create policy "Sesi: guru baca sesi muridnya"
  on public.quiz_sessions for select to authenticated
  using (public.is_teacher_of(quiz_sessions.student_id));

drop policy if exists "Jawaban: guru baca jawaban muridnya" on public.responses;
create policy "Jawaban: guru baca jawaban muridnya"
  on public.responses for select to authenticated
  using (public.is_teacher_of(responses.student_id));

drop policy if exists "Kemampuan: guru baca muridnya" on public.student_ability;
create policy "Kemampuan: guru baca muridnya"
  on public.student_ability for select to authenticated
  using (public.is_teacher_of(student_ability.student_id));

drop policy if exists "State: guru baca muridnya" on public.student_concept_state;
create policy "State: guru baca muridnya"
  on public.student_concept_state for select to authenticated
  using (public.is_teacher_of(student_concept_state.student_id));

drop policy if exists "Gamifikasi: guru baca muridnya" on public.gamification;
create policy "Gamifikasi: guru baca muridnya"
  on public.gamification for select to authenticated
  using (public.is_teacher_of(gamification.student_id));

drop policy if exists "LencanaKu: guru baca muridnya" on public.user_badges;
create policy "LencanaKu: guru baca muridnya"
  on public.user_badges for select to authenticated
  using (public.is_teacher_of(user_badges.user_id));
