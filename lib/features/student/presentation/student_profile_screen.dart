import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/teacher_repository_impl.dart';
import '../../../domain/gamification/badges.dart';
import '../../../domain/gamification/gamification_rules.dart';
import '../../../domain/models/class_info.dart';
import '../../auth/application/auth_controller.dart';
import '../../gamification/application/reminder_controller.dart';
import '../application/student_providers.dart';

/// Profil siswa: identitas, ringkasan gamifikasi, lencana,
/// pengaturan pengingat harian, dan tombol keluar.
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).profile;
    final name = (profile?.fullName ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: RefreshIndicator(
        onRefresh: () async => refreshStudySummary(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                name.isEmpty ? 'Siswa' : name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _GamificationCard(
                onRetry: () => refreshStudySummary(ref),
              ),
              const SizedBox(height: 16),
              Text('Lencana', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _BadgesGrid(
                onRetry: () => refreshStudySummary(ref),
              ),
              const SizedBox(height: 16),
              Text(
                'Pengingat belajar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const _ReminderCard(),
              const SizedBox(height: 16),
              Text('Kelas', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const _JoinClassCard(),
              const SizedBox(height: 24),
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
      ),
    );
  }
}

/// Kartu XP, level (dengan progres ke level berikut), dan streak.
class _GamificationCard extends ConsumerWidget {
  final VoidCallback onRetry;

  const _GamificationCard({required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider);
    return gamification.when(
      data: (state) {
        final progress = xpProgressToNextLevel(state.xp);
        final nextLevel = xpToLevel(state.xp) + 1;
        final remaining =
            xpThresholdForLevel(nextLevel) - state.xp;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  XpBadge(xp: state.xp),
                  LevelBadge(level: state.level),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$remaining XP lagi ke Level $nextLevel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Streak ${state.streak} hari',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const AppCard(
        child: LoadingView(message: 'Memuat progres…'),
      ),
      error: (error, _) => AppCard(
        child: ErrorView(
          message: error is AppException
              ? error.message
              : 'Gagal memuat progres.',
          onRetry: onRetry,
        ),
      ),
    );
  }
}

/// Grid seluruh lencana: perolehan berwarna, sisanya redup terkunci.
class _BadgesGrid extends ConsumerWidget {
  final VoidCallback onRetry;

  const _BadgesGrid({required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(studentBadgesProvider);
    return badgesAsync.when(
      data: (badges) => LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 8.0;
          final textScaler = MediaQuery.textScalerOf(context);
          final columns =
              constraints.maxWidth < 320 || textScaler.scale(14) > 21 ? 1 : 2;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              for (final entry in badges)
                SizedBox(
                  width: itemWidth,
                  child: _BadgeCard(entry: entry),
                ),
            ],
          );
        },
      ),
      loading: () => const AppCard(
        child: LoadingView(message: 'Memuat lencana…'),
      ),
      error: (error, _) => AppCard(
        child: ErrorView(
          message: error is AppException
              ? error.message
              : 'Gagal memuat lencana.',
          onRetry: onRetry,
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final ({AppBadge badge, bool earned}) entry;

  const _BadgeCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final earned = entry.earned;
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: earned
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              earned ? badgeIconFor(entry.badge.code) : Icons.lock_outline,
              color: earned ? colors.onPrimaryContainer : colors.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.badge.name,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          Text(
            earned ? entry.badge.description : 'Belum diperoleh',
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Pengaturan pengingat harian: sakelar, jam, dan izin.
class _ReminderCard extends ConsumerWidget {
  const _ReminderCard();

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final controller = ref.read(reminderControllerProvider.notifier);
    final ok = await controller.setEnabled(enabled);
    if (!ok && enabled && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Izin notifikasi ditolak. Aktifkan di Pengaturan '
              'perangkat untuk memakai pengingat.',
            ),
          ),
        );
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(reminderControllerProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );
    if (picked == null) return;
    await ref
        .read(reminderControllerProvider.notifier)
        .setTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderControllerProvider);
    return AppCard(
      child: Column(
        children: [
          InkWell(
            key: const Key('reminder-row'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => _toggle(context, ref, !settings.enabled),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Pengingat harian'),
                  ),
                  Switch(
                    key: const Key('reminder-toggle'),
                    value: settings.enabled,
                    onChanged: (value) => _toggle(context, ref, value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text('Jam pengingat'),
              ),
              OutlinedButton.icon(
                key: const Key('reminder-time'),
                icon: const Icon(Icons.schedule),
                label: Text(settings.label),
                onPressed: () => _pickTime(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kartu gabung kelas: daftar kelas yang diikuti plus input kode.
///
/// Kode divalidasi 6 karakter alfanumerik lalu dikirim ke RPC
/// `join_class`; RLS memastikan siswa hanya bergabung untuk dirinya.
class _JoinClassCard extends ConsumerStatefulWidget {
  const _JoinClassCard();

  @override
  ConsumerState<_JoinClassCard> createState() => _JoinClassCardState();
}

class _JoinClassCardState extends ConsumerState<_JoinClassCard> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late Future<List<ClassInfo>> _classesFuture;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _classesFuture = _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<List<ClassInfo>> _load() async {
    return ref.read(teacherRepositoryProvider).myClasses();
  }

  void _reload() {
    setState(() {
      _classesFuture = _load();
    });
  }

  Future<void> _join() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _joining = true);
    try {
      await ref
          .read(teacherRepositoryProvider)
          .joinClass(_codeController.text);
      _codeController.clear();
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Berhasil bergabung ke kelas!'),
            ),
          );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FutureBuilder<List<ClassInfo>>(
            future: _classesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Gagal memuat kelas.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Muat ulang'),
                      ),
                    ],
                  ),
                );
              }
              final classes = snapshot.data ?? [];
              if (classes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Kamu belum bergabung ke kelas mana pun.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final classInfo in classes)
                      Chip(
                        avatar: const Icon(Icons.class_outlined, size: 16),
                        label: Text(classInfo.name),
                      ),
                  ],
                ),
              );
            },
          ),
          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('join-code-field'),
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Kode kelas',
                      hintText: 'cth. AB12CD',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    validator: validateClassCode,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  key: const Key('join-class-submit'),
                  onPressed: _joining ? null : _join,
                  child: _joining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Gabung'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
