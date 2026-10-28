import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/concept_repository_impl.dart';
import '../../../data/repositories/teacher_repository_impl.dart';
import '../../../domain/models/concept_status.dart';
import '../../../domain/models/student_concept_state.dart';

/// Data gabungan detail murid untuk satu FutureBuilder.
class _StudentDetailData {
  final String fullName;
  final double percent;
  final DateTime? lastActive;
  final List<({String name, StudentConceptState state})> concepts;

  const _StudentDetailData({
    required this.fullName,
    required this.percent,
    this.lastActive,
    required this.concepts,
  });
}

/// Detail murid: ringkasan plus peta status per konsep.
class StudentDetailScreen extends ConsumerStatefulWidget {
  final String classId;
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  @override
  ConsumerState<StudentDetailScreen> createState() =>
      _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  late Future<_StudentDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentDetailData> _load() async {
    final teacher = ref.read(teacherRepositoryProvider);
    final concepts = ref.read(conceptRepositoryProvider);
    final report = await teacher.classReport(widget.classId);
    final member = report.members.firstWhere(
      (m) => m.studentId == widget.studentId,
      orElse: () => throw const AppException('Siswa tidak ditemukan.'),
    );
    final states = await teacher.memberConceptStates(widget.studentId);
    final catalog = await concepts.fetchConcepts();
    final names = {for (final c in catalog) c.id: c.name};
    final byId = {for (final s in states) s.conceptId: s};
    return _StudentDetailData(
      fullName: member.fullName.isEmpty ? 'Siswa' : member.fullName,
      percent: member.percent,
      lastActive: member.lastActive,
      concepts: [
        for (final id in catalog.map((c) => c.id))
          (
            name: names[id] ?? id,
            state: byId[id] ??
                StudentConceptState(
                  studentId: widget.studentId,
                  conceptId: id,
                  status: ConceptStatus.locked,
                ),
          ),
      ],
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
      appBar: AppBar(title: const Text('Detail Siswa')),
      body: FutureBuilder<_StudentDetailData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Memuat detail siswa…');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: _messageOf(snapshot.error),
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          final textTheme = Theme.of(context).textTheme;
          final last = data.lastActive?.toLocal();
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.fullName, style: textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Skor ${data.percent.round()}% • '
                          '${last == null ? 'Belum pernah aktif' : 'Aktif ${last.day}/${last.month}/${last.year}'}',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Peta status per konsep',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final entry in data.concepts)
                          ListTile(
                            title: Text(entry.name),
                            subtitle: Text(
                              'Dijawab ${entry.state.nAnswered} soal',
                            ),
                            trailing: ConceptStatusChip(
                              status: entry.state.status,
                            ),
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
    return 'Gagal memuat detail siswa. Silakan coba lagi.';
  }
}
