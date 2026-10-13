import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../domain/models/concept.dart';
import '../../domain/models/concept_edge.dart';
import '../../domain/models/learning_material.dart';
import '../../domain/repositories/concept_repository.dart';
import '../datasources/supabase_service.dart';

/// Implementasi [ConceptRepository] memakai tabel Supabase
/// `concepts`, `concept_edges`, dan `materials`.
class SupabaseConceptRepository implements ConceptRepository {
  final SupabaseClient _client;

  SupabaseConceptRepository(this._client);

  @override
  Future<List<Concept>> fetchConcepts() async {
    try {
      final rows = await _client
          .from('concepts')
          .select('id,code,title,description,topic,tau,order_index')
          .order('order_index');
      final edges = await fetchEdges();
      final prereqs = <String, List<String>>{};
      for (final edge in edges) {
        prereqs.putIfAbsent(edge.conceptId, () => []).add(edge.prerequisiteId);
      }
      return [
        for (final row in (rows as List))
          Concept(
            id: row['id'] as String,
            name: row['title'] as String? ?? '',
            description: row['description'] as String? ?? '',
            prerequisiteIds: prereqs[row['id']] ?? const [],
            code: row['code'] as String? ?? '',
            tau: (row['tau'] as num? ?? 0).toDouble(),
          ),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<List<ConceptEdge>> fetchEdges() async {
    try {
      final rows = await _client
          .from('concept_edges')
          .select('prerequisite_id,concept_id');
      return [
        for (final row in (rows as List))
          ConceptEdge(
            prerequisiteId: row['prerequisite_id'] as String,
            conceptId: row['concept_id'] as String,
          ),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<LearningMaterial> fetchMaterial(String conceptId) async {
    try {
      final row = await _client
          .from('materials')
          .select()
          .eq('concept_id', conceptId)
          .maybeSingle();
      if (row == null) {
        throw const AppException('Materi belum tersedia untuk konsep ini.');
      }
      return LearningMaterial.fromRow(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}

final conceptRepositoryProvider = Provider<ConceptRepository>(
  (ref) => SupabaseConceptRepository(ref.watch(supabaseClientProvider)),
);
