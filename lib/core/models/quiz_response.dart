class QuizResponse {
  final String questionId;
  final int selectedAnswerIndex;
  final bool isCorrect;
  final DateTime answeredAt;
  final int timeSpentSeconds;

  QuizResponse({
    required this.questionId,
    required this.selectedAnswerIndex,
    required this.isCorrect,
    required this.answeredAt,
    required this.timeSpentSeconds,
  });

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      questionId: json['questionId'],
      selectedAnswerIndex: json['selectedAnswerIndex'],
      isCorrect: json['isCorrect'],
      answeredAt: DateTime.parse(json['answeredAt']),
      timeSpentSeconds: json['timeSpentSeconds'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswerIndex': selectedAnswerIndex,
      'isCorrect': isCorrect,
      'answeredAt': answeredAt.toIso8601String(),
      'timeSpentSeconds': timeSpentSeconds,
    };
  }
}
