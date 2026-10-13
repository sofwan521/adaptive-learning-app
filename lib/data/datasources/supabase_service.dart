import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Layanan inisialisasi Supabase.
///
/// Dipanggil sekali dari `main()` bila kredensial tersedia.
abstract final class SupabaseService {
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  /// Client Supabase global. Hanya valid setelah [initialize].
  static SupabaseClient get client => Supabase.instance.client;
}

/// Provider status konfigurasi Supabase (untuk UI).
final supabaseReadyProvider = Provider<bool>((ref) => false);
