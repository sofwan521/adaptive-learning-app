import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/supabase_config.dart';
import 'data/datasources/reminder_store.dart';
import 'data/datasources/supabase_service.dart';
import 'features/gamification/application/notification_scheduler.dart';

/// Entry point AdaptiLearn.
///
/// Supabase diinisialisasi dari `--dart-define`
/// (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
/// Bila kunci kosong, aplikasi tetap jalan (layar kosong) tanpa backend.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await SupabaseService.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // Pulihkan jadwal pengingat harian (mis. setelah reboot).
  await _restoreDailyReminder();

  runApp(const ProviderScope(child: AdaptiLearnApp()));
}

/// Jadwalkan ulang pengingat bila masih aktif. Best-effort.
Future<void> _restoreDailyReminder() async {
  try {
    final settings = await const SharedPreferencesReminderStore().load();
    if (!settings.enabled) return;
    final scheduler = FlutterNotificationScheduler();
    await scheduler.initialize();
    await scheduler.scheduleDailyReminder(
      hour: settings.hour,
      minute: settings.minute,
    );
  } catch (_) {
    // Notifikasi best-effort; aplikasi tetap berjalan tanpanya.
  }
}
