/// Soal pilihan ganda dengan parameter IRT 2PL.
///
/// - [a]: daya pembeda (discrimination)
/// - [b]: tingkat kesulitan (difficulty)
///
/// Class Dart biasa (tanpa code generation).
/// Logika murni — tanpa import Flutter.
class Question {
  final String id;
  final String conceptId;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final double a;
  final double b;

  const Question({
    required this.id,
    required this.conceptId,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    required this.a,
    required this.b,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return Question(
      id: json['id'] as String,
      conceptId: json['conceptId'] as String,
      text: json['text'] as String,
      options: rawOptions is List
          ? rawOptions.map((e) => e.toString()).toList()
          : const [],
      correctAnswerIndex: json['correctAnswerIndex'] as int? ?? 0,
      a: (json['a'] as num? ?? 1.0).toDouble(),
      b: (json['b'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conceptId': conceptId,
      'text': text,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'a': a,
      'b': b,
    };
  }
}
