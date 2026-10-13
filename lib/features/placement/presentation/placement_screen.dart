import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../application/placement_controller.dart';

/// Pengantar placement test: penjelasan + tombol mulai.
class PlacementScreen extends ConsumerWidget {
  const PlacementScreen({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(placementControllerProvider.notifier);
    await controller.start();
    final state = ref.read(placementControllerProvider);
    if (!context.mounted) return;
    if (state.items.isNotEmpty) {
      context.push(AppRoutes.placementTest);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              state.errorMessage ?? 'Gagal memuat soal. Coba lagi.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(placementControllerProvider).phase;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tes Penempatan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ukur kemampuan awalmu',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Jawab 12 soal pilihan ganda. Tingkat kesulitan '
              'menyesuaikan jawabanmu, dan tiap jawaban langsung '
              'mendapat pembahasan.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IntroPoint(
                    icon: Icons.tune,
                    text: 'Soal adaptif: makin tepat, makin menantang.',
                  ),
                  SizedBox(height: 8),
                  _IntroPoint(
                    icon: Icons.check_circle_outline,
                    text: 'Umpan balik benar atau salah beserta pembahasan.',
                  ),
                  SizedBox(height: 8),
                  _IntroPoint(
                    icon: Icons.map_outlined,
                    text: 'Hasil menentukan peta belajarmu.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              key: const Key('placement-start'),
              label: 'Mulai Tes Penempatan',
              icon: Icons.play_arrow,
              isLoading: phase == PlacementPhase.loading,
              onPressed: phase == PlacementPhase.loading
                  ? null
                  : () => _start(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IntroPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
