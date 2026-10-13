import 'package:equatable/equatable.dart';

/// Materi pembelajaran ringkas untuk satu konsep.
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class LearningMaterial extends Equatable {
  final String id;
  final String conceptId;
  final String title;
  final String bodyMarkdown;

  const LearningMaterial({
    required this.id,
    required this.conceptId,
    required this.title,
    this.bodyMarkdown = '',
  });

  factory LearningMaterial.fromJson(Map<String, dynamic> json) {
    return LearningMaterial(
      id: json['id'] as String,
      conceptId: json['conceptId'] as String,
      title: json['title'] as String? ?? '',
      bodyMarkdown: json['bodyMarkdown'] as String? ?? '',
    );
  }

  /// Baris Supabase (`materials`) ke materi domain.
  factory LearningMaterial.fromRow(Map<String, dynamic> row) {
    return LearningMaterial(
      id: row['id'] as String,
      conceptId: row['concept_id'] as String,
      title: row['title'] as String? ?? '',
      bodyMarkdown: row['body_markdown'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conceptId': conceptId,
      'title': title,
      'bodyMarkdown': bodyMarkdown,
    };
  }

  @override
  List<Object?> get props => [id, conceptId, title, bodyMarkdown];
}
