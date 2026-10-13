import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/concept_repository_impl.dart';
import '../../../data/repositories/teacher_repository_impl.dart';
import '../../../domain/models/class_info.dart';

/// Data gabungan detail kelas untuk satu FutureBuilder.
class _ClassDetailData {
  final ClassReport report;
  final List<ConceptFailRate> failRates;
  final Map<String, String> conceptNames;

  const _ClassDetailData({
    required this.report,
    required this.failRates,
    required this.conceptNames,
  });
}

/// Detail kelas: kode, daftar siswa, dan konsep paling sering gagal.
///
/// Seluruh data dibaca lewat RLS backend sehingga guru hanya
/// melihat murid di kelasnya sendiri.
class ClassDetailScreen extends ConsumerStatefulWidget {
  final String classId;

  const ClassDetailScreen({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailScreen> createState() =>
      _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  late Future<_ClassDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ClassDetailData> _load() async {
    final teacher = ref.read(teacherRepositoryProvider);
    final concepts = ref.read(conceptRepositoryProvider);
    final report = await teacher.classReport(widget.classId);
    final rates = await teacher.conceptFailRates(widget.classId);
    final catalog = await concepts.fetchConcepts();
    return _ClassDetailData(
      report: report,
      failRates: rates,
      conceptNames: {for (final c in catalog) c.id: c.name},
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kelas')),
      body: FutureBuilder<_ClassDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Memuat detail kelas…');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: _messageOf(snapshot.error),
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          final report = data.report;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ClassHeader(report: report),
                  const SizedBox(height: 16),
                  Text(
                    'Siswa (${report.members.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (report.members.isEmpty)
                    const AppCard(
                      child: EmptyView(
                        message: 'Belum ada siswa di kelas ini. Bagikan '
                            'kode kelas agar siswa bisa bergabung.',
                        icon: Icons.group_add_outlined,
                      ),
                    )
                  else
                    for (final member in report.members)
                      _MemberTile(
                        member: member,
                        totalConcepts: report.totalConcepts,
                        onTap: () => context.push(
                          AppRoutes.teacherStudentDetail(
                            widget.classId,
                            member.studentId,
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                  Text(
                    'Konsep paling sering gagal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (data.failRates.isEmpty)
                    const AppCard(
                      child: EmptyView(
                        message: 'Belum ada data sesi. Minta siswa '
                            'mengerjakan kuis terlebih dahulu.',
                        icon: Icons.insights_outlined,
                      ),
                    )
                  else
                    AppCard(
                      child: Column(
                        children: [
                          for (final rate in data.failRates)
                            _FailRateRow(
                              rate: rate,
                              conceptName: data.conceptNames[rate.conceptId] ??
                                  rate.conceptId,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _messageOf(Object? error) {
    if (error is AppException) return error.message;
    return 'Gagal memuat detail kelas. Silakan coba lagi.';
  }
}

class _ClassHeader extends StatelessWidget {
  final ClassReport report;

  const _ClassHeader({required this.report});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.className, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kode kelas: ${report.joinCode}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: const Key('class-copy-code'),
                tooltip: 'Salin kode',
                icon: const Icon(Icons.copy),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: report.joinCode),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('Kode kelas disalin.'),
                        ),
                      );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ClassMemberReport member;
  final int totalConcepts;
  final VoidCallback onTap;

  const _MemberTile({
    required this.member,
    required this.totalConcepts,
    required this.onTap,
  });

  String _lastActiveText() {
    final last = member.lastActive;
    if (last == null) return 'Belum pernah aktif';
    final local = last.toLocal();
    return 'Aktif ${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final name =
        member.fullName.isEmpty ? 'Siswa' : member.fullName;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'θ ${member.theta.toStringAsFixed(1)} • '
                  '${member.masteredCount}/$totalConcepts dikuasai • '
                  '${_lastActiveText()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _FailRateRow extends StatelessWidget {
  final ConceptFailRate rate;
  final String conceptName;

  const _FailRateRow({required this.rate, required this.conceptName});

  @override
  Widget build(BuildContext context) {
    final percent = (rate.failRate * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  conceptName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                'gagal ${rate.failed}/${rate.sessions} ($percent%)',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: rate.failRate),
        ],
      ),
    );
  }
}
