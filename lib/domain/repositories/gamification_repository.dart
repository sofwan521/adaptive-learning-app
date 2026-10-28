// Kontrak repository gamifikasi (domain, tanpa import Flutter).
import '../models/gamification_state.dart';

/// Streak dan lencana siswa. Galat berupa [AppException].
abstract class GamificationRepository {
  /// Status gamifikasi saat ini (default awal bila belum ada).
  Future<GamificationState> load();

  /// Perbarui streak harian dan kembalikan status terbaru.
  Future<GamificationState> updateStreak();

  /// Kode lencana yang sudah dimiliki siswa.
  Future<Set<String>> loadBadgeCodes();

  /// Beri lencana [code] bila belum dimiliki.
  ///
  /// Mengembalikan true bila lencana baru saja diperoleh, false bila
  /// sudah dimiliki sebelumnya (idempoten) atau kode tak dikenal.
  Future<bool> awardBadge(String code);
}
