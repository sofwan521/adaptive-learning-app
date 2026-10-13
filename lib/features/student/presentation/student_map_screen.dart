import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Peta konsep siswa (implementasi menyusul langkah peta konsep).
class StudentMapScreen extends StatelessWidget {
  const StudentMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Peta Konsep')),
      body: const EmptyView(
        message: 'Peta konsep segera hadir.',
        icon: Icons.map_outlined,
      ),
    );
  }
}
