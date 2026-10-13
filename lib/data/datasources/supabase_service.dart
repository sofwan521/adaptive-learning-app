import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pembungkus klien Supabase.
///
/// Inisialisasi sekali dari `main()` memakai `--dart-define`
/// (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). Repository menerima
/// [SupabaseClient] lewat konstruktor agar mudah diuji.
abstract final class SupabaseService {
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  /// True bila [initialize] sudah pernah dipanggil.
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Klien global. Hanya valid setelah [initialize].
  static SupabaseClient get client => Supabase.instance.client;
}

/// Klien Supabase untuk repository.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseService.client,
);
