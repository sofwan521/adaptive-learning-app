import 'package:equatable/equatable.dart';

/// Relasi prasyarat antar-konsep: [prerequisiteId] harus dikuasai
/// sebelum [conceptId] terbuka.
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class ConceptEdge extends Equatable {
  final String prerequisiteId;
  final String conceptId;

  const ConceptEdge({
    required this.prerequisiteId,
    required this.conceptId,
  });

  factory ConceptEdge.fromJson(Map<String, dynamic> json) {
    return ConceptEdge(
      prerequisiteId: json['prerequisiteId'] as String,
      conceptId: json['conceptId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prerequisiteId': prerequisiteId,
      'conceptId': conceptId,
    };
  }

  @override
  List<Object?> get props => [prerequisiteId, conceptId];
}
