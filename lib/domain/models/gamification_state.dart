import 'package:equatable/equatable.dart';

/// Status gamifikasi siswa (cermin tabel `gamification`).
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class GamificationState extends Equatable {
  final String studentId;
  final int xp;
  final int level;
  final int streak;
  final DateTime? lastActiveDate;

  const GamificationState({
    required this.studentId,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    this.lastActiveDate,
  });

  factory GamificationState.fromRow(Map<String, dynamic> row) {
    DateTime? parseDate(Object? value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return GamificationState(
      studentId: row['student_id'] as String,
      xp: row['xp'] as int? ?? 0,
      level: row['level'] as int? ?? 1,
      streak: row['streak'] as int? ?? 0,
      lastActiveDate: parseDate(row['last_active_date']),
    );
  }

  @override
  List<Object?> get props => [studentId, xp, level, streak, lastActiveDate];
}
