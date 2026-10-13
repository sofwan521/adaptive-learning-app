// Kontrak repository progres belajar (domain, tanpa import Flutter).
import '../models/ability_estimate.dart';
import '../models/pending_response.dart';
import '../models/quiz_session.dart';
import '../models/student_concept_state.dart';

/// Kemampuan, state konsep, sesi, dan jawaban siswa.
/// Galat berupa [AppException].
abstract class ProgressRepository {
  /// Kemampuan global siswa (default theta 0, SE 1 bila belum ada).
  Future<AbilityEstimate> loadAbility();

  /// Simpan kemampuan global siswa.
  Future<void> saveAbility(AbilityEstimate estimate);

  /// Seluruh state konsep milik siswa.
  Future<List<StudentConceptState>> loadConceptStates();

  /// Simpan (sisip/perbarui) satu state konsep.
  Future<void> upsertConceptState(StudentConceptState state);

  /// Simpan satu jawaban. Bila luring, respons masuk antrean lokal
  /// dan [ResponseSyncStatus.queued] dikembalikan.
  Future<ResponseSyncStatus> saveResponse(PendingResponse response);

  /// Kirim semua antrean lokal. Mengembalikan jumlah yang terkirim.
  /// Dipanggil saat aplikasi aktif/koneksi pulih.
  Future<int> flushPending();

  /// Jumlah respons yang masih antre.
  Future<int> pendingCount();

  /// Jumlah soal yang dijawab hari ini (zona waktu perangkat).
  Future<int> countResponsesToday();

  /// Mulai sesi kuis, mengembalikan id sesi.
  Future<String> createSession({String? conceptId});

  /// Selesaikan sesi kuis dengan theta akhir.
  Future<void> finishSession({
    required String sessionId,
    required double finalTheta,
  });

  /// Riwayat sesi kuis terbaru.
  Future<List<QuizSession>> history({int limit = 20});
}
