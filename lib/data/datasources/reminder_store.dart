import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengaturan pengingat belajar harian.
class ReminderSettings extends Equatable {
  /// True bila pengingat harian aktif.
  final bool enabled;

  /// Jam (0-23) pengingat berbunyi.
  final int hour;

  /// Menit (0-59) pengingat berbunyi.
  final int minute;

  const ReminderSettings({
    this.enabled = false,
    this.hour = 19,
    this.minute = 0,
  });

  /// Label `HH:MM` untuk UI.
  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      enabled: json['enabled'] as bool? ?? false,
      hour: (json['hour'] as num? ?? 19).toInt().clamp(0, 23),
      minute: (json['minute'] as num? ?? 0).toInt().clamp(0, 59),
    );
  }

  Map<String, dynamic> toJson() {
    return {'enabled': enabled, 'hour': hour, 'minute': minute};
  }

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: (hour ?? this.hour).clamp(0, 23),
      minute: (minute ?? this.minute).clamp(0, 59),
    );
  }

  @override
  List<Object?> get props => [enabled, hour, minute];
}

/// Penyimpanan pengaturan pengingat dan penanda rekomendasi.
///
/// Seluruh operasi menelan galat agar alur utama tak terhenti.
abstract class ReminderStore {
  Future<ReminderSettings> load();
  Future<void> save(ReminderSettings settings);

  /// Kunci `hari|konsep` rekomendasi terakhir, null bila belum ada.
  Future<String?> getLastRecommendationKey();

  Future<void> setLastRecommendationKey(String key);
}

/// Implementasi [ReminderStore] memakai SharedPreferences.
class SharedPreferencesReminderStore implements ReminderStore {
  static const enabledKey = 'reminder_enabled';
  static const hourKey = 'reminder_hour';
  static const minuteKey = 'reminder_minute';
  static const lastRecommendationKey = 'reminder_last_recommendation';

  const SharedPreferencesReminderStore();

  @override
  Future<ReminderSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return ReminderSettings(
        enabled: prefs.getBool(enabledKey) ?? false,
        hour: (prefs.getInt(hourKey) ?? 19).clamp(0, 23),
        minute: (prefs.getInt(minuteKey) ?? 0).clamp(0, 59),
      );
    } catch (_) {
      return const ReminderSettings();
    }
  }

  @override
  Future<void> save(ReminderSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(enabledKey, settings.enabled);
      await prefs.setInt(hourKey, settings.hour);
      await prefs.setInt(minuteKey, settings.minute);
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Future<String?> getLastRecommendationKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(lastRecommendationKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setLastRecommendationKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(lastRecommendationKey, key);
    } catch (_) {
      // Best-effort.
    }
  }
}

final reminderStoreProvider = Provider<ReminderStore>(
  (ref) => const SharedPreferencesReminderStore(),
);
