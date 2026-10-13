import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/supabase_config.dart';
import 'data/datasources/supabase_service.dart';

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

  runApp(const ProviderScope(child: AdaptiLearnApp()));
}
