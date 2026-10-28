# PROJECT_CONTEXT.md — AdaptiLearn (adaptive_learning_app)

> Dibuat dari pembacaan langsung kode pada 2026-10-16. Jika sesuatu tidak ada di kode, ditulis "tidak ada". Jalur ditulis relatif dari repo root.

Proyek: aplikasi mobile pembelajaran adaptif Matematika SMP/SMA berbasis Knowledge Graph + IRT 2PL. Bahasa UI: Bahasa Indonesia. Aturan arsitektur ada di `AGENTS.md`.

---

## 1. Struktur folder `lib/` (tree) dan fungsi tiap folder/file utama

Total ±114 file `.dart` di `lib/`. Router aktif: `lib/core/router/app_router.dart`. Router lama (tidak aktif/legacy): `lib/core/routes/app_router.dart` — tidak diimpor oleh `lib/app.dart`.

```
lib/
├── main.dart                                   # Entry point; init Supabase (dart-define) + restore reminder; runApp ProviderScope(AdaptiLearnApp)
├── app.dart                                    # Root MaterialApp.router; pakai routerProvider (core/router) + AppTheme
├── core/
│   ├── constants/app_constants.dart            # Nama app, key dart-define SUPABASE_URL / SUPABASE_ANON_KEY
│   ├── error/app_exception.dart                # Tipe exception aplikasi
│   ├── models/                                 # Model lama (core): concept.dart, question.dart, quiz_response.dart, user.dart (dipakai jalur legacy)
│   ├── router/app_router.dart                  # ★ ROUTER AKTIF: AppRoutes + routerProvider + redirect berbasis peran/placement
│   ├── routes/app_router.dart                  # ROUTER LEGACY (tidak aktif): class AppRouter, rute /login /concept-map /quiz/:id dsb.
│   ├── services/
│   │   ├── auth_service.dart                   # Service auth lama (pakai crypto); dipakai provider legacy
│   │   ├── irt_service.dart                    # Service IRT lama (MLE Newton-Raphson, 3PL); dipakai learning_provider legacy saja
│   │   └── knowledge_graph_service.dart        # Service graf lama (tipe core/models); dipakai learning_provider legacy saja
│   ├── theme/app_theme.dart                    # Tema Material + google_fonts
│   ├── utils/supabase_config.dart              # Baca SUPABASE_URL / SUPABASE_ANON_KEY dari --dart-define; isConfigured
│   ├── validators.dart                         # ★ Validasi murni aktif (email, password, nama, konfirmasi, kode kelas)
│   └── widgets/                                # Design system: app_button, app_card, app_text_field, app_text_field,
│       │                                       # concept_status_chip, xp_badge, level_badge, loading_view, error_view,
│       │                                       # empty_view, backend_warning, widgets.dart (barrel)
├── domain/                                     # Logika murni, tanpa import Flutter
│   ├── irt/
│   │   ├── irt_math.dart                       # Fungsi murni probability2pl, information2pl, standardNormalPdf
│   │   └── irt_engine.dart                     # ★ Mesin aktif: probability, information, estimateEap, selectNextItem, evaluateSession
│   ├── graph/
│   │   ├── knowledge_graph.dart                # ★ Graf aktif: validasi asiklik, topologicalOrder, computeStatuses, remedial plan
│   │   └── concept_graph.dart                  # Graf minimal legacy (isUnlocked, topologicalSort subset); komentar "menyusul"
│   ├── gamification/
│   │   ├── gamification_rules.dart             # Aturan XP/level/streak
│   │   └── badges.dart                         # Definisi badge
│   ├── models/                                 # Model domain aktif: ability_estimate, class_info, concept, concept_edge,
│   │                                           # concept_status (locked/open/learning/mastered), gamification_state, item,
│   │                                           # learning_material, pending_response, question, quiz_session,
│   │                                           # response_history, response_record, student_concept_state, user_profile, user_role
│   └── repositories/                           # Kontrak: auth, concept, item, progress, gamification, teacher_repository
├── data/
│   ├── datasources/
│   │   ├── supabase_service.dart               # Inisialisasi + akses client Supabase; provider supabaseClientProvider
│   │   ├── reminder_store.dart                 # SharedPreferences: jadwal pengingat (reminder_enabled/hour/minute)
│   │   ├── quiz_resume_store.dart              # SharedPreferences: tawaran lanjutkan sesi kuis (quiz_resume_v1)
│   │   └── pending_response_store.dart         # SharedPreferences: antrean respons offline (pending_responses_v1)
│   └── repositories/                           # Implementasi Supabase: auth_repository_impl, concept_repository_impl,
│                                               # item_repository_impl, progress_repository_impl,
│                                               # gamification_repository_impl, teacher_repository_impl
├── features/
│   ├── auth/
│   │   ├── application/auth_controller.dart    # ★ AuthController (Riverpod Notifier) — dipakai aktif
│   │   ├── application/placement_provider.dart # placementCompletedProvider (FutureProvider<bool>)
│   │   ├── presentation/                       # ★ Layar aktif: splash_screen, login_screen, register_screen
│   │   ├── providers/auth_provider.dart        # AuthProvider legacy (ChangeNotifier + provider package)
│   │   └── screens/                            # Layar legacy: login_screen, register_screen (provider, context.go('/'))
│   ├── placement/                              # ★ Jalur aktif siswa baru
│   │   ├── application/placement_controller.dart
│   │   └── presentation/placement_screen.dart, placement_test_screen.dart, placement_result_screen.dart
│   ├── placement_test/screens/                 # Legacy: placement_test_screen, placement_result_screen(theta, level via extra)
│   ├── student/                                # ★ Shell + tab siswa (aktif)
│   │   ├── application/student_providers.dart  # FutureProvider graf/status/lanjutan/gamifikasi/badge/progres
│   │   └── presentation/student_shell.dart, student_home_screen.dart, student_map_screen.dart,
│   │                            student_progress_screen.dart, student_profile_screen.dart
│   ├── concept/presentation/                   # ★ Materi aktif: concept_screen.dart (route /student/material/:id)
│   │   ├── application/simple_markdown.dart    # Parser markdown minimal
│   │   └── presentation/simple_markdown_view.dart
│   ├── quiz/                                   # ★ Kuis adaptif aktif
│   │   ├── application/quiz_controller.dart    # QuizController (EAP + resume + remedial + XP)
│   │   └── presentation/quiz_screen.dart, quiz_result_screen.dart (hasil inline, bukan route)
│   ├── knowledge_map/
│   │   ├── application/knowledge_map_layout.dart # Geometri peta (depth, posisi node, hit-test) — bukan status
│   │   └── presentation/knowledge_map_view.dart, knowledge_graph_painter.dart, knowledge_map_style.dart,
│   │                            knowledge_map_legend.dart, concept_detail_sheet.dart (bottom sheet → materi)
│   ├── learning/                               # Legacy (provider): providers/learning_provider.dart (mock 5 konsep),
│   │                                           # screens/concept_map_screen, learning_material_screen, quiz_screen (mock)
│   ├── home/
│   │   ├── application/home_providers.dart     # Dummy Provider<String> (placeholder)
│   │   ├── presentation/home_screen.dart       # ★ Home aktif (route /): placeholder + tombol ke /dev/gallery
│   │   └── screens/home_screen.dart            # Legacy (drawer + daftar konsep)
│   ├── progress/
│   │   ├── application/progress_dashboard.dart # Agregasi dashboard aktif (ThetaPoint, ConceptBarData, HistoryItemData)
│   │   ├── providers/progress_provider.dart    # Legacy ChangeNotifier
│   │   └── screens/progress_screen.dart        # Legacy
│   ├── profile/screens/profile_screen.dart    # Legacy (logout → /login)
│   ├── teacher/presentation/                   # ★ Guru aktif: teacher_classes_screen, class_detail_screen, student_detail_screen
│   ├── gamification/application/               # reminder_controller.dart (Notifier), notification_scheduler.dart
│   └── dev/presentation/gallery_screen.dart    # Galeri design system (route /dev/gallery)
test/ (28 file incl. helpers + widget_test)
supabase/schema.sql, rls.sql, fix_rls_recursion.sql, seed.sql, README.md
docs/progress.md, test-report.md, laporan-tahap-2-3.md
```

Duplikasi aktif vs legacy yang penting:

| Aktif (dirute) | Legacy (tidak dirute, jangan dipakai) |
|---|---|
| `features/auth/presentation/*` | `features/auth/screens/*`, `features/auth/providers/auth_provider.dart` |
| `features/home/presentation/home_screen.dart` | `features/home/screens/home_screen.dart` |
| `features/placement/presentation/*` + `placement/application/*` | `features/placement_test/screens/*` |
| `features/quiz/*`, `features/concept/*`, `features/student/*` | `features/learning/screens/*`, `features/learning/providers/*` |
| `features/student/presentation/student_progress_screen.dart` | `features/progress/screens/*`, `features/progress/providers/*` |
| `features/student/presentation/student_profile_screen.dart` | `features/profile/screens/*` |
| `domain/irt/irt_engine.dart`, `domain/graph/knowledge_graph.dart` | `core/services/irt_service.dart`, `core/services/knowledge_graph_service.dart`, `domain/graph/concept_graph.dart` (minimal) |

---

## 2. Daftar halaman/screen, fungsi, dan rute navigasi (siapa membuka siapa)

Router aktif `lib/core/router/app_router.dart:27-59` (`AppRoutes`) dan `:127-259` (daftar `GoRoute`). Redirect peran/placement di `:79-126`.

### 2.1 Rute aktif

| Path | Name | Screen (file) |
|---|---|---|
| `/splash` | `splash` | `SplashScreen` — `features/auth/presentation/splash_screen.dart` |
| `/login` | `login` | `LoginScreen` — `features/auth/presentation/login_screen.dart` |
| `/register` | `register` | `RegisterScreen` — `features/auth/presentation/register_screen.dart` |
| `/` | `home` | `HomeScreen` — `features/home/presentation/home_screen.dart` (placeholder; siswa/guru langsung di-redirect) |
| `/placement` | `placement` | `PlacementScreen` — `features/placement/presentation/placement_screen.dart` |
| `/placement/test` | `placement-test` | `PlacementTestScreen` — `features/placement/presentation/placement_test_screen.dart` |
| `/placement/result` | `placement-result` | `PlacementResultScreen` — `features/placement/presentation/placement_result_screen.dart` |
| `/student/home` | `student-home` | `StudentHomeScreen` (dalam `StudentShell`) |
| `/student/map` | `student-map` | `StudentMapScreen` (dalam `StudentShell`) |
| `/student/progress` | `student-progress` | `StudentProgressScreen` (dalam `StudentShell`) |
| `/student/profile` | `student-profile` | `StudentProfileScreen` (dalam `StudentShell`) |
| `/student/material/:conceptId[?from=]` | `student-material` | `ConceptScreen(conceptId, from)` — `features/concept/presentation/concept_screen.dart` |
| `/student/quiz/:conceptId[?from=]` | `student-quiz` | `QuizScreen(conceptId, from)` — `features/quiz/presentation/quiz_screen.dart` (fase `done` render `QuizResultScreen` inline, bukan route) |
| `/teacher/classes` | `teacher-classes` | `TeacherClassesScreen` |
| `/teacher/classes/:classId` | `teacher-class-detail` | `ClassDetailScreen(classId)` |
| `/teacher/classes/:classId/students/:studentId` | `teacher-student-detail` | `StudentDetailScreen(classId, studentId)` |
| `/dev/gallery` | `gallery` | `GalleryScreen` — `features/dev/presentation/gallery_screen.dart` |

Rute legacy (tidak aktif, hanya di `lib/core/routes/app_router.dart:17-78`): `/login`, `/register`, `/`, `/placement-test`, `/placement-result` (via `extra {theta, level}`), `/concept-map`, `/quiz/:conceptId`, `/learning-material/:conceptId`, `/progress`, `/profile`.

### 2.2 Fungsi tiap screen aktif + navigasi

| Screen | Fungsi | Dibuka dari | Membuka ke |
|---|---|---|---|
| `SplashScreen` | Layar tunggu saat sesi/placement diperiksa | `initialLocation` `/splash`; redirect saat `AuthStatus.initial/loading` atau `placement.isLoading` | tidak ada (murni redirect router) |
| `LoginScreen` (presentation) | Form surel + kata sandi via `AuthController` | Redirect `/splash`→`/login`; link "Masuk" dari register | "Daftar" → `push('/register')` (`login_screen.dart:142`); sukses → redirect router (peran/placement) |
| `RegisterScreen` (presentation) | Form daftar Siswa/Guru via `AuthController` | Tombol "Daftar" dari login | "Masuk" → `go('/login')` (`register_screen.dart:188`); sukses → redirect router |
| `HomeScreen` (`/`) | Placeholder inisialisasi struktur | Route `/` | "Lihat Galeri Komponen" → `push(AppRoutes.gallery)` (`home_screen.dart:44`) |
| `GalleryScreen` | Galeri design system, tanpa logika bisnis | Dari `HomeScreen` | tidak ada |
| `StudentShell` | Wadah `StatefulShellRoute` 4 tab bawah | Dibangun router `:163-165` | `goBranch(index)` antar `/student/home|map|progress|profile` |
| `PlacementScreen` | Pengantar tes penempatan + tombol mulai | Redirect siswa belum placement | "Mulai Tes Penempatan" → `push(placementTest)` (`placement_screen.dart:19`) |
| `PlacementTestScreen` | Kerjakan 12 soal adaptif + pembahasan | Dari `PlacementScreen` | Selesai → `go(placementResult)` (`placement_test_screen.dart:38`) |
| `PlacementResultScreen` | Tampilkan level, theta, ringkasan | Dari `PlacementTestScreen` | "Ke Beranda"/"Mulai Belajar" → `go(studentHome)` (`:35,:91`) |
| `StudentHomeScreen` | Sapaan, XP/streak, kartu lanjutan, target harian, lencana | Redirect default siswa; tab Beranda | "Mulai Kuis" → `push('/student/quiz/${concept.id}')` (`student_home_screen.dart:211`) |
| `StudentMapScreen` | Peta graf prasyarat interaktif (zoom/ketuk) | Tab Peta; "Mulai Belajar" dari progres kosong; "Kembali ke Peta" dari hasil kuis | Ketuk node → `showConceptDetailSheet` (`student_map_screen.dart:87-93`) |
| `showConceptDetailSheet` (bottom sheet, bukan route) | Detail node + tombol aksi / daftar prasyarat bila terkunci | Dari `StudentMapScreen` | "Pelajari Materi" (non-locked) → `pop` lalu `push(studentMaterial(id))` (`concept_detail_sheet.dart:91-93`); locked → tidak ada navigasi |
| `ConceptScreen` | Materi markdown 1 konsep + tombol kuis | Dari bottom sheet; dari hasil kuis (remedial/origin) | "Mulai Kuis" → `push(studentQuiz(id, from))` (`concept_screen.dart:94-96`); konsep tak dikenal → `pop()` (`:80`) |
| `QuizScreen` | Kuis adaptif 1 konsep (+ tawaran lanjutkan sesi) | Dari home; dari materi | Fase `done` → tampilkan `QuizResultScreen` inline (`quiz_screen.dart:61`); tidak ada `go/push` di file ini |
| `QuizResultScreen` (widget, bukan route) | Hasil lulus (XP/konsep terbuka) atau gagal (akar masalah + jalur remedial) | Render kondisional dari `QuizScreen` | Lulus+origin → `push(studentMaterial(origin))` (`:147-148`); "Kembali ke Peta" → `go(studentMap)` (`:159`, `:280`); gagal → tiap "Ulangi {konsep}" → `push(studentMaterial(path[i], from: conceptId))` (`:262-266`) |
| `StudentProgressScreen` | Dasbor: ringkasan, grafik theta, bar per konsep, riwayat | Tab Progres | Kosong → "Mulai Belajar" → `go(studentMap)` (`:67`); selain itu tidak ada |
| `StudentProfileScreen` | Identitas, XP/level/streak, lencana, pengingat, gabung kelas, keluar | Tab Profil | tidak ada `go/push`; "Keluar" → `signOut()` lalu redirect ke `/login` |
| `TeacherClassesScreen` | Daftar kelas guru: lihat, buat kelas, buka detail | Redirect default guru/admin | Kartu kelas → `push(teacherClassDetail(id))` (`teacher_classes_screen.dart:110-112`) |
| `ClassDetailScreen` | Kode kelas, daftar siswa, konsep paling sering gagal | Dari daftar kelas | Siswa → `push(teacherStudentDetail(classId, studentId))` (`class_detail_screen.dart:114-119`) |
| `StudentDetailScreen` | Ringkasan murid + status per konsep | Dari detail kelas | tidak ada (terminal) |

---

## 3. Alur utama aplikasi (login → fitur inti)

### 3.1 Siswa

1. Buka aplikasi → `/splash` (`initialLocation`, `core/router/app_router.dart:78`) → `SplashScreen` ("Memuat…").
2. Belum login → redirect ke `/login` (`:90,:92`). Bisa ke `/register` via "Daftar" (`login_screen.dart:142`), kembali via "Masuk" (`register_screen.dart:188`).
3. `signIn`/`signUp` → redirect cek peran (`:95-102`). Untuk siswa cek `placementCompletedProvider` (`:75,:105-108`).
4. Belum placement → paksa `/placement` (`:119,:125`) → `PlacementScreen` → tekan "Mulai Tes Penempatan" → `push /placement/test` (`placement_screen.dart:19`).
5. Kerjakan soal di `PlacementTestScreen` → selesai → `go /placement/result` (`:38`) → `PlacementResultScreen` tampilkan theta/level → "Mulai Belajar" → `go /student/home` (`:91`).
6. Masuk `StudentShell` (4 tab):
   - Beranda `/student/home`: kartu "Lanjutkan belajar" → "Mulai Kuis" → `push /student/quiz/:id`.
   - Peta `/student/map`: ketuk node → bottom sheet → bila terbuka "Pelajari Materi" → `push /student/material/:id`; bila terkunci hanya info prasyarat.
   - Materi `/student/material/:id`: baca markdown → "Mulai Kuis" → `push /student/quiz/:id`.
   - Kuis `/student/quiz/:id`: jawab adaptif → hasil inline. Lulus → "Kembali ke Peta" atau kembali ke origin remedial. Gagal → ikuti "Ulangi {konsep}" satu per satu (materi remedial dengan `?from=`) lalu "Kembali ke Peta".
   - Progres `/student/progress`: lihat grafik theta/bar/riwayat; bila kosong "Mulai Belajar" → `/student/map`.
   - Profil `/student/profile`: pengingat harian, gabung kelas via kode, lencana; "Keluar" → `signOut` → `/login`.
7. Upaya buka `/teacher/*` sebagai siswa ditolak ke `/student/home` atau `/placement` (`:121-123`).

### 3.2 Guru / admin

1. Login sebagai guru/admin → redirect ke `/teacher/classes` (`:96-102`) → `TeacherClassesScreen` ("Kelas Saya" + FAB "Buat Kelas").
2. Ketuk kartu kelas → `push /teacher/classes/:classId` → `ClassDetailScreen` (kode kelas + daftar siswa + "Konsep paling sering gagal").
3. Ketuk siswa → `push /teacher/classes/:classId/students/:studentId` → `StudentDetailScreen` (theta/XP + peta status per konsep). Terminal.
4. Kembali via back AppBar/sistem; tidak ada `go` eksplisit di detail guru.

---

## 4. Skema database Supabase

File: `supabase/schema.sql` (14 tabel) → `supabase/rls.sql` → `supabase/seed.sql` (urutan di `supabase/README.md:4`, `schema.sql:5`). Ekstensi `pgcrypto` (`schema.sql:7`).

| Tabel | Kolom (tipe) | PK | FK | Relasi / constraint |
|---|---|---|---|---|
| `profiles` (`schema.sql:12-19`) | `id uuid`, `full_name text?`, `role text NOT NULL DEFAULT 'student'`, `created_at timestamptz`, `updated_at timestamptz` | `id` | `id → auth.users(id) CASCADE` | `role IN ('student','teacher','admin')` |
| `classes` (`:24-31`) | `id uuid DEFAULT gen_random_uuid()`, `teacher_id uuid NOT NULL`, `name text NOT NULL`, `join_code text NOT NULL UNIQUE DEFAULT upper(substr(md5(random()::text),1,6))`, `created_at timestamptz` | `id` | `teacher_id → profiles(id) CASCADE` | 1 guru → N kelas |
| `class_members` (`:36-41`) | `class_id uuid`, `student_id uuid`, `joined_at timestamptz` | `(class_id, student_id)` | `class_id → classes(id) CASCADE`, `student_id → profiles(id) CASCADE` | N-N siswa↔kelas |
| `concepts` (`:46-55`) | `id uuid DEFAULT gen_random_uuid()`, `code text NOT NULL UNIQUE`, `title text NOT NULL`, `description text DEFAULT ''`, `topic text DEFAULT ''`, `tau numeric DEFAULT 0`, `order_index int DEFAULT 0`, `created_at timestamptz` | `id` | tidak ada | Simpul knowledge graph |
| `concept_edges` (`:60-65`) | `prerequisite_id uuid`, `concept_id uuid` | `(prerequisite_id, concept_id)` | keduanya `→ concepts(id) CASCADE` | Prasyarat; `prerequisite_id <> concept_id` |
| `materials` (`:70-76`) | `id uuid DEFAULT gen_random_uuid()`, `concept_id uuid NOT NULL UNIQUE`, `title text NOT NULL`, `body_markdown text NOT NULL`, `created_at timestamptz` | `id` | `concept_id → concepts(id) CASCADE` | 1-1 konsep→materi |
| `items` (`:81-93`) | `id uuid DEFAULT gen_random_uuid()`, `concept_id uuid NOT NULL`, `question text NOT NULL`, `options jsonb DEFAULT '[]'`, `correct_index int NOT NULL`, `explanation text DEFAULT ''`, `a numeric DEFAULT 1`, `b numeric DEFAULT 0`, `n_responses int DEFAULT 0`, `created_at timestamptz` | `id` | `concept_id → concepts(id) CASCADE` | Bank soal + param IRT 2PL; `UNIQUE(concept_id, question)`; `correct_index 0..3`; `a>0`; `n_responses>=0` |
| `quiz_sessions` (`:98-107`) | `id uuid DEFAULT gen_random_uuid()`, `student_id uuid NOT NULL`, `concept_id uuid?`, `status text DEFAULT 'berjalan'`, `final_theta numeric?`, `started_at timestamptz`, `finished_at timestamptz?` | `id` | `student_id → profiles(id) CASCADE`, `concept_id → concepts(id) SET NULL` | `status IN ('berjalan','selesai','batal')` |
| `responses` (`:112-121`) | `id uuid DEFAULT gen_random_uuid()`, `session_id uuid NOT NULL`, `student_id uuid NOT NULL`, `item_id uuid NOT NULL`, `selected_index int NOT NULL`, `is_correct bool NOT NULL`, `theta_after numeric?`, `answered_at timestamptz` | `id` | `session_id → quiz_sessions(id) CASCADE`, `student_id → profiles(id) CASCADE`, `item_id → items(id) CASCADE` | `selected_index >= 0` |
| `student_ability` (`:126-131`) | `student_id uuid`, `theta numeric DEFAULT 0`, `se numeric DEFAULT 1`, `updated_at timestamptz` | `student_id` | `student_id → profiles(id) CASCADE` | `se > 0` |
| `student_concept_state` (`:136-145`) | `student_id uuid`, `concept_id uuid`, `status text DEFAULT 'locked'`, `theta_c numeric DEFAULT 0`, `n_answered int DEFAULT 0`, `updated_at timestamptz` | `(student_id, concept_id)` | `student_id → profiles(id) CASCADE`, `concept_id → concepts(id) CASCADE` | `status IN ('locked','open','learning','mastered')`; `n_answered>=0` |
| `gamification` (`:150-156`) | `student_id uuid`, `xp int DEFAULT 0`, `level int DEFAULT 1`, `streak int DEFAULT 0`, `last_active_date date?` | `student_id` | `student_id → profiles(id) CASCADE` | `xp>=0`; `level>=1`; `streak>=0` |
| `badges` (`:161-167`) | `id uuid DEFAULT gen_random_uuid()`, `code text NOT NULL UNIQUE`, `name text NOT NULL`, `description text DEFAULT ''`, `created_at timestamptz` | `id` | tidak ada | Daftar lencana |
| `user_badges` (`:172-177`) | `user_id uuid`, `badge_id uuid`, `awarded_at timestamptz` | `(user_id, badge_id)` | `user_id → profiles(id) CASCADE`, `badge_id → badges(id) CASCADE` | N-N user↔badge |

Indeks: 15 indeks di `schema.sql:182-195` (mis. `classes_teacher_idx`, `responses_session_idx`).

Fungsi/trigger (`schema.sql:204-308`): `is_admin()`, `set_updated_at()` + 3 trigger, `prevent_role_escalation()` (hanya admin boleh ubah role), `handle_new_user()` + trigger `on_auth_user_created` di `auth.users` (auto-insert `profiles` + `gamification` + `student_ability`; role dipaksa `student`/`teacher`).

Seed (`supabase/seed.sql`): 8 konsep K01–K08; 8 edge (K01→K02, K02→K03, K03→K04, K03→K05, K01→K06, K06→K07, K05→K08, K07→K08); 8 materi (1/konsep); 64 soal (8/konsep, `a` 0.8–2.0); 8 badge (`penjelajah-1`, `konsisten-3`, `teliti`, `master-8`, `langkah-pertama`, `beruntun-3`, `konsep-pertama`, `pahlawan-remedial`).

RLS (`supabase/rls.sql`, `fix_rls_recursion.sql`): RLS aktif 14 tabel; katalog (`concepts`, `concept_edges`, `materials`, `items`, `badges`) dibaca semua login, tulis hanya admin via `is_admin()`; data siswa milik-sendiri + guru via `is_teacher_of()` + admin penuh. Fungsi anti-rekursi `is_class_teacher / is_class_member / is_teacher_of`. RPC `join_class(p_code text) → uuid` (error: `'Harus masuk terlebih dahulu.'`, `'Kode kelas tidak ditemukan.'`).

---

## 5. Daftar service/repository dan fungsi yang dipanggil ke Supabase

### 5.1 Datasource

| File | Fungsi | Panggil Supabase? |
|---|---|---|
| `lib/data/datasources/supabase_service.dart` | `initialize({url, anonKey})` (`:10-15`), `isInitialized` (`:18-25`), `client` (`:28`), `supabaseClientProvider` (`:32-34`) | Hanya init + sediakan klien (`Supabase.initialize`); tidak akses tabel |
| `lib/core/utils/supabase_config.dart` | `url` (`String.fromEnvironment SUPABASE_URL`), `anonKey` (`SUPABASE_ANON_KEY`), `isConfigured` | tidak ada (hanya baca dart-define) |
| `lib/data/datasources/reminder_store.dart` | `SharedPreferencesReminderStore.load/save/...` (keys `reminder_enabled/hour/minute/last_recommendation`) | tidak ada (SharedPreferences) |
| `lib/data/datasources/quiz_resume_store.dart` | `load/save/clear` (key `quiz_resume_v1`, timeout 3 dtk) | tidak ada |
| `lib/data/datasources/pending_response_store.dart` | `loadAll/saveAll` (key `pending_responses_v1`) | tidak ada |

### 5.2 Repository (kontrak `lib/domain/repositories/*.dart` → `lib/data/repositories/*_impl.dart`)

| Repository | Fungsi → operasi Supabase (tabel) |
|---|---|
| Auth (`auth_repository_impl.dart`) | `_fetchProfile` → `profiles.select().eq(id).maybeSingle()` (`:18-22`); `signUp` → `auth.signUp(email,password,data:{full_name,role})` + fetch (`:42-52`, admin dipaksa student `:41`); `signIn` → `auth.signInWithPassword` + fetch (`:64-73`); `signOut` → `auth.signOut()` (`:82`); `currentProfile`/`authStateChanges` → `auth.currentUser`/`onAuthStateChange` + fetch (`:90-110`) |
| Concept (`concept_repository_impl.dart`) | `fetchConcepts` → `concepts.select(id,code,title,description,topic,tau,order_index).order(order_index)` + `fetchEdges` (`:21-29`); `fetchEdges` → `concept_edges.select(prerequisite_id,concept_id)` (`:49-51`); `fetchMaterial` → `materials.select().eq(concept_id).maybeSingle()` (`:67-71`) |
| Item (`item_repository_impl.dart`) | `fetchItems(conceptId)` → `items.select().eq(concept_id).order(b)` (`:34-38`); `fetchPlacementItems({limit=20})` → `items.select().order(b).limit(limit)` (`:51-55`) |
| Progress (`progress_repository_impl.dart`) | `loadAbility` → `student_ability.select(theta,se).eq(student_id).maybeSingle()` (`:78-82`); `saveAbility` → `student_ability.upsert({student_id,theta,se}, onConflict:student_id)` (`:98-105`); `loadConceptStates` → `student_concept_state.select().eq(student_id)` (`:115-118`); `upsertConceptState` → `student_concept_state.upsert(..., onConflict:student_id,concept_id)` (`:137-146`); `saveResponse/flushPending` → `responses.insert({session_id,student_id,item_id,selected_index,is_correct,theta_after})`, offline → antrean `PendingResponseStore` (`:23-28,:60-69`); `countResponsesToday` → `responses.select(id).eq(student_id).gte(answered_at,startOfDay).limit(1000)` (`:212-217`); `createSession` → `quiz_sessions.insert({student_id,concept_id}).select(id).single()` (`:228-232`); `finishSession` → `quiz_sessions.update({status:'selesai',final_theta,finished_at}).eq(id)` (`:245-249`); `history` → `quiz_sessions.select().eq(student_id).order(started_at desc).limit(limit)` (`:259-264`); `loadResponseHistory` → `responses.select(session_id,is_correct,theta_after,answered_at).eq(...).order(answered_at asc).limit(limit)` (`:280-285`) |
| Gamification (`gamification_repository_impl.dart`) | `load/addXp/updateStreak/_save` → `gamification.select().eq(student_id).maybeSingle()` (`:44-48`) + `gamification.upsert({student_id,xp,level,streak,last_active_date}, onConflict:student_id)` (`:26-37`); `loadBadgeCodes` → `user_badges.select(badge_id, badges(code)).eq(user_id)` (`:109-112`); `awardBadge` → `badges.select(id).eq(code).maybeSingle()` (`:132-136`) + cek `user_badges` (`:139-144`) + `user_badges.insert({user_id,badge_id})` (`:147-150`) |
| Teacher (`teacher_repository_impl.dart`) | `classes` → `classes.select().eq(teacher_id).order(created_at)` (`:37-41`) + `class_members.select(class_id).inFilter(class_id,ids)` (`:47-50`); `createClass` → `classes.insert({teacher_id,name}).select().single()` (`:73-77`); `classReport` → `classes.select().eq(id).maybeSingle()` (`:87-91`) + `class_members.select(student_id)` (`:97-100`) + `profiles.select(id,full_name)` (`:114-117`) + `student_ability.select(student_id,theta)` (`:118-121`) + `student_concept_state.select(student_id,status)` (`:122-125`) + `gamification.select(student_id,xp,last_active_date)` (`:126-129`); `myClasses` → `class_members.select(class_id).eq(student_id)` (`:201-204`) + `classes.select().inFilter(id,...)` (`:209-213`); `joinClass` → `rpc('join_class',{p_code})` (`:231-234`); `conceptFailRates` → `class_members` + `quiz_sessions.select().inFilter(student_id).limit(1000)` (`:244-256`) + `concepts.select(id,tau)` (`:257-260`); `memberConceptStates` → `student_concept_state.select().eq(student_id)` (`:284-287`) |

---

## 6. State management dan package di `pubspec.yaml` + alasan

### 6.1 State management

- Aktif: `flutter_riverpod ^3.4.3`. `QuizController extends Notifier<QuizState>` (`features/quiz/application/quiz_controller.dart:314,962-963`, state immutable `Equatable` + `copyWith` + `QuizPhase`); `PlacementController extends Notifier<PlacementState>` (`features/placement/application/placement_controller.dart:218,412-415`); `AuthController extends Notifier<AuthState>` (`features/auth/application/auth_controller.dart:66,197-198`); `FutureProvider` di `features/student/application/student_providers.dart:20-90` + `placementCompletedProvider` (`features/auth/application/placement_provider.dart:10-20`); `ReminderController extends Notifier` (`features/gamification/application/reminder_controller.dart:12-17`); dashboard `features/progress/application/progress_dashboard.dart`; router `Provider<GoRouter> routerProvider` (`core/router/app_router.dart:73`).
- Legacy (tidak dipakai router aktif, hanya layar lama): package `provider ^6.1.1` (`ChangeNotifier`): `AuthProvider` (`features/auth/providers/auth_provider.dart:5`), `LearningProvider` (`features/learning/providers/learning_provider.dart:8`, mock 5 konsep), `ProgressProvider` (`features/progress/providers/progress_provider.dart:17`).

### 6.2 Packages (`pubspec.yaml:9-58`)

| Package | Versi | Alasan (bukti import) |
|---|---|---|
| `flutter` (sdk) | — | Framework UI |
| `cupertino_icons` | `^1.0.6` | Ikon iOS; tidak ada import di `lib/` |
| `google_fonts` | `^9.0.0` | Font; `core/theme/app_theme.dart:2` |
| `flutter_svg` | `^2.0.9` | tidak ada (tidak ada import di `lib/`) |
| `provider` | `^6.1.1` | State legacy `ChangeNotifier` (9 file `features/*/screens`, `learning/providers`, dsb.) |
| `go_router` | `^18.0.2` | Navigasi aktif; `core/router/app_router.dart:2`, `app.dart:16-21` |
| `http` | `^1.1.2` | HTTP; `core/error/app_exception.dart:5` |
| `dio` | `^5.4.0` | tidak ada (tidak ada import di `lib/`) |
| `shared_preferences` | `^2.5.6` | Simpan luring; `quiz_resume_store.dart:5`, `pending_response_store.dart:3`, `reminder_store.dart:3` |
| `sqflite` | `^2.3.0` | tidak ada |
| `path_provider` | `^2.1.1` | tidak ada |
| `crypto` | `^3.0.3` | Hash; `core/services/auth_service.dart:2` (jalur legacy) |
| `graphview` | `^1.2.0` | tidak ada (peta pakai `CustomPainter`, bukan graphview) |
| `fl_chart` | `^1.2.0` | Grafik theta; `student_progress_screen.dart:1`, `progress/screens/progress_screen.dart:3` |
| `intl` | `^0.20.3` | tidak ada |
| `uuid` | `^4.3.3` | tidak ada |
| `collection` | `^1.18.0` | tidak ada import `package:collection` (hanya `dart:collection`) |
| `flutter_local_notifications` | `^22.3.2` | Pengingat harian; `gamification/application/notification_scheduler.dart:1` |
| `timezone` | `^0.11.0` | Jadwal zoned; `notification_scheduler.dart:3-4` |
| `flutter_riverpod` | `^3.4.3` | State aktif (lihat 6.1) |
| `supabase_flutter` | `^2.18.3` | Backend; `data/datasources/supabase_service.dart:2`, `*_repository_impl.dart` |
| `equatable` | `^2.1.0` | Equality state/model; `domain/graph/knowledge_graph.dart:7`, `quiz_controller.dart:1`, `ability_estimate.dart:1` |
| Dev: `flutter_test` (sdk) | — | `test/` 28 file |
| Dev: `flutter_lints` | `^3.0.0` | Lint |
| Dev: `mocktail` | `^1.0.5` | Mock test; `test/helpers/repository_fakes.dart` |

SDK: `sdk: '>=3.0.0 <4.0.0'` (`pubspec.yaml:6-7`). Terinstal saat pemeriksaan: Flutter `3.47.2` stable, Dart `3.13.2`.

---

## 7. Semua validasi input

Sumber aktif: `lib/core/validators.dart` (murni, tanpa Flutter).

| Form | Aturan | Pesan error persis |
|---|---|---|
| Surel (login `:100`, register `:130`) — `validateEmail` (`validators.dart:5-12`) | trim; kosong → galat; regex `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$` | `'Surel tidak boleh kosong.'`, `'Format surel tidak valid.'` |
| Kata sandi (login `:126`, register `:156` + hint "Minimal 8 karakter, huruf dan angka") — `validatePassword` (`:15-24`) | kosong; <8 char; harus ada huruf + angka | `'Kata sandi tidak boleh kosong.'`, `'Kata sandi minimal 8 karakter.'`, `'Kata sandi harus mengandung huruf dan angka.'` |
| Nama lengkap (register `:117`) — `validateName` (`:27-32`) | trim; 3–50 char | `'Nama minimal 3 karakter.'`, `'Nama maksimal 50 karakter.'` |
| Konfirmasi (register `:169-172`) — `validateConfirmPassword` (`:35-41`) | confirm kosong; harus `== password` | `'Konfirmasi kata sandi tidak boleh kosong.'`, `'Konfirmasi kata sandi tidak sama.'` |
| Gabung kelas (`student_profile_screen.dart:455-464`) — `validateClassCode` + `maxLength: 6` | trim; kosong; tepat 6 char; regex `^[A-Za-z0-9]{6}$` | `'Kode kelas tidak boleh kosong.'`, `'Kode kelas harus 6 karakter.'`, `'Kode kelas hanya boleh huruf dan angka.'`; sukses → SnackBar `'Berhasil bergabung ke kelas!'` (`:374`) |
| Buat kelas guru (`teacher_classes_screen.dart:218-231`, inline bukan `validators.dart`) | `(value??'').trim().isEmpty` | `'Nama kelas tidak boleh kosong.'`; repo juga melempar `'Nama kelas tidak boleh kosong.'` (`teacher_repository_impl.dart:71`), `'Kode kelas tidak boleh kosong.'` (`:229`), `'Kelas tidak ditemukan.'` (`:93`) |

Validasi legacy (tidak dipakai router aktif, pola `provider`): `features/auth/screens/login_screen.dart:96-104,126-134` (`'Email tidak boleh kosong'`, `'Email tidak valid'`, `'Password tidak boleh kosong'`, `'Password minimal 6 karakter'`); `features/auth/screens/register_screen.dart:81-106,147-214` (`'Nama tidak boleh kosong'`, `'Email tidak boleh kosong'`, `'Email tidak valid'`, `'Pilih tingkat kelas'` dropdown 7–12, `'Password tidak boleh kosong'`, `'Password minimal 6 karakter'`, `'Password tidak sama'`).

Form lain: tidak ada validator di `features/quiz`, `placement`, `concept`, `progress`, `knowledge_map`; `gallery_screen.dart:71` hanya contoh `errorText: 'Format surel tidak valid'` (display saja).

---

## 8. Implementasi logika inti (Knowledge Graph dan IRT 2PL)

### 8.1 IRT 2PL

Aktif: `lib/domain/irt/irt_engine.dart` (+ referensi murni `irt_math.dart`). Dipakai `quiz_controller.dart` / `placement_controller.dart`.

| File:fungsi | Rumus / aturan |
|---|---|
| `irt_math.dart:10-17` `probability2pl({theta,a,b})` | `P(theta)=1/(1+exp(-a*(theta-b)))` → `1.0/(1.0+exp(-a*(theta-b)))` |
| `irt_math.dart:20-27` `information2pl({theta,a,b})` | `informasi=a²P(1-P)` → `a*a*p*(1-p)` |
| `irt_math.dart:30-33` `standardNormalPdf(x)` | Prior `N(0,1)`: `0.3989422804014327*exp(-0.5*x*x)` |
| `irt_engine.dart:17-23` konstanta | `eapMinTheta=-4.0`, `eapMaxTheta=4.0`, `eapStep=0.1` (grid -4..4 langkah 0.1) |
| `irt_engine.dart:40-43` `probability(theta,a,b)` | Sama 2PL |
| `irt_engine.dart:46-49` `information(theta,a,b)` | Sama Fisher |
| `irt_engine.dart:57-106` `estimateEap(responses,{priorMean=0.0,priorSd=1.0})` | EAP grid + prior Normal (`logWeights=logLikelihood-0.5*z²`, `z=(theta-priorMean)/priorSd` default `N(0,1)`), stabil `log-sum-exp`, hasil `AbilityEstimate(theta,se)` (mean + `sqrt(varians)`) |
| `irt_engine.dart:114-140` `selectNextItem(theta,candidates,usedIds,{random})` | Informasi Fisher maksimum; seri dipecah acak terkontrol; `null` bila habis |
| `irt_engine.dart:149-173` `evaluateSession({estimate,nAnswered,consecutiveWrong,tau,minItems=4,maxItems=8,maxSe=0.6,maxConsecutiveWrong=3})` | `consecutiveWrong>=3` → `failed` (gagal dini); `nAnswered>=8` → `theta>=tau?mastered:failed`; `nAnswered>=4 && se<=0.6` → `theta>=tau?mastered:failed`; selain itu `ongoing` |

Legacy (tidak dipakai aktif, hanya `learning_provider.dart`): `lib/core/services/irt_service.dart` — `calculateProbability` 2PL (`:22-29`), `calculateProbability3PL` (`:33-42`, di luar spek), `calculateInformation` (`:46-57`), `updateTheta` MLE Newton-Raphson 10 iterasi clamp [-4,4] (`:61-107`, bukan EAP), `selectNextQuestion`, `calculateSEM=1/sqrt(sum I)`, `isPlacementTestComplete`.

### 8.2 Knowledge Graph

Aktif: `lib/domain/graph/knowledge_graph.dart`. Status enum `lib/domain/models/concept_status.dart:9-13` (`locked, open, learning, mastered` + label Indonesia `:31-42`).

| File:fungsi | Aturan |
|---|---|
| `knowledge_graph.dart:70-108` konstruktor | Tolak duplikat/edge tak dikenal; lempar `GraphCycleException` bila siklus (termasuk self-loop) |
| `knowledge_graph.dart:183-211` `topologicalOrder()` | Kahn (`inDegree=prereq.count`, queue `inDegree==0`) |
| `knowledge_graph.dart:134-146` `ancestorsOf(id)` | BFS prasyarat transitif |
| `knowledge_graph.dart:219-241` `computeStatuses(states)` | `mastered→mastered`; bila ada ancestor non-mastered → `locked`; bila `state==null`/`nAnswered==0` → `open`; selain itu → `learning` |
| `knowledge_graph.dart:302-320` `newlyUnlocked(masteredId,statuses)` | Yang `locked` + ancestor mengandung `masteredId` + semua prasyarat `mastered` |
| `knowledge_graph.dart:248-295` `buildRemedialPlan(failedId,statuses)` | `W`=prasyarat lemah non-mastered, `R`=anggota `W` yang semua parent mastered, `orderedPath=[topo(R),topo(W-R),failed]`; `W` kosong → `[failed]` (`isRepeatOnly`) |
| `knowledge_map_layout.dart:11-21` `computeKnowledgeDepths` + `:69-116` `KnowledgeMapLayout.fromGraph` | Geometri saja: akar depth 0, lain `1+max(parent)`; node 148×100, hGap 28, vGap 64; `nodeAt` hit-test — tidak ada logika status/unlock |

Legacy/minimal: `domain/graph/concept_graph.dart` (komentar "Algoritma lengkap menyusul"; hanya `isUnlocked` + `topologicalSort` subset); `core/services/knowledge_graph_service.dart` (`isConceptLocked`, `getMissingPrerequisites`, `getRemediallPath` [typo], `topologicalSort`, `getAvailableConcepts`, `getDescendants`, `getFullLearningPath` — hanya dipakai `learning_provider`).

---

## 9. Fitur: selesai, sebagian, belum

Acuan: screen + repository + rute aktif ada. Semua di bawah "selesai" sudah punya ketiganya + unit test (lihat `test/`, 28 file).

| Status | Fitur + bukti |
|---|---|
| Selesai | Auth (`presentation/splash|login|register`, `auth_repository`, rute `/splash|login|register` + redirect; test `auth_controller|auth_flow|login_screen`) |
| Selesai | Placement test (`placement/presentation/*`, `placement_controller` 12 soal, repo `progress|item|concept`, rute `/placement|/placement/test|/placement/result` + gate; test `placement_controller`) |
| Selesai | Knowledge map (`student_map_screen` + `knowledge_map/*view|painter|legend|detail_sheet|layout`, `concept_repository`, rute `/student/map`; test `knowledge_map|layout|graph_engine`) |
| Selesai | Kuis adaptif (`quiz/presentation/quiz_screen|quiz_result`, `quiz_controller` EAP+resume+remedial+XP, repo `item|progress|gamification|concept`, rute `/student/quiz/:conceptId?from=`; test `quiz_controller|quiz_question`) |
| Selesai | Materi (`concept/presentation/concept_screen|simple_markdown_view`, `concept/application/simple_markdown`, model `learning_material`, rute `/student/material/:conceptId`; test `simple_markdown`) |
| Selesai | Progres/dashboard (`student_progress_screen` + `fl_chart`, `progress/application/progress_dashboard`, `progress_repository`, rute `/student/progress`; test `progress_dashboard|progress_screen`) |
| Selesai | Gamifikasi/notifikasi (rules `badges|gamification_rules`, `gamification_repository`, `reminder_controller|notification_scheduler` + `reminder_store`, UI di home/profil, tanpa rute khusus; test `gamification_rules|reminder|recommendation|profile_screen`) |
| Selesai | Teacher dashboard (`teacher_classes|class_detail|student_detail`, `teacher_repository`, rute `/teacher/classes|.../:classId|.../students/:studentId` + redirect guru/admin; test `teacher_report|teacher_screens`) |
| Selesai | Profil (`student_profile_screen`, rute `/student/profile`, repo `gamification|auth`; test `profile_screen`) |
| Sebagian | tidak ada (semua fitur MVP di atas selesai penuh; tidak ditemukan fitur yang hanya punya screen tanpa repo/rute atau sebaliknya di jalur aktif) |
| Belum | Panel admin bank soal — tidak ada screen/repo/rute admin (`docs/progress.md`: "Berikutnya (di luar MVP): panel admin bank soal"); peran `admin` hanya diarahkan ke rute guru (`core/router/app_router.dart:96-102`) |

Catatan: banyak file legacy (`features/auth/screens`, `features/home/screens`, `features/learning/*`, `features/placement_test/*`, `features/progress/screens|providers`, `features/profile/screens`, `core/services/*`, `core/routes/*`) tidak dirute aktif — dianggap mati, bukan "sebagian".

---

## 10. Cara menjalankan proyek

Versi Flutter: tidak ada pin di repo (`pubspec.yaml:6-7` hanya `sdk >=3.0.0 <4.0.0`; tidak ada `.fvmrc`). Terinstal saat pemeriksaan: `Flutter 3.47.2 • channel stable • Dart 3.13.2 • DevTools 2.60.0`.

Konfigurasi env (cara utama `--dart-define`; alternatif salin `.env.example` → `.env`, sudah di-gitignore):

```bash
# .env.example
SUPABASE_URL=https://contoh.supabase.co
SUPABASE_ANON_KEY=isi-anon-key-di-sini
```

Tanpa kunci aplikasi tetap jalan tanpa backend (layar kosong + peringatan) — `lib/main.dart:14`, `INSTALL.md:54-56`.

Perintah:

```bash
flutter pub get
# Tanpa backend:
flutter run
# Dengan backend (disarankan):
flutter run --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co --dart-define=SUPABASE_ANON_KEY=isi-anon-key-di-sini
flutter analyze   # harus bersih
flutter test      # README klaim 229 tes
flutter build apk --release
```

Setup Supabase (`supabase/README.md`, `README.md:95-104`, `INSTALL.md`): buat proyek di supabase.com → catat URL + anon key → di SQL Editor jalankan `supabase/schema.sql` → `supabase/rls.sql` → `supabase/seed.sql` → verifikasi count. Akun demo `INSTALL.md:60-68` (`student@test.com` / `teacher@test.com`, password `password`) tidak ada di `seed.sql` — harus didaftarkan manual via register.

Dokumen terkait: `README.md`, `INSTALL.md`, `QUICKSTART.md`, `supabase/README.md`, `docs/progress.md`, `docs/test-report.md`, `CHANGELOG.md`, `.env.example`.
