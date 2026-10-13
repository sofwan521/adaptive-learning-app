import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';

/// Progres belajar siswa (implementasi menyusul langkah progres).
class StudentProgressScreen extends StatelessWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progres')),
      body: const EmptyView(
        message: 'Grafik progres segera hadir.',
        icon: Icons.show_chart_outlined,
      ),
    );
  }
}
