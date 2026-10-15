-- =====================================================================
-- AdaptiLearn — skema basis data (FILE 1 dari 3, jalankan pertama)
-- Jalankan di Supabase SQL Editor. Aman diulang (idempotent).
-- Urutan: schema.sql -> rls.sql -> seed.sql
-- =====================================================================

create extension if not exists "pgcrypto";

-- =====================================================================
-- 1. PROFILES — satu baris per pengguna auth
-- =====================================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role text not null default 'student'
    check (role in ('student', 'teacher', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- =====================================================================
-- 2. CLASSES — kelas yang diajar seorang guru
-- =====================================================================
create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  join_code text not null unique
    default upper(substr(md5(random()::text), 1, 6)),
  created_at timestamptz not null default now()
);

-- =====================================================================
-- 3. CLASS_MEMBERS — keanggotaan siswa di kelas
-- =====================================================================
create table if not exists public.class_members (
  class_id uuid not null references public.classes (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (class_id, student_id)
);

-- =====================================================================
-- 4. CONCEPTS — simpul knowledge graph
-- =====================================================================
create table if not exists public.concepts (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  description text not null default '',
  topic text not null default '',
  tau numeric not null default 0,
  order_index int not null default 0,
  created_at timestamptz not null default now()
);

-- =====================================================================
-- 5. CONCEPT_EDGES — relasi prasyarat antar-konsep
-- =====================================================================
create table if not exists public.concept_edges (
  prerequisite_id uuid not null references public.concepts (id) on delete cascade,
  concept_id uuid not null references public.concepts (id) on delete cascade,
  primary key (prerequisite_id, concept_id),
  check (prerequisite_id <> concept_id)
);

-- =====================================================================
-- 6. MATERIALS — satu materi ringkas per konsep
-- =====================================================================
create table if not exists public.materials (
  id uuid primary key default gen_random_uuid(),
  concept_id uuid not null unique references public.concepts (id) on delete cascade,
  title text not null,
  body_markdown text not null,
  created_at timestamptz not null default now()
);

-- =====================================================================
-- 7. ITEMS — bank soal pilihan ganda + parameter IRT 2PL
-- =====================================================================
create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  concept_id uuid not null references public.concepts (id) on delete cascade,
  question text not null,
  options jsonb not null default '[]'::jsonb,
  correct_index int not null check (correct_index between 0 and 3),
  explanation text not null default '',
  a numeric not null default 1 check (a > 0),
  b numeric not null default 0,
  n_responses int not null default 0 check (n_responses >= 0),
  created_at timestamptz not null default now(),
  unique (concept_id, question)
);

-- =====================================================================
-- 8. QUIZ_SESSIONS — satu sesi pengerjaan kuis
-- =====================================================================
create table if not exists public.quiz_sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  concept_id uuid references public.concepts (id) on delete set null,
  status text not null default 'berjalan'
    check (status in ('berjalan', 'selesai', 'batal')),
  final_theta numeric,
  started_at timestamptz not null default now(),
  finished_at timestamptz
);

-- =====================================================================
-- 9. RESPONSES — jawaban siswa per soal
-- =====================================================================
create table if not exists public.responses (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.quiz_sessions (id) on delete cascade,
  student_id uuid not null references public.profiles (id) on delete cascade,
  item_id uuid not null references public.items (id) on delete cascade,
  selected_index int not null check (selected_index >= 0),
  is_correct boolean not null,
  theta_after numeric,
  answered_at timestamptz not null default now()
);

-- =====================================================================
-- 10. STUDENT_ABILITY — estimasi kemampuan global siswa (theta, SE)
-- =====================================================================
create table if not exists public.student_ability (
  student_id uuid primary key references public.profiles (id) on delete cascade,
  theta numeric not null default 0,
  se numeric not null default 1 check (se > 0),
  updated_at timestamptz not null default now()
);

-- =====================================================================
-- 11. STUDENT_CONCEPT_STATE — status per konsep per siswa
-- =====================================================================
create table if not exists public.student_concept_state (
  student_id uuid not null references public.profiles (id) on delete cascade,
  concept_id uuid not null references public.concepts (id) on delete cascade,
  status text not null default 'locked'
    check (status in ('locked', 'open', 'learning', 'mastered')),
  theta_c numeric not null default 0,
  n_answered int not null default 0 check (n_answered >= 0),
  updated_at timestamptz not null default now(),
  primary key (student_id, concept_id)
);

-- =====================================================================
-- 12. GAMIFICATION — XP, level, streak siswa
-- =====================================================================
create table if not exists public.gamification (
  student_id uuid primary key references public.profiles (id) on delete cascade,
  xp int not null default 0 check (xp >= 0),
  level int not null default 1 check (level >= 1),
  streak int not null default 0 check (streak >= 0),
  last_active_date date
);

-- =====================================================================
-- 13. BADGES — daftar lencana
-- =====================================================================
create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null default '',
  created_at timestamptz not null default now()
);

-- =====================================================================
-- 14. USER_BADGES — lencana milik pengguna
-- =====================================================================
create table if not exists public.user_badges (
  user_id uuid not null references public.profiles (id) on delete cascade,
  badge_id uuid not null references public.badges (id) on delete cascade,
  awarded_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);

-- =====================================================================
-- Indeks untuk kolom kunci asing dan kolom yang sering disaring
-- =====================================================================
create index if not exists classes_teacher_idx on public.classes (teacher_id);
create index if not exists class_members_student_idx on public.class_members (student_id);
create index if not exists class_members_class_idx on public.class_members (class_id);
create index if not exists concept_edges_concept_idx on public.concept_edges (concept_id);
create index if not exists concept_edges_prereq_idx on public.concept_edges (prerequisite_id);
create index if not exists materials_concept_idx on public.materials (concept_id);
create index if not exists items_concept_idx on public.items (concept_id);
create index if not exists quiz_sessions_student_idx on public.quiz_sessions (student_id);
create index if not exists quiz_sessions_concept_idx on public.quiz_sessions (concept_id);
create index if not exists responses_session_idx on public.responses (session_id);
create index if not exists responses_student_idx on public.responses (student_id);
create index if not exists responses_item_idx on public.responses (item_id);
create index if not exists concept_state_concept_idx on public.student_concept_state (concept_id);
create index if not exists user_badges_badge_idx on public.user_badges (badge_id);

-- =====================================================================
-- Fungsi pembantu + trigger.
-- Urutan: tabel -> indeks (di atas) -> fungsi -> trigger.
-- public.is_admin() WAJIB setelah CREATE TABLE public.profiles agar tidak
-- error 42P01 "relation public.profiles does not exist" (fungsi SQL
-- divalidasi saat CREATE, jadi tabel yang dibaca harus sudah ada).
-- =====================================================================
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ---------------------------------------------------------------------
-- Trigger updated_at otomatis
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_ability_updated on public.student_ability;
create trigger trg_ability_updated
  before update on public.student_ability
  for each row execute function public.set_updated_at();

drop trigger if exists trg_concept_state_updated on public.student_concept_state;
create trigger trg_concept_state_updated
  before update on public.student_concept_state
  for each row execute function public.set_updated_at();

-- =====================================================================
-- Cegah kenaikan peran oleh non-admin (siswa tidak bisa jadi admin)
-- =====================================================================
create or replace function public.prevent_role_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.role <> old.role and not public.is_admin() then
    raise exception 'Hanya admin yang dapat mengubah peran.';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_role_guard on public.profiles;
create trigger trg_profiles_role_guard
  before update of role on public.profiles
  for each row execute function public.prevent_role_escalation();

-- =====================================================================
-- Trigger pendaftaran: user auth baru -> profiles + gamification.
-- full_name dan role diambil dari raw_user_meta_data.
-- Role dipaksa hanya 'student' atau 'teacher' (selain itu jadi student).
-- =====================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_name text;
begin
  v_role := coalesce(nullif(new.raw_user_meta_data ->> 'role', ''), 'student');
  if v_role not in ('student', 'teacher') then
    v_role := 'student';
  end if;
  v_name := nullif(new.raw_user_meta_data ->> 'full_name', '');

  insert into public.profiles (id, full_name, role)
  values (new.id, v_name, v_role)
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, public.profiles.full_name);

  insert into public.gamification (student_id)
  values (new.id)
  on conflict (student_id) do nothing;

  insert into public.student_ability (student_id)
  values (new.id)
  on conflict (student_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
