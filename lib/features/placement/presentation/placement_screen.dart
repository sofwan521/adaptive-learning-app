import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';

/// Tempat tes penempatan (implementasi menyusul langkah placement).
class PlacementScreen extends ConsumerWidget {
  const PlacementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tes Penempatan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Expanded(
              child: EmptyView(
                message: 'Tes penempatan segera hadir.',
                icon: Icons.quiz_outlined,
              ),
            ),
            AppButton(
              label: 'Keluar',
              variant: AppButtonVariant.secondary,
              icon: Icons.logout,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
