import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/reminder_store.dart';
import 'notification_scheduler.dart';

/// Pengendali pengaturan pengingat harian (Riverpod Notifier).
///
/// - Mengaktifkan: minta izin dulu (Android 13+); bila ditolak,
///   tetap nonaktif dan kembalikan false agar UI bisa menjelaskan.
/// - Menonaktifkan: batalkan jadwal yang sudah terpasang.
/// - Mengubah jam: simpan lalu jadwalkan ulang bila aktif.
class ReminderController extends Notifier<ReminderSettings> {
  @override
  ReminderSettings build() {
    Future.microtask(_restore);
    return const ReminderSettings();
  }

  ReminderStore _store() => ref.read(reminderStoreProvider);

  NotificationScheduler _scheduler() =>
      ref.read(notificationSchedulerProvider);

  Future<void> _restore() async {
    final settings = await _store().load();
    if (!ref.mounted) return;
    state = settings;
    if (settings.enabled) {
      try {
        await _scheduler().scheduleDailyReminder(
          hour: settings.hour,
          minute: settings.minute,
        );
      } catch (_) {
        // Best-effort: jadwal dipulihkan saat Profil dibuka.
      }
    }
  }

  /// Nyalakan/matikan pengingat. Mengembalikan status aktif akhir.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final granted = await _scheduler().requestPermission();
      if (!granted) return false;
      final settings = state.copyWith(enabled: true);
      await _store().save(settings);
      state = settings;
      try {
        await _scheduler().scheduleDailyReminder(
          hour: settings.hour,
          minute: settings.minute,
        );
      } catch (_) {
        // Pengaturan tersimpan; penjadwalan dicoba lagi saat buka app.
      }
      return true;
    }
    final settings = state.copyWith(enabled: false);
    await _store().save(settings);
    state = settings;
    try {
      await _scheduler().cancelDailyReminder();
    } catch (_) {
      // Best-effort.
    }
    return false;
  }

  /// Ubah jam pengingat; jadwalkan ulang bila sedang aktif.
  Future<void> setTime(int hour, int minute) async {
    final settings = state.copyWith(hour: hour, minute: minute);
    await _store().save(settings);
    state = settings;
    if (settings.enabled) {
      try {
        await _scheduler().scheduleDailyReminder(
          hour: settings.hour,
          minute: settings.minute,
        );
      } catch (_) {
        // Best-effort.
      }
    }
  }
}

final reminderControllerProvider =
    NotifierProvider<ReminderController, ReminderSettings>(
  ReminderController.new,
);
