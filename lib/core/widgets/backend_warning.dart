import 'package:flutter/material.dart';

import '../utils/supabase_config.dart';

/// Spanduk peringatan bila backend Supabase belum dikonfigurasi.
///
/// Murni UI — hanya membaca [SupabaseConfig.isConfigured]. Dipakai di
/// layar Masuk dan Daftar agar kegagalan konfigurasi (`flutter run`
/// tanpa `--dart-define`) terlihat jelas, bukan sekadar memantul
/// kembali ke halaman login.
class BackendWarning extends StatelessWidget {
  const BackendWarning({super.key});

  @override
  Widget build(BuildContext context) {
    if (SupabaseConfig.isConfigured) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('backend-warning'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Backend belum dikonfigurasi. Jalankan aplikasi dengan '
              '--dart-define SUPABASE_URL dan SUPABASE_ANON_KEY.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
