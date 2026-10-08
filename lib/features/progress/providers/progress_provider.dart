import 'package:flutter/foundation.dart';

class ProgressData {
  final DateTime date;
  final int questionsAnswered;
  final int correctAnswers;
  final double averageScore;

  ProgressData({
    required this.date,
    required this.questionsAnswered,
    required this.correctAnswers,
    required this.averageScore,
  });
}

class ProgressProvider with ChangeNotifier {
  final List<ProgressData> _progressHistory = [];
  int _totalQuestionsAnswered = 0;
  int _totalCorrectAnswers = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;

  List<ProgressData> get progressHistory => _progressHistory;
  int get totalQuestionsAnswered => _totalQuestionsAnswered;
  int get totalCorrectAnswers => _totalCorrectAnswers;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;

  double get overallAccuracy {
    if (_totalQuestionsAnswered == 0) return 0.0;
    return (_totalCorrectAnswers / _totalQuestionsAnswered * 100);
  }

  void addProgress({
    required int questionsAnswered,
    required int correctAnswers,
  }) {
    _totalQuestionsAnswered += questionsAnswered;
    _totalCorrectAnswers += correctAnswers;

    final today = DateTime.now();
    final todayProgress = _progressHistory.firstWhere(
      (p) => p.date.year == today.year &&
             p.date.month == today.month &&
             p.date.day == today.day,
      orElse: () => ProgressData(
        date: today,
        questionsAnswered: 0,
        correctAnswers: 0,
        averageScore: 0.0,
      ),
    );

    final newQuestionsTotal = todayProgress.questionsAnswered + questionsAnswered;
    final newCorrectTotal = todayProgress.correctAnswers + correctAnswers;
    final newAverage = (newCorrectTotal / newQuestionsTotal * 100);

    _progressHistory.removeWhere((p) =>
      p.date.year == today.year &&
      p.date.month == today.month &&
      p.date.day == today.day
    );

    _progressHistory.add(ProgressData(
      date: today,
      questionsAnswered: newQuestionsTotal,
      correctAnswers: newCorrectTotal,
      averageScore: newAverage,
    ));

    _updateStreak();
    notifyListeners();
  }

  void _updateStreak() {
    if (_progressHistory.isEmpty) {
      _currentStreak = 0;
      return;
    }

    _progressHistory.sort((a, b) => b.date.compareTo(a.date));

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    final hasProgressToday = _progressHistory.any((p) =>
      p.date.year == today.year &&
      p.date.month == today.month &&
      p.date.day == today.day
    );

    if (!hasProgressToday) {
      final hasProgressYesterday = _progressHistory.any((p) =>
        p.date.year == yesterday.year &&
        p.date.month == yesterday.month &&
        p.date.day == yesterday.day
      );

      if (!hasProgressYesterday) {
        _currentStreak = 0;
        return;
      }
    }

    _currentStreak = 1;
    var checkDate = today.subtract(const Duration(days: 1));

    for (var i = 0; i < 365; i++) {
      final hasProgress = _progressHistory.any((p) =>
        p.date.year == checkDate.year &&
        p.date.month == checkDate.month &&
        p.date.day == checkDate.day
      );

      if (!hasProgress) break;

      _currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }
  }

  List<ProgressData> getLastNDays(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _progressHistory
        .where((p) => p.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
}
