import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../application/placement_controller.dart';

/// Layar pengerjaan placement test: progres, kartu soal, opsi,
/// tombol jawab, dan umpan balik beserta pembahasan.
class PlacementTestScreen extends ConsumerStatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  ConsumerState<PlacementTestScreen> createState() =>
      _PlacementTestScreenState();
}

class _PlacementTestScreenState extends ConsumerState<PlacementTestScreen> {
  @override
  void initState() {
    super.initState();
    final state = ref.read(placementControllerProvider);
    if (state.items.isEmpty &&
        state.phase != PlacementPhase.loading &&
        state.phase != PlacementPhase.finishing) {
      Future.microtask(
        () => ref.read(placementControllerProvider.notifier).start(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PlacementState>(placementControllerProvider, (previous, next) {
      if (next.phase == PlacementPhase.done &&
          previous?.phase != PlacementPhase.done) {
        context.go(AppRoutes.placementResult);
      }
    });
    final state = ref.watch(placementControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tes Penempatan')),
      body: switch (state.phase) {
        PlacementPhase.loading => const LoadingView(
            message: 'Memuat soal…',
          ),
        PlacementPhase.finishing => const LoadingView(
            message: 'Menyimpan hasil…',
          ),
        PlacementPhase.error => ErrorView(
            message: state.errorMessage ?? 'Terjadi kesalahan.',
            onRetry: () =>
                ref.read(placementControllerProvider.notifier).retry(),
          ),
        PlacementPhase.done => const LoadingView(
            message: 'Menyiapkan hasil…',
          ),
        PlacementPhase.intro => ErrorView(
            message: 'Sesi belum dimulai.',
            onRetry: () =>
                ref.read(placementControllerProvider.notifier).start(),
          ),
        PlacementPhase.answering || PlacementPhase.feedback =>
          _QuestionBody(state: state),
      },
    );
  }
}

class _QuestionBody extends ConsumerWidget {
  final PlacementState state;

  const _QuestionBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(placementControllerProvider.notifier);
    final item = state.currentItem;
    if (item == null) {
      return ErrorView(
        message: 'Soal tidak tersedia.',
        onRetry: () => controller.retry(),
      );
    }
    final showingFeedback = state.phase == PlacementPhase.feedback;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: state.total == 0
                      ? 0
                      : state.questionNumber / state.total,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Soal ${state.questionNumber} dari ${state.total}',
                style: textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Text(item.question, style: textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < item.options.length; i++)
            _OptionTile(
              key: Key('placement-option-$i'),
              letter: String.fromCharCode('A'.codeUnitAt(0) + i),
              text: item.options[i],
              selected: state.selected == i,
              revealed: showingFeedback,
              isCorrect: i == item.correctIndex,
              onTap: showingFeedback ? null : () => controller.select(i),
            ),
          const SizedBox(height: 16),
          if (!showingFeedback)
            AppButton(
              key: const Key('placement-answer'),
              label: 'Jawab',
              onPressed: state.selected == null
                  ? null
                  : () => controller.answer(),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (state.lastCorrect ?? false)
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (state.lastCorrect ?? false)
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (state.lastCorrect ?? false)
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: (state.lastCorrect ?? false)
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (state.lastCorrect ?? false)
                          ? 'Benar! Kerja bagus.'
                          : 'Kurang tepat. Pelajari pembahasannya.',
                      style: textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pembahasan', style: textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    item.explanation.isEmpty
                        ? 'Periksa kembali materi terkait soal ini.'
                        : item.explanation,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              key: const Key('placement-next'),
              label: state.isLast ? 'Lihat Hasil' : 'Lanjut',
              icon: Icons.arrow_forward,
              onPressed: () => controller.next(),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool selected;
  final bool revealed;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _OptionTile({
    super.key,
    required this.letter,
    required this.text,
    required this.selected,
    required this.revealed,
    required this.isCorrect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color? background;
    Color? border;
    if (revealed && isCorrect) {
      background = Colors.green.shade50;
      border = Colors.green;
    } else if (revealed && selected && !isCorrect) {
      background = Colors.red.shade50;
      border = Colors.red;
    } else if (selected) {
      background = colors.primaryContainer;
      border = colors.primary;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border ?? colors.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    (selected || (revealed && isCorrect)) ? border : null,
                child: Text(
                  letter,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
