import 'package:equatable/equatable.dart';

/// Satu jawaban tersimpan untuk dasbor progres.
///
/// Cermin baris tabel `responses` di Supabase (beserta waktu jawab).
/// Berbeda dari [ResponseRecord] yang menyimpan parameter soal untuk
/// estimasi EAP: model ini menyimpan hasil dan waktu untuk agregasi.
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class ResponseHistoryEntry extends Equatable {
  final String sessionId;
  final bool isCorrect;
  final double? thetaAfter;
  final DateTime answeredAt;

  const ResponseHistoryEntry({
    required this.sessionId,
    required this.isCorrect,
    this.thetaAfter,
    required this.answeredAt,
  });

  /// Baris Supabase (`responses`) ke entri domain.
  ///
  /// Baris tanpa `answered_at` yang sah dilewati (mengembalikan null)
  /// agar agregasi tak memakai titik waktu fiktif.
  static ResponseHistoryEntry? fromRow(Map<String, dynamic> row) {
    final answeredAt = DateTime.tryParse(
      (row['answered_at'] ?? '').toString(),
    );
    if (answeredAt == null) return null;
    return ResponseHistoryEntry(
      sessionId: row['session_id'] as String? ?? '',
      isCorrect: row['is_correct'] as bool? ?? false,
      thetaAfter: (row['theta_after'] as num?)?.toDouble(),
      answeredAt: answeredAt,
    );
  }

  @override
  List<Object?> get props => [sessionId, isCorrect, thetaAfter, answeredAt];
}
