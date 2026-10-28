import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/core/theme/app_theme.dart';
import 'package:adaptive_learning_app/data/datasources/quiz_resume_store.dart';
import 'package:adaptive_learning_app/data/datasources/reminder_store.dart';
import 'package:adaptive_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/gamification_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/item_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/teacher_repository_impl.dart';
import 'package:adaptive_learning_app/domain/gamification/badges.dart';
import 'package:adaptive_learning_app/domain/models/class_info.dart';
import 'package:adaptive_learning_app/domain/models/item.dart';
import 'package:adaptive_learning_app/domain/models/quiz_session.dart';
import 'package:adaptive_learning_app/domain/models/response_history.dart';
import 'package:adaptive_learning_app/domain/models/student_concept_state.dart';
import 'package:adaptive_learning_app/domain/repositories/item_repository.dart';
import 'package:adaptive_learning_app/domain/repositories/teacher_repository.dart';
import 'package:adaptive_learning_app/features/auth/application/placement_provider.dart';
import 'package:adaptive_learning_app/features/auth/presentation/login_screen.dart';
import 'package:adaptive_learning_app/features/auth/presentation/register_screen.dart';
import 'package:adaptive_learning_app/features/concept/presentation/concept_screen.dart';
import 'package:adaptive_learning_app/features/gamification/application/notification_scheduler.dart';
import 'package:adaptive_learning_app/features/placement/presentation/placement_screen.dart';
import 'package:adaptive_learning_app/features/placement/presentation/placement_test_screen.dart';
import 'package:adaptive_learning_app/features/quiz/presentation/quiz_screen.dart';
import 'package:adaptive_learning_app/features/student/presentation/student_home_screen.dart';
import 'package:adaptive_learning_app/features/student/presentation/student_map_screen.dart';
import 'package:adaptive_learning_app/features/student/presentation/student_profile_screen.dart';
import 'package:adaptive_learning_app/features/student/presentation/student_progress_screen.dart';
import 'package:adaptive_learning_app/features/teacher/presentation/class_detail_screen.dart';
import 'package:adaptive_learning_app/features/teacher/presentation/student_detail_screen.dart';
import 'package:adaptive_learning_app/features/teacher/presentation/teacher_classes_screen.dart';

import '../helpers/repository_fakes.dart';

class _SmallItemRepository implements ItemRepository {
  @override
  Future<List<Item>> fetchItems(String conceptId) async {
    return [
      for (var i = 0; i < 4; i++)
        Item(
          id: 'k02-q${i + 1}',
          conceptId: 'K02',
          question: 'Soal K02 nomor ${i + 1} dengan teks cukup panjang '
              'untuk menguji pembungkusan baris pada layar sempit',
          options: const ['Jawaban A', 'Jawaban B', 'Jawaban C', 'Jawaban D'],
          correctIndex: 0,
          a: 1.0,
          b: -1.0 + i,
          explanation: 'Pembahasan K02-${i + 1}',
        ),
    ];
  }

  @override
  Future<List<Item>> fetchPlacementItems({int limit = 20}) async => [
        for (var i = 0; i < limit; i++)
          Item(
            id: 'placement-$i',
            conceptId: 'K01',
            question: 'Soal penempatan ${i + 1} dengan teks cukup panjang '
                'untuk menguji pembungkusan baris pada layar sempit',
            options: const [
              'Jawaban A',
              'Jawaban B',
              'Jawaban C',
              'Jawaban D',
            ],
            correctIndex: 0,
            a: 1.0,
            b: -2.0 + (i * 0.25),
            explanation: 'Pembahasan penempatan ${i + 1}',
          ),
      ];
}

class _SmallTeacherRepository implements TeacherRepository {
  _SmallTeacherRepository({this.empty = false, this.failure, this.report});

  final bool empty;
  final AppException? failure;
  final ClassReport? report;

  void _throwIfFailed() {
    if (failure != null) throw failure!;
  }

  @override
  Future<List<ClassInfo>> classes() async {
    _throwIfFailed();
    if (empty) return const [];
    return const [
      ClassInfo(
        id: 'kelas-1',
        teacherId: 'guru-1',
        name: 'Matematika 7A dengan nama yang cukup panjang',
        joinCode: 'AB12CD',
        memberCount: 12,
      ),
    ];
  }

  @override
  Future<ClassInfo> createClass(String name) async {
    _throwIfFailed();
    return ClassInfo(
      id: 'kelas-2',
      teacherId: 'guru-1',
      name: name,
      joinCode: 'ZZ0001',
    );
  }

  @override
  Future<ClassReport> classReport(String classId) async {
    _throwIfFailed();
    return report ??
        ClassReport(
          classId: classId,
          className: 'Matematika 7A',
          totalConcepts: 3,
        );
  }

  @override
  Future<List<ClassInfo>> myClasses() async {
    _throwIfFailed();
    return const [];
  }

  @override
  Future<String> joinClass(String code) async {
    _throwIfFailed();
    return 'kelas-1';
  }

  @override
  Future<List<ConceptFailRate>> conceptFailRates(String classId) async {
    _throwIfFailed();
    return const [];
  }

  @override
  Future<List<StudentConceptState>> memberConceptStates(
    String studentId,
  ) async {
    _throwIfFailed();
    return [];
  }
}

class _MemoryResumeStore implements QuizResumeStore {
  QuizResumeSnapshot? snapshot;

  @override
  Future<QuizResumeSnapshot?> load() async => snapshot;

  @override
  Future<void> save(QuizResumeSnapshot value) async {
    snapshot = value;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
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

ProviderContainer _container({
  Set<String>? badgeCodes,
  FakeProgressRepository? progress,
  FakeGamificationRepository? gamification,
  _SmallTeacherRepository? teacher,
}) {
  final now = DateTime.now();
  return ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      placementCompletedProvider.overrideWith((ref) => Future.value(true)),
      conceptRepositoryProvider.overrideWithValue(FakeConceptRepository()),
      progressRepositoryProvider.overrideWithValue(
        progress ??
            FakeProgressRepository(
              states: [masteredState('K01'), learningState('K02')],
              answeredToday: 3,
              sessions: [
                QuizSession(
                  id: 's1',
                  studentId: 'siswa-1',
                  conceptId: 'K01',
                  status: QuizSessionStatus.finished,
                  finalTheta: 0.4,
                  startedAt: now.subtract(const Duration(hours: 5)),
                  finishedAt: now.subtract(const Duration(hours: 4)),
                ),
              ],
              responses: [
                ResponseHistoryEntry(
                  sessionId: 's1',
                  isCorrect: true,
                  thetaAfter: 0.2,
                  answeredAt: now.subtract(const Duration(hours: 5)),
                ),
                ResponseHistoryEntry(
                  sessionId: 's1',
                  isCorrect: false,
                  thetaAfter: 0.1,
                  answeredAt: now.subtract(const Duration(hours: 4)),
                ),
              ],
            ),
      ),
      gamificationRepositoryProvider.overrideWithValue(
        gamification ??
            (FakeGamificationRepository()
              ..badgeCodes.addAll(badgeCodes ?? const <String>{})),
      ),
      itemRepositoryProvider.overrideWithValue(_SmallItemRepository()),
      quizResumeStoreProvider.overrideWithValue(_MemoryResumeStore()),
      reminderStoreProvider.overrideWithValue(_MemoryReminderStore()),
      notificationSchedulerProvider.overrideWithValue(_FakeScheduler()),
      teacherRepositoryProvider.overrideWithValue(
        teacher ?? _SmallTeacherRepository(),
      ),
    ],
    retry: (_, __) => null,
  );
}

Future<void> _pumpNarrow(
  WidgetTester tester,
  Widget screen, {
  double textScale = 1.0,
  ThemeData? theme,
  Set<String>? badgeCodes,
  FakeProgressRepository? progress,
  FakeGamificationRepository? gamification,
  _SmallTeacherRepository? teacher,
}) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: _container(
        badgeCodes: badgeCodes,
        progress: progress,
        gamification: gamification,
        teacher: teacher,
      ),
      child: MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Gulir semua panel gulir utama sampai bawah agar konten lazy
/// ikut ter-build dan diukur (grid dalam tak ikut digulir).
Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

Future<void> _scrollAll(WidgetTester tester) async {
  final primary = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.physics is! NeverScrollableScrollPhysics,
  );
  for (var i = 0; i < primary.evaluate().length; i++) {
    await tester.drag(
      find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.physics is! NeverScrollableScrollPhysics,
          )
          .at(i),
      const Offset(0, -2000),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('layar 360 dp tanpa overflow', () {
    testWidgets('masuk', (tester) async {
      await _pumpNarrow(tester, const LoginScreen());

      expect(find.text('Masuk'), findsWidgets);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kuis', (tester) async {
      await _pumpNarrow(tester, const QuizScreen(conceptId: 'K02'));

      expect(find.text('Soal 1 dari 4'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kuis sampai hasil', (tester) async {
      await _pumpNarrow(tester, const QuizScreen(conceptId: 'K02'));

      for (var i = 0; i < 4; i++) {
        await _tapVisible(tester, find.byKey(const Key('quiz-option-0')));
        await tester.pump();
        await _tapVisible(tester, find.byKey(const Key('quiz-answer')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await _tapVisible(tester, find.byKey(const Key('quiz-next')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byKey(const Key('quiz-result-title')), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('beranda', (tester) async {
      await _pumpNarrow(tester, const StudentHomeScreen());

      expect(find.text('Halo, Siswa Uji!'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('progres', (tester) async {
      await _pumpNarrow(tester, const StudentProgressScreen());

      expect(find.text('Ringkasan'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('peta', (tester) async {
      await _pumpNarrow(tester, const StudentMapScreen());

      expect(find.text('Peta Konsep'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('profil', (tester) async {
      await _pumpNarrow(tester, const StudentProfileScreen());

      expect(find.text('Siswa Uji'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('profil dengan text scale 1.3', (tester) async {
      await _pumpNarrow(
        tester,
        const StudentProfileScreen(),
        theme: AppTheme.light(),
        textScale: 1.3,
        badgeCodes: {for (final badge in kAppBadges) badge.code},
      );

      expect(find.text('Konsep Pertama Dikuasai'), findsOneWidget);
      expect(
        find.text('Menguasai konsep lewat jalur remedial.'),
        findsOneWidget,
      );
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('materi', (tester) async {
      await _pumpNarrow(tester, const ConceptScreen(conceptId: 'K01'));

      expect(find.text('Materi'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('daftar kelas guru', (tester) async {
      await _pumpNarrow(tester, const TeacherClassesScreen());

      expect(find.textContaining('Matematika 7A'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('daftar akun', (tester) async {
      await _pumpNarrow(tester, const RegisterScreen());

      expect(find.text('Daftar'), findsWidgets);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pengantar placement', (tester) async {
      await _pumpNarrow(tester, const PlacementScreen());

      expect(find.textContaining('Tes Penempatan'), findsWidgets);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('soal placement', (tester) async {
      await _pumpNarrow(tester, const PlacementTestScreen());

      expect(find.textContaining('Soal 1 dari 12'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('progres kosong', (tester) async {
      await _pumpNarrow(
        tester,
        const StudentProgressScreen(),
        progress: FakeProgressRepository(),
      );

      expect(find.text('Belum ada progres'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('beranda galat', (tester) async {
      await _pumpNarrow(
        tester,
        const StudentHomeScreen(),
        progress: FakeProgressRepository()
          ..failure = const AppException('Gagal memuat progres uji.'),
      );

      expect(find.text('Gagal memuat progres uji.'), findsWidgets);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('profil galat gamifikasi', (tester) async {
      await _pumpNarrow(
        tester,
        const StudentProfileScreen(),
        gamification: FakeGamificationRepository()
          ..failure = const AppException('Gagal memuat gamifikasi uji.'),
      );

      expect(find.text('Gagal memuat gamifikasi uji.'), findsWidgets);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('daftar kelas kosong', (tester) async {
      await _pumpNarrow(
        tester,
        const TeacherClassesScreen(),
        teacher: _SmallTeacherRepository(empty: true),
      );

      expect(find.textContaining('Belum ada kelas'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('daftar kelas galat', (tester) async {
      await _pumpNarrow(
        tester,
        const TeacherClassesScreen(),
        teacher: _SmallTeacherRepository(
          failure: const AppException('Gagal memuat kelas uji.'),
        ),
      );

      expect(find.text('Gagal memuat kelas uji.'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail kelas panjang', (tester) async {
      await _pumpNarrow(
        tester,
        const ClassDetailScreen(classId: 'kelas-1'),
        teacher: _SmallTeacherRepository(
          report: ClassReport(
            classId: 'kelas-1',
            className: 'Matematika 7A dengan nama kelas yang sangat panjang',
            joinCode: 'AB12CD',
            totalConcepts: 8,
            members: [
              ClassMemberReport(
                studentId: 'siswa-1',
                fullName: 'Nama Siswa Yang Sangat Panjang Sekali Untuk Layar',
                percent: 99.9,
                masteredCount: 8,
                lastActive: DateTime(2026, 10, 12),
              ),
            ],
          ),
        ),
      );

      expect(find.textContaining('Matematika 7A'), findsOneWidget);
      expect(find.textContaining('Nama Siswa'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail kelas galat', (tester) async {
      await _pumpNarrow(
        tester,
        const ClassDetailScreen(classId: 'kelas-1'),
        teacher: _SmallTeacherRepository(
          failure: const AppException('Gagal memuat detail kelas uji.'),
        ),
      );

      expect(find.text('Gagal memuat detail kelas uji.'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detail siswa', (tester) async {
      await _pumpNarrow(
        tester,
        const StudentDetailScreen(
          classId: 'kelas-1',
          studentId: 'siswa-1',
        ),
        teacher: _SmallTeacherRepository(
          report: ClassReport(
            classId: 'kelas-1',
            className: 'Matematika 7A',
            joinCode: 'AB12CD',
            totalConcepts: 8,
            members: [
              ClassMemberReport(
                studentId: 'siswa-1',
                fullName: 'Nama Siswa Yang Sangat Panjang Sekali',
                percent: 99.9,
                masteredCount: 8,
                lastActive: DateTime(2026, 10, 12),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Detail Siswa'), findsOneWidget);
      await _scrollAll(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
