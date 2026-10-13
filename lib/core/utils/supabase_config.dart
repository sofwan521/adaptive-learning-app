import '../../core/constants/app_constants.dart';

/// Konfigurasi Supabase dari --dart-define.
///
/// Contoh menjalankan:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    AppConstants.supabaseUrlKey,
    defaultValue: '',
  );
  static const String anonKey = String.fromEnvironment(
    AppConstants.supabaseAnonKeyKey,
    defaultValue: '',
  );

  /// True bila kedua kunci terisi.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
