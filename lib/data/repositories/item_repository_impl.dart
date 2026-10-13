import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../domain/models/item.dart';
import '../../domain/repositories/item_repository.dart';
import '../datasources/supabase_service.dart';

/// Implementasi [ItemRepository] memakai tabel Supabase `items`.
class SupabaseItemRepository implements ItemRepository {
  final SupabaseClient _client;

  SupabaseItemRepository(this._client);

  Item _fromRow(Map<String, dynamic> row) {
    final rawOptions = row['options'];
    return Item(
      id: row['id'] as String,
      conceptId: row['concept_id'] as String,
      question: row['question'] as String? ?? '',
      options: rawOptions is List
          ? rawOptions.map((e) => e.toString()).toList()
          : const [],
      correctIndex: row['correct_index'] as int? ?? 0,
      a: (row['a'] as num? ?? 1).toDouble(),
      b: (row['b'] as num? ?? 0).toDouble(),
      explanation: row['explanation'] as String? ?? '',
    );
  }

  @override
  Future<List<Item>> fetchItems(String conceptId) async {
    try {
      final rows = await _client
          .from('items')
          .select()
          .eq('concept_id', conceptId)
          .order('b');
      return [
        for (final row in (rows as List))
          _fromRow(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<List<Item>> fetchPlacementItems({int limit = 20}) async {
    try {
      final rows = await _client
          .from('items')
          .select()
          .order('b')
          .limit(limit);
      return [
        for (final row in (rows as List))
          _fromRow(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => SupabaseItemRepository(ref.watch(supabaseClientProvider)),
);
