// Kontrak repository bank soal (domain, tanpa import Flutter).
import '../models/item.dart';

/// Bank soal pilihan ganda beserta parameter IRT 2PL.
/// Galat berupa [AppException].
abstract class ItemRepository {
  /// Soal satu konsep terurut tingkat kesulitan (b menaik).
  Future<List<Item>> fetchItems(String conceptId);

  /// Sampel soal lintas konsep untuk placement test.
  Future<List<Item>> fetchPlacementItems({int limit = 20});
}
