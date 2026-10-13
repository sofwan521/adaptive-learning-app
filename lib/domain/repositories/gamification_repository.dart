// Kontrak repository gamifikasi (domain, tanpa import Flutter).
import '../models/gamification_state.dart';

/// XP, level, dan streak siswa. Galat berupa [AppException].
abstract class GamificationRepository {
  /// Status gamifikasi saat ini (default awal bila belum ada).
  Future<GamificationState> load();

  /// Tambah XP (level dihitung ulang) dan kembalikan status terbaru.
  Future<GamificationState> addXp(int xp);

  /// Perbarui streak harian dan kembalikan status terbaru.
  Future<GamificationState> updateStreak();
}
