import 'package:equatable/equatable.dart';

import 'concept_status.dart';

/// Konsep Matematika dalam Knowledge Graph.
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class Concept extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> prerequisiteIds;
  final ConceptStatus status;

  const Concept({
    required this.id,
    required this.name,
    required this.description,
    this.prerequisiteIds = const [],
    this.status = ConceptStatus.locked,
  });

  Concept copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? prerequisiteIds,
    ConceptStatus? status,
  }) {
    return Concept(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      prerequisiteIds: prerequisiteIds ?? this.prerequisiteIds,
      status: status ?? this.status,
    );
  }

  factory Concept.fromJson(Map<String, dynamic> json) {
    final prereqs = json['prerequisiteIds'];
    return Concept(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      prerequisiteIds: prereqs is List
          ? prereqs.map((e) => e.toString()).toList()
          : const [],
      status: ConceptStatus.fromString(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'prerequisiteIds': prerequisiteIds,
      'status': status.name,
    };
  }

  @override
  List<Object?> get props => [id, name, description, prerequisiteIds, status];
}
