import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../../auth/application/auth_controller.dart';

/// Daftar kelas guru (implementasi menyusul langkah teacher).
class TeacherClassesScreen extends ConsumerWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelas Saya')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Expanded(
              child: EmptyView(
                message: 'Belum ada kelas. Daftar kelas segera hadir.',
                icon: Icons.class_outlined,
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
