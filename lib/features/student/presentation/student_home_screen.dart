import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';

/// Beranda siswa (implementasi menyusul langkah student).
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;
    final name = (profile?.fullName ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda Siswa')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name.isEmpty ? 'Halo!' : 'Halo, $name!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Beranda belajarmu segera hadir.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
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
