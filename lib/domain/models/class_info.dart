import 'package:equatable/equatable.dart';

import 'quiz_session.dart';

/// Kelas milik guru (cermin tabel `classes`).
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class ClassInfo extends Equatable {
  final String id;
  final String teacherId;
  final String name;
  final String joinCode;

  /// Jumlah siswa anggota (diisi repository, default 0).
  final int memberCount;

  const ClassInfo({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.joinCode,
    this.memberCount = 0,
  });

  factory ClassInfo.fromRow(Map<String, dynamic> row) {
    return ClassInfo(
      id: row['id'] as String,
      teacherId: row['teacher_id'] as String,
      name: row['name'] as String? ?? '',
      joinCode: row['join_code'] as String? ?? '',
    );
  }

  ClassInfo copyWith({
    String? id,
    String? teacherId,
    String? name,
    String? joinCode,
    int? memberCount,
  }) {
    return ClassInfo(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      name: name ?? this.name,
      joinCode: joinCode ?? this.joinCode,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  List<Object?> get props => [id, teacherId, name, joinCode, memberCount];
}

/// Ringkasan satu murid untuk laporan kelas.
class ClassMemberReport extends Equatable {
  final String studentId;
  final String fullName;
  final double theta;
  final int masteredCount;
  final int xp;

  /// Aktivitas terakhir (tanggal gamifikasi), null bila tak diketahui.
  final DateTime? lastActive;

  const ClassMemberReport({
    required this.studentId,
    required this.fullName,
    required this.theta,
    required this.masteredCount,
    required this.xp,
    this.lastActive,
  });

  @override
  List<Object?> get props =>
      [studentId, fullName, theta, masteredCount, xp, lastActive];
}

/// Laporan kelas: daftar murid beserta kemajuannya.
class ClassReport extends Equatable {
  final String classId;
  final String className;

  /// Kode gabung untuk dibagikan ke siswa (bisa kosong di versi lama).
  final String joinCode;
  final int totalConcepts;
  final List<ClassMemberReport> members;

  const ClassReport({
    required this.classId,
    required this.className,
    this.joinCode = '',
    required this.totalConcepts,
    this.members = const [],
  });

  @override
  List<Object?> get props =>
      [classId, className, joinCode, totalConcepts, members];
}

/// Tingkat kegagalan satu konsep di sebuah kelas.
class ConceptFailRate extends Equatable {
  final String conceptId;

  /// Jumlah sesi selesai yang dinilai.
  final int sessions;

  /// Jumlah sesi dengan theta akhir di bawah ambang.
  final int failed;

  /// [failed] / [sessions], 0 bila tak ada sesi.
  double get failRate => sessions == 0 ? 0 : failed / sessions;

  const ConceptFailRate({
    required this.conceptId,
    required this.sessions,
    required this.failed,
  });

  @override
  List<Object?> get props => [conceptId, sessions, failed];
}

/// Urutkan konsep paling sering gagal dari sesi selesai.
///
/// Sesi tanpa konsep, tanpa theta akhir, atau belum selesai
/// diabaikan. Gagal berarti theta akhir < ambang [taus] konsep
/// (default 0 bila ambang tak dikenal). Urutan: persentase gagal
/// menurun, lalu jumlah sesi menurun, lalu id menaik agar stabil.
List<ConceptFailRate> rankFailedConcepts({
  required List<QuizSession> sessions,
  required Map<String, double> taus,
}) {
  final totals = <String, int>{};
  final failed = <String, int>{};
  for (final session in sessions) {
    final conceptId = session.conceptId;
    final theta = session.finalTheta;
    if (session.status != QuizSessionStatus.finished ||
        conceptId == null ||
        theta == null) {
      continue;
    }
    totals[conceptId] = (totals[conceptId] ?? 0) + 1;
    if (theta < (taus[conceptId] ?? 0)) {
      failed[conceptId] = (failed[conceptId] ?? 0) + 1;
    }
  }
  final ranked = [
    for (final entry in totals.entries)
      ConceptFailRate(
        conceptId: entry.key,
        sessions: entry.value,
        failed: failed[entry.key] ?? 0,
      ),
  ];
  ranked.sort((a, b) {
    final rate = b.failRate.compareTo(a.failRate);
    if (rate != 0) return rate;
    final count = b.sessions.compareTo(a.sessions);
    if (count != 0) return count;
    return a.conceptId.compareTo(b.conceptId);
  });
  return ranked;
}
