import 'package:equatable/equatable.dart';

/// Kelas milik guru (cermin tabel `classes`).
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class ClassInfo extends Equatable {
  final String id;
  final String teacherId;
  final String name;
  final String joinCode;

  const ClassInfo({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.joinCode,
  });

  factory ClassInfo.fromRow(Map<String, dynamic> row) {
    return ClassInfo(
      id: row['id'] as String,
      teacherId: row['teacher_id'] as String,
      name: row['name'] as String? ?? '',
      joinCode: row['join_code'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, teacherId, name, joinCode];
}

/// Ringkasan satu murid untuk laporan kelas.
class ClassMemberReport extends Equatable {
  final String studentId;
  final String fullName;
  final double theta;
  final int masteredCount;
  final int xp;

  const ClassMemberReport({
    required this.studentId,
    required this.fullName,
    required this.theta,
    required this.masteredCount,
    required this.xp,
  });

  @override
  List<Object?> get props =>
      [studentId, fullName, theta, masteredCount, xp];
}

/// Laporan kelas: daftar murid beserta kemajuannya.
class ClassReport extends Equatable {
  final String classId;
  final String className;
  final int totalConcepts;
  final List<ClassMemberReport> members;

  const ClassReport({
    required this.classId,
    required this.className,
    required this.totalConcepts,
    this.members = const [],
  });

  @override
  List<Object?> get props => [classId, className, totalConcepts, members];
}
