import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/gamification/badges.dart';
import '../../../domain/gamification/gamification_rules.dart';
import '../../../domain/irt/irt_engine.dart';
import '../application/quiz_controller.dart';

/// Hasil kuis satu konsep.
///
/// - Dikuasai: perayaan, XP yang diperoleh, dan konsep baru yang terbuka.
/// - Gagal: kartu `Akar masalah: <konsep>` dan jalur remedial berurutan
///   dengan tombol `Ulangi <konsep>` (membuka materi), serta tombol
///   `Kembali ke Peta`. Bila kuis ini remedial dan lulus, tawarkan
///   kembali ke konsep awal.
class QuizResultScreen extends ConsumerWidget {
  final QuizState state;

  const QuizResultScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.decision == SessionDecision.mastered) {
      return _MasteredBody(state: state);
    }
    return _FailedBody(state: state);
  }
}

class _MasteredBody extends StatelessWidget {
  final QuizState state;

  const _MasteredBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showOrigin = state.originConceptId != null &&
        state.originConceptId != state.conceptId &&
        (state.originConceptName ?? '').isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.celebration,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            key: const Key('quiz-result-title'),
            'Selamat! ${state.conceptName} Dikuasai',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Center(child: XpBadge(xp: state.xpEarned)),
          if (state.leveledUp) ...[
            const SizedBox(height: 8),
            Center(
              child: LevelBadge(level: xpToLevel(state.xpTotal)),
            ),
            const SizedBox(height: 4),
            Text(
              'Naik level! Pertahankan streak belajarmu.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (state.newBadges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in state.newBadges)
                  Chip(
                    key: Key('quiz-new-badge-$code'),
                    avatar: Icon(
                      badgeIconFor(code),
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(_badgeName(code)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jawaban benar: '
                  '${state.correctCount} dari ${state.nAnswered}',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Konsep baru yang terbuka:',
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                if (state.newlyUnlockedIds.isEmpty)
                  Text(
                    'Belum ada konsep baru yang terbuka. Pertahankan!',
                    style: textTheme.bodyMedium,
                  )
                else
                  for (final id in state.newlyUnlockedIds)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_open,
                            size: 16,
                            color:
                                Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.names[id] ?? id,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (showOrigin) ...[
            AppButton(
              key: const Key('quiz-to-origin'),
              label: 'Kembali ke ${state.originConceptName}',
              icon: Icons.history,
              onPressed: () => context.push(
                AppRoutes.studentMaterial(state.originConceptId!),
              ),
            ),
            const SizedBox(height: 12),
          ],
          AppButton(
            key: const Key('quiz-to-map'),
            label: 'Kembali ke Peta',
            variant:
                showOrigin ? AppButtonVariant.secondary : AppButtonVariant.primary,
            icon: Icons.map_outlined,
            onPressed: () => context.go(AppRoutes.studentMap),
          ),
        ],
      ),
    );
  }
}

class _FailedBody extends StatelessWidget {
  final QuizState state;

  const _FailedBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final plan = state.remedialPlan;
    final path = plan?.orderedPath ?? const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          Text(
            key: const Key('quiz-result-title'),
            '${state.conceptName} Belum Dikuasai',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Jangan menyerah. Ikuti jalur remedial di bawah ini.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Akar masalah: ${state.rootCauseName}',
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
                Text('Jalur remedial:', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                if (path.isEmpty)
                  Text(
                    'Pelajari kembali materi ${state.conceptName}.',
                    style: textTheme.bodyMedium,
                  )
                else
                  for (var i = 0; i < path.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 13,
                                child: Text(
                                  '${i + 1}',
                                  style: textTheme.labelMedium,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.names[path[i]] ?? path[i],
                                  style: textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AppButton(
                            key: Key('quiz-retry-${path[i]}'),
                            label:
                                'Ulangi ${state.names[path[i]] ?? path[i]}',
                            variant: AppButtonVariant.secondary,
                            onPressed: () => context.push(
                              AppRoutes.studentMaterial(
                                path[i],
                                from: state.conceptId,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            key: const Key('quiz-to-map'),
            label: 'Kembali ke Peta',
            icon: Icons.map_outlined,
            onPressed: () => context.go(AppRoutes.studentMap),
          ),
        ],
      ),
    );
  }
}

/// Nama lencana dari kode; kode asing ditampilkan apa adanya.
String _badgeName(String code) {
  for (final badge in kAppBadges) {
    if (badge.code == code) return badge.name;
  }
  return code;
}
