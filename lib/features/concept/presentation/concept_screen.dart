import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/concept_repository_impl.dart';
import '../../../domain/models/concept.dart';
import '../../../domain/models/concept_status.dart';
import '../../../domain/models/learning_material.dart';
import '../../student/application/student_providers.dart';
import 'simple_markdown_view.dart';

/// Halaman Materi satu konsep: judul, status, isi markdown
/// (termasuk gambar bila ada), dan tombol Mulai Kuis.
///
/// [from] adalah id konsep asal bila materi dibuka sebagai
/// remedial; diteruskan ke kuis agar hasilnya bisa menawarkan
/// kembali ke konsep awal.
class ConceptScreen extends ConsumerStatefulWidget {
  final String conceptId;
  final String? from;

  const ConceptScreen({super.key, required this.conceptId, this.from});

  @override
  ConsumerState<ConceptScreen> createState() => _ConceptScreenState();
}

class _ConceptScreenState extends ConsumerState<ConceptScreen> {
  late Future<LearningMaterial?> _materialFuture;

  @override
  void initState() {
    super.initState();
    _materialFuture = _loadMaterial();
  }

  @override
  void didUpdateWidget(covariant ConceptScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conceptId != widget.conceptId) {
      _materialFuture = _loadMaterial();
    }
  }

  Future<LearningMaterial?> _loadMaterial() async {
    try {
      return await ref
          .read(conceptRepositoryProvider)
          .fetchMaterial(widget.conceptId);
    } catch (_) {
      // Materi belum tersedia: tampilkan deskripsi konsep sebagai ganti.
      return null;
    }
  }

  void _reload() {
    setState(() {
      _materialFuture = _loadMaterial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final graphAsync = ref.watch(knowledgeGraphProvider);
    final statusesAsync = ref.watch(conceptStatusesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Materi')),
      body: graphAsync.when(
        data: (graph) {
          Concept concept;
          try {
            concept = graph.concept(widget.conceptId);
          } catch (_) {
            return ErrorView(
              message: 'Konsep tidak dikenal.',
              onRetry: () => context.pop(),
            );
          }
          final status = statusesAsync.when(
            data: (statuses) =>
                statuses[widget.conceptId] ?? ConceptStatus.locked,
            loading: () => ConceptStatus.locked,
            error: (_, __) => ConceptStatus.locked,
          );
          return _MaterialBody(
            concept: concept,
            status: status,
            materialFuture: _materialFuture,
            onRetryMaterial: _reload,
            onStartQuiz: () => context.push(
              AppRoutes.studentQuiz(widget.conceptId, from: widget.from),
            ),
          );
        },
        loading: () => const LoadingView(message: 'Memuat materi…'),
        error: (error, _) => ErrorView(
          message: error is AppException
              ? error.message
              : 'Gagal memuat materi. Silakan coba lagi.',
          onRetry: () => refreshStudySummary(ref),
        ),
      ),
    );
  }
}

class _MaterialBody extends StatelessWidget {
  final Concept concept;
  final ConceptStatus status;
  final Future<LearningMaterial?> materialFuture;
  final VoidCallback onRetryMaterial;
  final VoidCallback onStartQuiz;

  const _MaterialBody({
    required this.concept,
    required this.status,
    required this.materialFuture,
    required this.onRetryMaterial,
    required this.onStartQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(concept.name, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ConceptStatusChip(status: status),
          ),
          const SizedBox(height: 16),
          FutureBuilder<LearningMaterial?>(
            future: materialFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(message: 'Memuat isi materi…');
              }
              if (snapshot.hasError) {
                return ErrorView(
                  message: 'Gagal memuat isi materi.',
                  onRetry: onRetryMaterial,
                );
              }
              final material = snapshot.data;
              final body = material?.bodyMarkdown.trim() ?? '';
              if (body.isEmpty) {
                return AppCard(
                  child: Text(
                    concept.description.isEmpty
                        ? 'Materi belum tersedia untuk konsep ini.'
                        : concept.description,
                    style: textTheme.bodyMedium,
                  ),
                );
              }
              return AppCard(child: SimpleMarkdownView(source: body));
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            key: const Key('material-start-quiz'),
            label: 'Mulai Kuis',
            icon: Icons.play_arrow,
            onPressed: onStartQuiz,
          ),
        ],
      ),
    );
  }
}
