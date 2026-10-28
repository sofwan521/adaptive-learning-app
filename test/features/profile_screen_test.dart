import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/data/datasources/reminder_store.dart';
import 'package:adaptive_learning_app/data/repositories/auth_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/gamification_repository_impl.dart';
import 'package:adaptive_learning_app/features/gamification/application/notification_scheduler.dart';
import 'package:adaptive_learning_app/features/student/presentation/student_profile_screen.dart';

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
  int scheduled = 0;
  int cancelled = 0;

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
  }) async {
    scheduled++;
  }

  @override
  Future<void> cancelDailyReminder() async {
    cancelled++;
  }
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  FakeGamificationRepository? gamification,
}) async {
  final container = ProviderContainer.test(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      gamificationRepositoryProvider.overrideWithValue(
        gamification ?? FakeGamificationRepository(),
      ),
      reminderStoreProvider.overrideWithValue(MemoryReminderStore()),
      notificationSchedulerProvider.overrideWithValue(FakeScheduler()),
    ],
    retry: (_, __) => null,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: StudentProfileScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('StudentProfileScreen', () {
    testWidgets('menampilkan streak dan lencana', (tester) async {
      final gamification = FakeGamificationRepository()
        ..badgeCodes.add('langkah-pertama');
      await _pumpProfile(tester, gamification: gamification);

      expect(find.text('Siswa Uji'), findsOneWidget);
      expect(find.textContaining('Streak 4 hari'), findsOneWidget);
      // Katalog 4 lencana tampil; yang diperoleh tak terkunci.
      expect(find.text('Langkah Pertama'), findsOneWidget);
      expect(find.text('3 Hari Beruntun'), findsOneWidget);
      expect(find.text('Konsep Pertama Dikuasai'), findsOneWidget);
      expect(find.text('Pahlawan Remedial'), findsOneWidget);
      expect(find.text('Belum diperoleh'), findsNWidgets(3));
      // Pengaturan pengingat.
      expect(find.text('Pengingat harian'), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
    });

    testWidgets('sakelar pengingat menyalakan jadwal', (tester) async {
      await _pumpProfile(tester);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('reminder-toggle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tetap di layar profil tanpa galat; jam tetap tampil.
      expect(find.text('Pengingat harian'), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
    });
  });
}
