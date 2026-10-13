import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Pengingat harian pada jam pilihan dan rekomendasi konsep Terbuka.
///
/// Kontrak ini diabstraksi agar mudah diuji (implementasi asli
/// memakai plugin, uji memakai palsu dalam-memori).
abstract class NotificationScheduler {
  /// Siapkan plugin dan basis data zona waktu (idempoten).
  Future<void> initialize();

  /// Minta izin notifikasi (penting untuk Android 13+).
  ///
  /// Mengembalikan true bila diizinkan.
  Future<bool> requestPermission();

  /// Tampilkan anjuran belajar konsep [conceptName] yang Terbuka.
  Future<void> showRecommendation({required String conceptName});

  /// Jadwalkan pengingat harian pada [hour]:[minute], berulang tiap hari.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  });

  /// Batalkan pengingat harian (dipanggil saat dimatikan).
  Future<void> cancelDailyReminder();
}

/// Kunci penyusun rekomendasi harian: `hari|konsep`.
String recommendationKey({required DateTime today, required String conceptId}) {
  return '${today.year}-${today.month}-${today.day}|$conceptId';
}

/// True bila rekomendasi [key] belum ditampilkan hari ini.
bool shouldShowRecommendation({required String? lastKey, required String key}) {
  return lastKey != key;
}

/// Kejadian lokal berikutnya pada [hour]:[minute].
///
/// Hari ini bila jamnya belum lewat, besok bila sudah. Fungsi murni
/// (tanpa plugin) sehingga mudah diuji.
DateTime nextDailyOccurrence({
  required DateTime now,
  required int hour,
  required int minute,
}) {
  var next = DateTime(now.year, now.month, now.day, hour, minute);
  if (!next.isAfter(now)) {
    next = next.add(const Duration(days: 1));
  }
  return next;
}

/// Implementasi [NotificationScheduler] memakai plugin.
class FlutterNotificationScheduler implements NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const int dailyReminderId = 1001;
  static const int recommendationId = 1002;
  static const String channelId = 'belajar_harian';
  static const String channelName = 'Pengingat Belajar';

  FlutterNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
      );
      _initialized = true;
    } catch (_) {
      // Notifikasi best-effort; aplikasi tetap berjalan tanpanya.
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macos != null) {
        return await macos.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }

  @override
  Future<void> showRecommendation({required String conceptName}) async {
    try {
      await initialize();
      await _plugin.show(
        id: recommendationId,
        title: 'Lanjut belajar yuk!',
        body: 'Konsep $conceptName sudah Terbuka dan menunggumu.',
        notificationDetails: _details(),
      );
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    try {
      await initialize();
      // Konversi waktu dinding lokal ke UTC: pengulangan harian memakai
      // komponen waktu dari zona lokasi jadwal. Untuk zona offset-tetap
      // (mis. WIB) hasilnya tepat; zona DST dapat bergeser sejam.
      final next = nextDailyOccurrence(
        now: DateTime.now(),
        hour: hour,
        minute: minute,
      );
      final scheduled = tz.TZDateTime.from(next.toUtc(), tz.UTC);
      await _plugin.zonedSchedule(
        id: dailyReminderId,
        title: 'Waktunya belajar!',
        body: 'Kerjakan kuis hari ini untuk menjaga streak-mu.',
        scheduledDate: scheduled,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(id: dailyReminderId);
    } catch (_) {
      // Best-effort.
    }
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>(
  (ref) => FlutterNotificationScheduler(),
);
