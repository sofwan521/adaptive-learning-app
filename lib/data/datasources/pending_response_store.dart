import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/pending_response.dart';

/// Penyimpanan antrean respons luring.
abstract class PendingResponseStore {
  Future<List<PendingResponse>> loadAll();
  Future<void> saveAll(List<PendingResponse> items);
}

/// Implementasi [PendingResponseStore] memakai SharedPreferences.
///
/// Seluruh antrean disimpan sebagai satu string JSON agar tulis/baca atomik.
class SharedPreferencesPendingStore implements PendingResponseStore {
  static const storageKey = 'pending_responses_v1';

  const SharedPreferencesPendingStore();

  @override
  Future<List<PendingResponse>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return [
        for (final entry in decoded)
          if (entry is Map)
            PendingResponse.fromJson(
              Map<String, dynamic>.from(entry),
            ),
      ];
    } catch (_) {
      // Data rusak: pulihkan dengan antrean kosong.
      return [];
    }
  }

  @override
  Future<void> saveAll(List<PendingResponse> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode([for (final item in items) item.toJson()]),
    );
  }
}
