import 'package:equatable/equatable.dart';

import 'concept_status.dart';

/// Status penguasaan satu konsep oleh satu siswa.
///
/// Cermin tabel `student_concept_state` di Supabase.
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class StudentConceptState extends Equatable {
  final String studentId;
  final String conceptId;
  final ConceptStatus status;
  final double thetaC;
  final int nAnswered;

  const StudentConceptState({
    required this.studentId,
    required this.conceptId,
    this.status = ConceptStatus.locked,
    this.thetaC = 0.0,
    this.nAnswered = 0,
  });

  StudentConceptState copyWith({
    String? studentId,
    String? conceptId,
    ConceptStatus? status,
    double? thetaC,
    int? nAnswered,
  }) {
    return StudentConceptState(
      studentId: studentId ?? this.studentId,
      conceptId: conceptId ?? this.conceptId,
      status: status ?? this.status,
      thetaC: thetaC ?? this.thetaC,
      nAnswered: nAnswered ?? this.nAnswered,
    );
  }

  factory StudentConceptState.fromJson(Map<String, dynamic> json) {
    return StudentConceptState(
      studentId: json['studentId'] as String,
      conceptId: json['conceptId'] as String,
      status: ConceptStatus.fromString(json['status'] as String?),
      thetaC: (json['thetaC'] as num? ?? 0.0).toDouble(),
      nAnswered: json['nAnswered'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'conceptId': conceptId,
      'status': status.name,
      'thetaC': thetaC,
      'nAnswered': nAnswered,
    };
  }

  @override
  List<Object?> get props =>
      [studentId, conceptId, status, thetaC, nAnswered];
}
