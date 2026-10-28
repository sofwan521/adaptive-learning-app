import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/data/datasources/reminder_store.dart';
import 'package:adaptive_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/gamification_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/teacher_repository_impl.dart';
import 'package:adaptive_learning_app/domain/models/class_info.dart';
import 'package:adaptive_learning_app/domain/models/student_concept_state.dart';
import 'package:adaptive_learning_app/domain/models/user_profile.dart';
import 'package:adaptive_learning_app/domain/models/user_role.dart';
import 'package:adaptive_learning_app/domain/repositories/teacher_repository.dart';
import 'package:adaptive_learning_app/features/gamification/application/notification_scheduler.dart';
import 'package:adaptive_learning_app/features/student/presentation/student_profile_screen.dart';
import 'package:adaptive_learning_app/features/teacher/presentation/class_detail_screen.dart';
import 'package:adaptive_learning_app/features/teacher/presentation/student_detail_screen.dart';
import 'package:adaptive_learning_app/features/teacher/presentation/teacher_classes_screen.dart';

import '../helpers/repository_fakes.dart';

const _teacher = UserProfile(
  id: 'guru-1',
  fullName: 'Guru Uji',
  role: UserRole.teacher,
);

class FakeTeacherRepository implements TeacherRepository {
  List<ClassInfo> classList;
  List<ClassInfo> joinedClasses;
  Map<String, ClassReport> reports;
  Map<String, List<ConceptFailRate>> failRates;
  Map<String, List<StudentConceptState>> studentStates;
  final List<String> joinedCodes = [];
  AppException? failure;

  FakeTeacherRepository({
    List<ClassInfo>? classList,
    List<ClassInfo>? joinedClasses,
    Map<String, ClassReport>? reports,
    Map<String, List<ConceptFailRate>>? failRates,
    Map<String, List<StudentConceptState>>? studentStates,
  })  : classList = classList ?? [],
        joinedClasses = joinedClasses ?? [],
        reports = reports ?? {},
        failRates = failRates ?? {},
        studentStates = studentStates ?? {};

  void _throwIfFailed() {
    if (failure != null) throw failure!;
  }

  @override
  Future<List<ClassInfo>> classes() async {
    _throwIfFailed();
    return classList;
  }

  @override
  Future<ClassInfo> createClass(String name) async {
    _throwIfFailed();
    final created = ClassInfo(
      id: 'kelas-${classList.length + 1}',
      teacherId: _teacher.id,
      name: name.trim(),
      joinCode: 'KL${(classList.length + 1).toString().padLeft(4, '0')}',
    );
    classList = [...classList, created];
    return created;
  }

  @override
  Future<ClassReport> classReport(String classId) async {
    _throwIfFailed();
    final report = reports[classId];
    if (report == null) throw const AppException('Kelas tidak ditemukan.');
    return report;
  }

  @override
  Future<List<ClassInfo>> myClasses() async {
    _throwIfFailed();
    return joinedClasses;
  }

  @override
  Future<String> joinClass(String code) async {
    _throwIfFailed();
    final normalized = code.trim().toUpperCase();
    joinedCodes.add(normalized);
    for (final classInfo in joinedClasses) {
      if (classInfo.joinCode == normalized) return classInfo.id;
    }
    if (normalized == 'AB12CD') {
      const joined = ClassInfo(
        id: 'kelas-9',
        teacherId: 'guru-1',
        name: 'Matematika 7A',
        joinCode: 'AB12CD',
      );
      joinedClasses = [...joinedClasses, joined];
      return joined.id;
    }
    throw const AppException('Kode kelas tidak ditemukan.');
  }

  @override
  Future<List<ConceptFailRate>> conceptFailRates(String classId) async {
    _throwIfFailed();
    return failRates[classId] ?? [];
  }

  @override
  Future<List<StudentConceptState>> memberConceptStates(
    String studentId,
  ) async {
    _throwIfFailed();
    return studentStates[studentId] ?? [];
  }
}

ClassReport _report() => ClassReport(
      classId: 'kelas-1',
      className: 'Matematika 7A',
      joinCode: 'AB12CD',
      totalConcepts: 3,
      members: [
        ClassMemberReport(
          studentId: 'siswa-1',
          fullName: 'Siswa Uji',
          percent: 69,
          masteredCount: 1,
          lastActive: DateTime(2026, 10, 12),
        ),
        const ClassMemberReport(
          studentId: 'siswa-2',
          fullName: '',
          percent: 38,
          masteredCount: 0,
        ),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  FakeTeacherRepository? teacher,
}) async {
  final container = ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(profile: _teacher),
      ),
      teacherRepositoryProvider.overrideWithValue(
        teacher ?? FakeTeacherRepository(),
      ),
      conceptRepositoryProvider.overrideWithValue(FakeConceptRepository()),
      gamificationRepositoryProvider.overrideWithValue(
        FakeGamificationRepository(),
      ),
      reminderStoreProvider.overrideWithValue(_MemoryReminderStore()),
      notificationSchedulerProvider.overrideWithValue(_FakeScheduler()),
    ],
    retry: (_, __) => null,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

class _MemoryReminderStore implements ReminderStore {
  ReminderSettings settings = const ReminderSettings();
  String? lastKey;

  @override
  Future<ReminderSettings> load() async => settings;

  @override
  Future<void> save(ReminderSettings value) async {
    settings = value;
  }

  @override
  Future<String?> getLastRecommendationKey() async => lastKey;

  @override
  Future<void> setLastRecommendationKey(String key) async {
    lastKey = key;
  }
}

class _FakeScheduler implements NotificationScheduler {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showRecommendation({required String conceptName}) async {}

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> cancelDailyReminder() async {}
}

void main() {
  group('TeacherClassesScreen', () {
    testWidgets('menampilkan daftar kelas dengan kode dan jumlah',
        (tester) async {
      await _pump(
        tester,
        const TeacherClassesScreen(),
        teacher: FakeTeacherRepository(
          classList: const [
            ClassInfo(
              id: 'kelas-1',
              teacherId: 'guru-1',
              name: 'Matematika 7A',
              joinCode: 'AB12CD',
              memberCount: 2,
            ),
          ],
        ),
      );

      expect(find.text('Matematika 7A'), findsOneWidget);
      expect(find.textContaining('2 siswa'), findsOneWidget);
      expect(find.textContaining('AB12CD'), findsOneWidget);
    });

    testWidgets('kosong mengajak membuat kelas', (tester) async {
      await _pump(tester, const TeacherClassesScreen());

      expect(find.textContaining('Belum ada kelas'), findsOneWidget);
      expect(find.byKey(const Key('class-create-fab')), findsOneWidget);
    });

    testWidgets('galat memuat kelas bisa dicoba lagi', (tester) async {
      final teacher = FakeTeacherRepository(
        classList: const [
          ClassInfo(
            id: 'kelas-1',
            teacherId: 'guru-1',
            name: 'Matematika 7A',
            joinCode: 'AB12CD',
            memberCount: 2,
          ),
        ],
      )..failure = const AppException('Gagal memuat kelas.');
      await _pump(tester, const TeacherClassesScreen(), teacher: teacher);

      expect(find.text('Gagal memuat kelas.'), findsOneWidget);

      teacher.failure = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Matematika 7A'), findsOneWidget);
      expect(find.text('Gagal memuat kelas.'), findsNothing);
    });

    testWidgets('buat kelas memunculkan hasil di daftar', (tester) async {
      final teacher = FakeTeacherRepository();
      await _pump(
        tester,
        const TeacherClassesScreen(),
        teacher: teacher,
      );

      await tester.tap(find.byKey(const Key('class-create-fab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byKey(const Key('class-name-field')),
        'Matematika 8B',
      );
      // Tutup keyboard dulu agar teardown fokus dialog bersih.
      tester.testTextInput.hide();
      await tester.pump();
      await tester.tap(find.byKey(const Key('class-create-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Matematika 8B'), findsOneWidget);
      expect(teacher.classList, hasLength(1));
      expect(teacher.classList.single.joinCode, hasLength(6));
    });
  });

  group('ClassDetailScreen', () {
    testWidgets('menampilkan siswa, terakhir aktif, dan gagal', (tester) async {
      await _pump(
        tester,
        const ClassDetailScreen(classId: 'kelas-1'),
        teacher: FakeTeacherRepository(
          reports: {'kelas-1': _report()},
          failRates: {
            'kelas-1': const [
              ConceptFailRate(conceptId: 'K02', sessions: 4, failed: 3),
              ConceptFailRate(conceptId: 'K01', sessions: 5, failed: 1),
            ],
          },
        ),
      );

      expect(find.text('Matematika 7A'), findsOneWidget);
      expect(find.textContaining('AB12CD'), findsOneWidget);
      expect(find.text('Siswa Uji'), findsOneWidget);
      expect(find.textContaining('1/3 dikuasai'), findsOneWidget);
      expect(find.textContaining('Aktif 12/10/2026'), findsOneWidget);
      expect(find.text('Siswa'), findsOneWidget);
      expect(find.textContaining('Belum pernah aktif'), findsOneWidget);
      expect(find.textContaining('gagal 3/4 (75%)'), findsOneWidget);
    });

    testWidgets('kelas tanpa siswa dan sesi berpesan jelas', (tester) async {
      await _pump(
        tester,
        const ClassDetailScreen(classId: 'kelas-1'),
        teacher: FakeTeacherRepository(
          reports: {
            'kelas-1': const ClassReport(
              classId: 'kelas-1',
              className: 'Kelas Kosong',
              joinCode: 'ZZ0001',
              totalConcepts: 3,
            ),
          },
        ),
      );

      expect(find.textContaining('Belum ada siswa'), findsOneWidget);
      expect(find.textContaining('Belum ada data sesi'), findsOneWidget);
    });
  });

  group('StudentDetailScreen', () {
    testWidgets('menampilkan peta status per konsep', (tester) async {
      await _pump(
        tester,
        const StudentDetailScreen(
          classId: 'kelas-1',
          studentId: 'siswa-1',
        ),
        teacher: FakeTeacherRepository(
          reports: {'kelas-1': _report()},
          studentStates: {
            'siswa-1': [
              masteredState('K01'),
              learningState('K02'),
            ],
          },
        ),
      );

      expect(find.text('Siswa Uji'), findsWidgets);
      expect(find.text('Bilangan Bulat'), findsOneWidget);
      expect(find.text('Operasi Aljabar'), findsOneWidget);
      expect(find.text('Persamaan Linear'), findsOneWidget);
      expect(find.text('Dikuasai'), findsOneWidget);
      expect(find.text('Dipelajari'), findsOneWidget);
      expect(find.text('Terkunci'), findsOneWidget);
    });
  });

  group('Profil gabung kelas', () {
    testWidgets('kode salah menampilkan validasi', (tester) async {
      await _pump(tester, const StudentProfileScreen());

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -800),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('join-code-field')),
        'AB1',
      );
      await tester.tap(find.byKey(const Key('join-class-submit')));
      await tester.pump();

      expect(find.text('Kode kelas harus 6 karakter.'), findsOneWidget);
    });

    testWidgets('kode benar bergabung dan tampil di daftar', (tester) async {
      final teacher = FakeTeacherRepository();
      await _pump(
        tester,
        const StudentProfileScreen(),
        teacher: teacher,
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -800),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('join-code-field')),
        'ab12cd',
      );
      await tester.tap(find.byKey(const Key('join-class-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(teacher.joinedCodes, ['AB12CD']);
      expect(find.text('Berhasil bergabung ke kelas!'), findsOneWidget);
      expect(find.text('Matematika 7A'), findsWidgets);
    });

    testWidgets('kode tak dikenal menampilkan galat ramah', (tester) async {
      await _pump(tester, const StudentProfileScreen());

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -800),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('join-code-field')),
        'ZZZZZZ',
      );
      await tester.tap(find.byKey(const Key('join-class-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Kode kelas tidak ditemukan.'), findsOneWidget);
    });
  });
}
