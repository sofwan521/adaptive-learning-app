import 'package:equatable/equatable.dart';

/// Status sesi kuis (cermin kolom `status` di `quiz_sessions`).
enum QuizSessionStatus {
  ongoing,
  finished,
  cancelled;

  static QuizSessionStatus fromDb(String? value) {
    switch (value) {
      case 'selesai':
        return QuizSessionStatus.finished;
      case 'batal':
        return QuizSessionStatus.cancelled;
      case 'berjalan':
      default:
        return QuizSessionStatus.ongoing;
    }
  }

  String toDb() {
    switch (this) {
      case QuizSessionStatus.ongoing:
        return 'berjalan';
      case QuizSessionStatus.finished:
        return 'selesai';
      case QuizSessionStatus.cancelled:
        return 'batal';
    }
  }
}

/// Satu sesi pengerjaan kuis oleh siswa.
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class QuizSession extends Equatable {
  final String id;
  final String studentId;
  final String? conceptId;
  final QuizSessionStatus status;
  final double? finalTheta;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const QuizSession({
    required this.id,
    required this.studentId,
    this.conceptId,
    this.status = QuizSessionStatus.ongoing,
    this.finalTheta,
    this.startedAt,
    this.finishedAt,
  });

  factory QuizSession.fromRow(Map<String, dynamic> row) {
    DateTime? parseDate(Object? value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return QuizSession(
      id: row['id'] as String,
      studentId: row['student_id'] as String,
      conceptId: row['concept_id'] as String?,
      status: QuizSessionStatus.fromDb(row['status'] as String?),
      finalTheta: (row['final_theta'] as num?)?.toDouble(),
      startedAt: parseDate(row['started_at']),
      finishedAt: parseDate(row['finished_at']),
    );
  }

  @override
  List<Object?> get props =>
      [id, studentId, conceptId, status, finalTheta, startedAt, finishedAt];
}
