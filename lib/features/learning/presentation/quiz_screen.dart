import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../../student/application/student_providers.dart';

/// Layar kuis per konsep (implementasi menyusul langkah kuis).
///
/// Dari Beranda cukup 1 ketukan tombol "Mulai Kuis" untuk sampai ke sini.
class QuizScreen extends ConsumerWidget {
  final String conceptId;

  const QuizScreen({super.key, required this.conceptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(knowledgeGraphProvider).when(
          data: (graph) {
            try {
              return graph.concept(conceptId).name;
            } catch (_) {
              return 'Kuis';
            }
          },
          loading: () => 'Kuis',
          error: (_, __) => 'Kuis',
        );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const EmptyView(
        message: 'Kuis segera hadir.',
        icon: Icons.quiz_outlined,
      ),
    );
  }
}
