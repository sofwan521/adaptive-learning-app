import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import '../application/quiz_controller.dart';
import 'quiz_result_screen.dart';

/// Layar kuis adaptif satu konsep: progres, kartu soal, opsi,
/// tombol jawab, umpan balik beserta pembahasan, dan hasil.
///
/// [from] adalah id konsep asal bila kuis dikerjakan sebagai
/// remedial; dipakai layar hasil untuk menawarkan kembali.
class QuizScreen extends ConsumerStatefulWidget {
  final String conceptId;
  final String? from;

  const QuizScreen({super.key, required this.conceptId, this.from});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    final state = ref.read(quizControllerProvider);
    if (state.conceptId != widget.conceptId ||
        state.phase == QuizPhase.idle) {
      Future.microtask(
        () => ref
            .read(quizControllerProvider.notifier)
            .start(widget.conceptId, originConceptId: widget.from),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.conceptName.isEmpty ? 'Kuis' : state.conceptName,
        ),
      ),
      body: switch (state.phase) {
        QuizPhase.idle || QuizPhase.loading => const LoadingView(
            message: 'Memuat soal…',
          ),
        QuizPhase.resumeOffer => _ResumeOffer(state: state),
        QuizPhase.finishing => const LoadingView(
            message: 'Menyimpan hasil…',
          ),
        QuizPhase.error => ErrorView(
            message: state.errorMessage ?? 'Terjadi kesalahan.',
            onRetry: () =>
                ref.read(quizControllerProvider.notifier).retry(),
          ),
        QuizPhase.done => QuizResultScreen(state: state),
        QuizPhase.answering || QuizPhase.feedback =>
          _QuestionBody(state: state),
      },
    );
  }
}

/// Tawaran melanjutkan sesi yang terputus.
class _ResumeOffer extends ConsumerWidget {
  final QuizState state;

  const _ResumeOffer({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quizControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final answered = state.pendingResume?.answers.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sesi belum selesai',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            answered > 0
                ? 'Kamu sudah menjawab $answered soal untuk '
                    '${state.conceptName}. Lanjutkan dari progres terakhirmu?'
                : 'Ada sesi ${state.conceptName} yang belum selesai. '
                    'Lanjutkan sesinya?',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            key: const Key('quiz-resume-continue'),
            label: 'Lanjutkan Sesi',
            icon: Icons.play_arrow,
            onPressed: () => controller.resume(),
          ),
          const SizedBox(height: 12),
          AppButton(
            key: const Key('quiz-resume-restart'),
            label: 'Mulai Baru',
            variant: AppButtonVariant.secondary,
            icon: Icons.refresh,
            onPressed: () => controller.restart(),
          ),
        ],
      ),
    );
  }
}

class _QuestionBody extends ConsumerWidget {
  final QuizState state;

  const _QuestionBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(quizControllerProvider.notifier);
    final item = state.currentItem;
    if (item == null) {
      return ErrorView(
        message: 'Soal tidak tersedia.',
        onRetry: () => controller.retry(),
      );
    }
    final showingFeedback = state.phase == QuizPhase.feedback;
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
                  value: state.items.isEmpty
                      ? 0
                      : state.questionNumber / state.items.length,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Soal ${state.questionNumber} dari ${state.items.length}',
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
              key: Key('quiz-option-$i'),
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
              key: const Key('quiz-answer'),
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
              key: const Key('quiz-next'),
              label: 'Lanjut',
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
