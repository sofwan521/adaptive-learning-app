import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/data/datasources/reminder_store.dart';
import 'package:adaptive_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/gamification_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/features/auth/application/placement_provider.dart';
import 'package:adaptive_learning_app/features/gamification/application/notification_scheduler.dart';
import 'package:adaptive_learning_app/features/student/presentation/student_home_screen.dart';

import '../helpers/repository_fakes.dart';

class MemoryReminderStore implements ReminderStore {
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

class FakeScheduler implements NotificationScheduler {
  final List<String> recommendations = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showRecommendation({required String conceptName}) async {
    recommendations.add(conceptName);
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> cancelDailyReminder() async {}
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required MemoryReminderStore store,
  required FakeScheduler scheduler,
}) async {
  final container = ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      placementCompletedProvider.overrideWith((ref) => Future.value(true)),
      conceptRepositoryProvider.overrideWithValue(FakeConceptRepository()),
      progressRepositoryProvider.overrideWithValue(
        FakeProgressRepository(
          states: [masteredState('K01'), learningState('K02')],
          answeredToday: 3,
        ),
      ),
      gamificationRepositoryProvider.overrideWithValue(
        FakeGamificationRepository(),
      ),
      reminderStoreProvider.overrideWithValue(store),
      notificationSchedulerProvider.overrideWithValue(scheduler),
    ],
    retry: (_, __) => null,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: StudentHomeScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('pemicu rekomendasi', () {
    testWidgets('menampilkan anjuran konsep Terbuka sekali sehari',
        (tester) async {
      final store = MemoryReminderStore();
      final scheduler = FakeScheduler();

      await _pumpHome(tester, store: store, scheduler: scheduler);

      expect(scheduler.recommendations, ['Operasi Aljabar']);
      expect(store.lastKey, endsWith('|K02'));
    });

    testWidgets('tidak mengulang untuk kunci yang sama', (tester) async {
      final store = MemoryReminderStore();
      final scheduler = FakeScheduler();

      await _pumpHome(tester, store: store, scheduler: scheduler);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(scheduler.recommendations, hasLength(1));
    });
  });
}
