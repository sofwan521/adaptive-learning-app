import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/progress_repository_impl.dart';

/// True bila siswa sudah menuntaskan placement test.
///
/// Dianggap tuntas bila sudah ada state konsep, atau SE kemampuan
/// sudah menyempit di bawah prior (SE awal = 1). Gagal baca data
/// (mis. luring) dianggap belum tuntas.
final placementCompletedProvider = FutureProvider<bool>((ref) async {
  try {
    final repository = ref.watch(progressRepositoryProvider);
    final states = await repository.loadConceptStates();
    if (states.isNotEmpty) return true;
    final ability = await repository.loadAbility();
    return ability.se < 1.0;
  } catch (_) {
    return false;
  }
});
