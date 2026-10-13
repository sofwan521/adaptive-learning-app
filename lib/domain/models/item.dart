import 'package:equatable/equatable.dart';

/// Soal pilihan ganda dengan parameter IRT 2PL.
///
/// - [a]: daya pembeda (discrimination), harus > 0.
/// - [b]: tingkat kesulitan (difficulty).
/// - [correctIndex]: indeks opsi yang benar (0-based).
///
/// Immutable + Equatable (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class Item extends Equatable {
  final String id;
  final String conceptId;
  final String question;
  final List<String> options;
  final int correctIndex;
  final double a;
  final double b;

  /// Pembahasan singkat yang ditampilkan setelah menjawab.
  final String explanation;

  const Item({
    required this.id,
    required this.conceptId,
    this.question = '',
    this.options = const [],
    required this.correctIndex,
    this.a = 1.0,
    this.b = 0.0,
    this.explanation = '',
  });

  Item copyWith({
    String? id,
    String? conceptId,
    String? question,
    List<String>? options,
    int? correctIndex,
    double? a,
    double? b,
    String? explanation,
  }) {
    return Item(
      id: id ?? this.id,
      conceptId: conceptId ?? this.conceptId,
      question: question ?? this.question,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      a: a ?? this.a,
      b: b ?? this.b,
      explanation: explanation ?? this.explanation,
    );
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return Item(
      id: json['id'] as String,
      conceptId: json['conceptId'] as String,
      question: json['question'] as String? ?? '',
      options: rawOptions is List
          ? rawOptions.map((e) => e.toString()).toList()
          : const [],
      correctIndex: json['correctIndex'] as int? ?? 0,
      a: (json['a'] as num? ?? 1.0).toDouble(),
      b: (json['b'] as num? ?? 0.0).toDouble(),
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conceptId': conceptId,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'a': a,
      'b': b,
      'explanation': explanation,
    };
  }

  @override
  List<Object?> get props =>
      [id, conceptId, question, options, correctIndex, a, b, explanation];
}
