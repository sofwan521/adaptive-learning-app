class Question {
  final String id;
  final String conceptId;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final double difficulty; // IRT parameter 'b'
  final double discrimination; // IRT parameter 'a'
  final double? guessing; // IRT parameter 'c' (optional, for 3PL)
  final String? explanation;
  final String? imageUrl;

  Question({
    required this.id,
    required this.conceptId,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    required this.difficulty,
    this.discrimination = 1.0,
    this.guessing,
    this.explanation,
    this.imageUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      conceptId: json['conceptId'],
      text: json['text'],
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'],
      difficulty: json['difficulty'].toDouble(),
      discrimination: json['discrimination']?.toDouble() ?? 1.0,
      guessing: json['guessing']?.toDouble(),
      explanation: json['explanation'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conceptId': conceptId,
      'text': text,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'difficulty': difficulty,
      'discrimination': discrimination,
      'guessing': guessing,
      'explanation': explanation,
      'imageUrl': imageUrl,
    };
  }
}
