import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adaptive_learning_app/app.dart';
import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/data/datasources/reminder_store.dart';
import 'package:adaptive_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/gamification_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/item_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/domain/models/ability_estimate.dart';
import 'package:adaptive_learning_app/domain/models/item.dart';
import 'package:adaptive_learning_app/domain/models/student_concept_state.dart';
import 'package:adaptive_learning_app/domain/repositories/item_repository.dart';
import 'package:adaptive_learning_app/features/auth/application/placement_provider.dart';
import 'package:adaptive_learning_app/features/gamification/application/notification_scheduler.dart';

import '../helpers/repository_fakes.dart';

class _PlacementItemRepository implements ItemRepository {
  AppException? failure;

  @override
  Future<List<Item>> fetchPlacementItems({int limit = 20}) async {
    if (failure != null) throw failure!;
    return [
      for (var i = 0; i < limit; i++)
        Item(
          id: 'placement-$i',
          conceptId: 'K01',
          question: 'Soal penempatan ${i + 1}',
          options: const ['Benar', 'Salah', 'Mungkin', 'Tidak tahu'],
          correctIndex: 0,
          a: 1.0,
          b: -2.0 + (i * 0.25),
          explanation: 'Pembahasan penempatan ${i + 1}',
        ),
    ];
  }

  @override
  Future<List<Item>> fetchItems(String conceptId) async => [
        for (var i = 0; i < 4; i++)
          Item(
            id: '$conceptId-quiz-$i',
            conceptId: conceptId,
            question: 'Soal kuis ${i + 1}',
            options: const ['Benar', 'Salah', 'Mungkin', 'Tidak tahu'],
            correctIndex: 0,
            a: 1.0,
            b: -1.0 + i,
            explanation: 'Pembahasan kuis ${i + 1}',
          ),
      ];
}

class _PersistingProgressRepository extends FakeProgressRepository {
  final Map<String, StudentConceptState> savedStates = {};
  AbilityEstimate? savedAbility;
  String? finishedSessionId;

  @override
  Future<AbilityEstimate> loadAbility() async =>
      savedAbility ?? const AbilityEstimate(theta: 0, se: 1);

  @override
  Future<void> saveAbility(AbilityEstimate estimate) async {
    savedAbility = estimate;
  }

  @override
  Future<List<StudentConceptState>> loadConceptStates() async =>
      savedStates.values.toList();

  @override
  Future<void> upsertConceptState(StudentConceptState state) async {
    savedStates[state.conceptId] = state;
  }

  @override
  Future<String> createSession({String? conceptId}) async => 'placement-1';

  @override
  Future<void> finishSession({
    required String sessionId,
    required double finalTheta,
  }) async {
    finishedSessionId = sessionId;
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

class _NoopScheduler implements NotificationScheduler {
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
  required _PlacementItemRepository items,
  required _PersistingProgressRepository progress,
  bool? placementDone,
}) {
  return ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(profile: null),
      ),
      if (placementDone != null)
        placementCompletedProvider.overrideWith(
          (ref) => Future.value(placementDone),
        ),
      conceptRepositoryProvider.overrideWithValue(FakeConceptRepository()),
      progressRepositoryProvider.overrideWithValue(progress),
      gamificationRepositoryProvider.overrideWithValue(
        FakeGamificationRepository(),
      ),
      itemRepositoryProvider.overrideWithValue(items),
      reminderStoreProvider.overrideWithValue(_MemoryReminderStore()),
      notificationSchedulerProvider.overrideWithValue(_NoopScheduler()),
    ],
    retry: (_, __) => null,
  );
}

Future<void> _pumpApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const AdaptiLearnApp(),
    ),
  );
  await _pumpFrames(tester);
}

Future<void> _pumpFrames(WidgetTester tester, [int count = 12]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _login(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('login-email')),
    'siswa@contoh.id',
  );
  await tester.enterText(
    find.byKey(const Key('login-password')),
    'sandi123',
  );
  await tester.tap(find.byKey(const Key('login-submit')));
  await _pumpFrames(tester, 20);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('siswa menyelesaikan placement lalu kembali ke beranda',
      (tester) async {
    final items = _PlacementItemRepository();
    final progress = _PersistingProgressRepository();
    await _pumpApp(tester, _container(items: items, progress: progress));

    await _login(tester);
    expect(find.text('Tes Penempatan'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('placement-start')));
    await _pumpFrames(tester, 20);
    expect(find.textContaining('Soal 1 dari 12'), findsOneWidget);

    for (var i = 0; i < 12; i++) {
      await _tapVisible(tester, find.byKey(const Key('placement-option-0')));
      await tester.pump();
      await _tapVisible(tester, find.byKey(const Key('placement-answer')));
      await _pumpFrames(tester, 4);
      await _tapVisible(tester, find.byKey(const Key('placement-next')));
      await _pumpFrames(tester, 8);
    }

    expect(find.text('Hasil Tes'), findsOneWidget);
    expect(find.textContaining('%'), findsWidgets);
    expect(progress.savedStates, isNotEmpty);
    expect(progress.finishedSessionId, 'placement-1');

    await _tapVisible(tester, find.byKey(const Key('placement-to-home')));
    await _pumpFrames(tester, 20);

    expect(find.text('Halo, Siswa Uji!'), findsOneWidget);
  });

  testWidgets('galat memuat soal placement bisa dicoba lagi', (tester) async {
    final items = _PlacementItemRepository()
      ..failure = const AppException('Soal placement gagal dimuat.');
    await _pumpApp(
      tester,
      _container(items: items, progress: _PersistingProgressRepository()),
    );

    await _login(tester);
    await _tapVisible(tester, find.byKey(const Key('placement-start')));
    await _pumpFrames(tester, 20);

    expect(find.text('Soal placement gagal dimuat.'), findsOneWidget);

    items.failure = null;
    await _tapVisible(tester, find.byKey(const Key('placement-start')));
    await _pumpFrames(tester, 20);

    expect(find.textContaining('Soal 1 dari 12'), findsOneWidget);
  });

  testWidgets('siswa menjawab kuis sampai melihat hasil', (tester) async {
    final progress = _PersistingProgressRepository();
    progress.savedStates['K01'] = masteredState('K01');
    progress.savedStates['K02'] = learningState('K02');
    await _pumpApp(
      tester,
      _container(
        items: _PlacementItemRepository(),
        progress: progress,
        placementDone: true,
      ),
    );

    await _login(tester);
    expect(find.text('Halo, Siswa Uji!'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('home-start-quiz')));
    await _pumpFrames(tester, 20);
    expect(find.textContaining('Soal 1 dari 4'), findsOneWidget);

    for (var i = 0; i < 4; i++) {
      await _tapVisible(tester, find.byKey(const Key('quiz-option-0')));
      await tester.pump();
      await _tapVisible(tester, find.byKey(const Key('quiz-answer')));
      await _pumpFrames(tester, 4);
      await _tapVisible(tester, find.byKey(const Key('quiz-next')));
      await _pumpFrames(tester, 10);
    }

    expect(find.byKey(const Key('quiz-result-title')), findsOneWidget);
    expect(find.textContaining('Skor kemampuan:'), findsOneWidget);
  });
}
