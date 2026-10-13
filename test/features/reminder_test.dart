import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/data/datasources/reminder_store.dart';
import 'package:adaptive_learning_app/features/gamification/application/notification_scheduler.dart';
import 'package:adaptive_learning_app/features/gamification/application/reminder_controller.dart';

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
  bool permissionGranted = true;
  int permissionRequests = 0;
  final List<({int hour, int minute})> scheduled = [];
  int cancellations = 0;
  final List<String> recommendations = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<void> showRecommendation({required String conceptName}) async {
    recommendations.add(conceptName);
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    scheduled.add((hour: hour, minute: minute));
  }

  @override
  Future<void> cancelDailyReminder() async {
    cancellations++;
  }
}

ProviderContainer _container({
  required MemoryReminderStore store,
  required FakeScheduler scheduler,
}) {
  return ProviderContainer.test(
    overrides: [
      reminderStoreProvider.overrideWithValue(store),
      notificationSchedulerProvider.overrideWithValue(scheduler),
    ],
    retry: (_, __) => null,
  );
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('ReminderSettings', () {
    test('default mati pukul 19:00', () {
      const settings = ReminderSettings();
      expect(settings.enabled, isFalse);
      expect(settings.label, '19:00');
    });

    test('label berformat HH:MM', () {
      expect(
        const ReminderSettings(hour: 7, minute: 5).label,
        '07:05',
      );
    });

    test('fromJson menjepit jam di luar rentang', () {
      final settings = ReminderSettings.fromJson(
        const {'enabled': true, 'hour': 30, 'minute': -5},
      );
      expect(settings.enabled, isTrue);
      expect(settings.hour, 23);
      expect(settings.minute, 0);
    });

    test('pulang-pergi json utuh', () {
      const settings = ReminderSettings(
        enabled: true,
        hour: 6,
        minute: 30,
      );
      final restored = ReminderSettings.fromJson(settings.toJson());
      expect(restored, settings);
    });
  });

  group('nextDailyOccurrence', () {
    test('jam yang belum lewat berarti hari ini', () {
      final next = nextDailyOccurrence(
        now: DateTime(2026, 10, 13, 8),
        hour: 19,
        minute: 0,
      );
      expect(next, DateTime(2026, 10, 13, 19));
    });

    test('jam yang sudah lewat berarti besok', () {
      final next = nextDailyOccurrence(
        now: DateTime(2026, 10, 13, 20, 15),
        hour: 19,
        minute: 0,
      );
      expect(next, DateTime(2026, 10, 14, 19));
    });

    test('tepat pada menitnya berarti besok', () {
      final next = nextDailyOccurrence(
        now: DateTime(2026, 10, 13, 19, 0),
        hour: 19,
        minute: 0,
      );
      expect(next, DateTime(2026, 10, 14, 19));
    });
  });

  group('shouldShowRecommendation', () {
    test('tampil bila kunci hari ini belum ada', () {
      expect(
        shouldShowRecommendation(lastKey: null, key: '2026-10-13|K02'),
        isTrue,
      );
      expect(
        shouldShowRecommendation(
          lastKey: '2026-10-12|K02',
          key: '2026-10-13|K02',
        ),
        isTrue,
      );
    });

    test('tidak tampil dua kali untuk kunci yang sama', () {
      expect(
        shouldShowRecommendation(
          lastKey: '2026-10-13|K02',
          key: '2026-10-13|K02',
        ),
        isFalse,
      );
    });
  });

  group('ReminderController', () {
    test('memulihkan pengaturan tersimpan saat dibuka', () async {
      final store = MemoryReminderStore()
        ..settings = const ReminderSettings(
          enabled: true,
          hour: 7,
          minute: 30,
        );
      final scheduler = FakeScheduler();
      final container = _container(store: store, scheduler: scheduler);

      container.read(reminderControllerProvider);
      await _settle();

      final state = container.read(reminderControllerProvider);
      expect(state.enabled, isTrue);
      expect(state.label, '07:30');
      // Jadwal dipulihkan (mis. setelah reboot).
      expect(scheduler.scheduled, const [(hour: 7, minute: 30)]);
    });

    test('menyalakan meminta izin lalu menjadwalkan', () async {
      final store = MemoryReminderStore();
      final scheduler = FakeScheduler();
      final container = _container(store: store, scheduler: scheduler);
      final controller =
          container.read(reminderControllerProvider.notifier);
      await _settle();

      final result = await controller.setEnabled(true);

      expect(result, isTrue);
      expect(scheduler.permissionRequests, 1);
      expect(scheduler.scheduled, [(hour: 19, minute: 0)]);
      expect(container.read(reminderControllerProvider).enabled, isTrue);
      expect(store.settings.enabled, isTrue);
    });

    test('izin ditolak berarti tetap mati tanpa jadwal', () async {
      final store = MemoryReminderStore();
      final scheduler = FakeScheduler()..permissionGranted = false;
      final container = _container(store: store, scheduler: scheduler);
      final controller =
          container.read(reminderControllerProvider.notifier);
      await _settle();

      final result = await controller.setEnabled(true);

      expect(result, isFalse);
      expect(scheduler.scheduled, isEmpty);
      expect(container.read(reminderControllerProvider).enabled, isFalse);
      expect(store.settings.enabled, isFalse);
    });

    test('mematikan membatalkan jadwal tersimpan', () async {
      final store = MemoryReminderStore()
        ..settings = const ReminderSettings(enabled: true);
      final scheduler = FakeScheduler();
      final container = _container(store: store, scheduler: scheduler);
      final controller =
          container.read(reminderControllerProvider.notifier);
      await _settle();

      final result = await controller.setEnabled(false);

      expect(result, isFalse);
      expect(scheduler.cancellations, 1);
      expect(container.read(reminderControllerProvider).enabled, isFalse);
    });

    test('ubah jam menjadwalkan ulang bila aktif', () async {
      final store = MemoryReminderStore();
      final scheduler = FakeScheduler();
      final container = _container(store: store, scheduler: scheduler);
      final controller =
          container.read(reminderControllerProvider.notifier);
      await _settle();
      await controller.setEnabled(true);
      scheduler.scheduled.clear();

      await controller.setTime(6, 45);

      expect(scheduler.scheduled, [(hour: 6, minute: 45)]);
      expect(container.read(reminderControllerProvider).label, '06:45');
    });
  });
}
