import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../application/placement_controller.dart';

/// Hasil placement test: tingkat kemampuan bahasa awam,
/// ringkasan jawaban, dan tombol ke Beranda.
class PlacementResultScreen extends ConsumerWidget {
  const PlacementResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(placementControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    if (state.phase != PlacementPhase.done) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hasil Tes')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Expanded(
                child: EmptyView(
                  message: 'Belum ada hasil tes penempatan.',
                  icon: Icons.assignment_outlined,
                ),
              ),
              AppButton(
                label: 'Ke Beranda',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.go(AppRoutes.studentHome),
              ),
            ],
          ),
        ),
      );
    }

    final level = placementLevelName(state.theta);

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Tes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tingkat kemampuanmu: $level',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Skor kemampuan (theta): ${state.theta.toStringAsFixed(2)}',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  _ResultRow(
                    icon: Icons.check_circle_outline,
                    text: 'Jawaban benar: '
                        '${state.correctCount} dari ${state.total}',
                  ),
                  const SizedBox(height: 8),
                  _ResultRow(
                    icon: Icons.workspace_premium_outlined,
                    text: 'Konsep langsung dikuasai: '
                        '${state.masteredIds.length}',
                  ),
                  const SizedBox(height: 8),
                  const _ResultRow(
                    icon: Icons.map_outlined,
                    text: 'Peta belajarmu sudah disiapkan.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              key: const Key('placement-to-home'),
              label: 'Mulai Belajar',
              icon: Icons.arrow_forward,
              onPressed: () => context.go(AppRoutes.studentHome),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ResultRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
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
