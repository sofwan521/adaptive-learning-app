import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../application/home_providers.dart';

/// Layar awal kosong AdaptiLearn.
///
/// Tanpa logika bisnis — hanya tampilan (Bahasa Indonesia).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(appTitleProvider);
    final welcome = ref.watch(welcomeMessageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                welcome,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Layar awal siap. Struktur proyek terinisialisasi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Lihat Galeri Komponen',
                variant: AppButtonVariant.secondary,
                icon: Icons.palette_outlined,
                onPressed: () => context.push(AppRoutes.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
