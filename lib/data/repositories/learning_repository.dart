import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/concept.dart';
import '../../domain/models/question.dart';

/// Kontrak repository pembelajaran.
///
/// Implementasi Supabase menyusul di langkah data.
abstract class LearningRepository {
  Future<List<Concept>> fetchConcepts();
  Future<List<Question>> fetchQuestions(String conceptId);
}

/// Implementasi sementara dalam memori (placeholder berarti).
///
/// Dipakai agar struktur terkompilasi sebelum integrasi Supabase.
class InMemoryLearningRepository implements LearningRepository {
  const InMemoryLearningRepository();

  @override
  Future<List<Concept>> fetchConcepts() async => const [];

  @override
  Future<List<Question>> fetchQuestions(String conceptId) async =>
      const [];
}

/// Provider repository default.
final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => const InMemoryLearningRepository(),
);
