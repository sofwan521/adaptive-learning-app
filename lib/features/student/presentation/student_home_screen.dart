import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/models/concept.dart';
import '../../auth/application/auth_controller.dart';
import '../application/student_providers.dart';

/// Beranda siswa: sapaan, XP/streak, kartu lanjutan, dan target harian.
///
/// Data dari providers dengan state loading, error (coba lagi), dan kosong.
/// Dari sini ke kuis cukup 1 ketukan ("Mulai Kuis").
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  String _friendlyError(Object error) {
    if (error is AppException) return error.message;
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;
    final name = (profile?.fullName ?? '').trim();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: RefreshIndicator(
        onRefresh: () async => refreshStudySummary(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                name.isEmpty ? 'Halo!' : 'Halo, $name!',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Siap lanjut belajar hari ini?',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _StatsRow(onRetry: () => refreshStudySummary(ref)),
              const SizedBox(height: 24),
              Text('Lanjutkan belajar', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              _ContinueCard(
                onRetry: () => refreshStudySummary(ref),
                friendlyError: _friendlyError,
              ),
              const SizedBox(height: 24),
              Text('Target harian', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              _DailyTargetCard(
                onRetry: () => refreshStudySummary(ref),
                friendlyError: _friendlyError,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  final VoidCallback onRetry;

  const _StatsRow({required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider);
    return gamification.when(
      data: (state) => Row(
        children: [
          XpBadge(xp: state.xp),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  '${state.streak} hari',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Row(
        children: [
          const Icon(Icons.error_outline, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              error is AppException
                  ? error.message
                  : 'Gagal memuat XP.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Muat ulang')),
        ],
      ),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  final VoidCallback onRetry;
  final String Function(Object error) friendlyError;

  const _ContinueCard({required this.onRetry, required this.friendlyError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueAsync = ref.watch(continueConceptProvider);
    return continueAsync.when(
      data: (concept) {
        if (concept == null) {
          return const AppCard(
            child: EmptyView(
              message: 'Tidak ada konsep yang perlu dilanjutkan.',
              icon: Icons.celebration_outlined,
            ),
          );
        }
        return _ContinueDataCard(concept: concept);
      },
      loading: () => const AppCard(
        child: LoadingView(message: 'Memuat rekomendasi…'),
      ),
      error: (error, _) => AppCard(
        child: ErrorView(
          message: friendlyError(error),
          onRetry: onRetry,
        ),
      ),
    );
  }
}

class _ContinueDataCard extends StatelessWidget {
  final Concept concept;

  const _ContinueDataCard({required this.concept});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConceptStatusChip(status: concept.status),
          const SizedBox(height: 8),
          Text(concept.name, style: textTheme.titleMedium),
          if (concept.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              concept.description,
              style: textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          AppButton(
            key: const Key('home-start-quiz'),
            label: 'Mulai Kuis',
            icon: Icons.play_arrow,
            onPressed: () => context.push('/student/quiz/${concept.id}'),
          ),
        ],
      ),
    );
  }
}

class _DailyTargetCard extends ConsumerWidget {
  final VoidCallback onRetry;
  final String Function(Object error) friendlyError;

  const _DailyTargetCard({required this.onRetry, required this.friendlyError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyProgressProvider);
    return dailyAsync.when(
      data: (progress) {
        final reached = progress.answered >= progress.target;
        final value =
            (progress.answered / progress.target).clamp(0.0, 1.0);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                reached
                    ? 'Target tercapai! Pertahankan.'
                    : '${progress.answered} dari ${progress.target} soal hari ini',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: value),
            ],
          ),
        );
      },
      loading: () => const AppCard(
        child: LoadingView(message: 'Memuat target…'),
      ),
      error: (error, _) => AppCard(
        child: ErrorView(
          message: friendlyError(error),
          onRetry: onRetry,
        ),
      ),
    );
  }
}
