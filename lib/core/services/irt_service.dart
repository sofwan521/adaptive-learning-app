import 'dart:math';
import '../models/question.dart';
import '../models/quiz_response.dart';

/// Service untuk implementasi Item Response Theory (IRT)
/// Menggunakan model 2PL (Two-Parameter Logistic)
class IRTService {
  // Estimasi kemampuan awal siswa (theta)
  double _currentTheta = 0.0;

  // Riwayat respon untuk kalibrasi
  final List<QuizResponse> _responses = [];

  double get currentTheta => _currentTheta;

  /// Menghitung probabilitas jawaban benar menggunakan model 2PL
  /// P(θ) = 1 / (1 + e^(-a(θ - b)))
  ///
  /// - theta: kemampuan siswa
  /// - a: discrimination (daya pembeda)
  /// - b: difficulty (tingkat kesulitan)
  double calculateProbability({
    required double theta,
    required double discrimination,
    required double difficulty,
  }) {
    final exponent = -discrimination * (theta - difficulty);
    return 1 / (1 + exp(exponent));
  }

  /// Menghitung probabilitas dengan model 3PL (dengan guessing parameter)
  /// P(θ) = c + (1 - c) / (1 + e^(-a(θ - b)))
  double calculateProbability3PL({
    required double theta,
    required double discrimination,
    required double difficulty,
    required double guessing,
  }) {
    final exponent = -discrimination * (theta - difficulty);
    final twoPlProb = 1 / (1 + exp(exponent));
    return guessing + (1 - guessing) * twoPlProb;
  }

  /// Menghitung information function untuk soal
  /// I(θ) = a² * P(θ) * (1 - P(θ))
  double calculateInformation({
    required double theta,
    required double discrimination,
    required double difficulty,
  }) {
    final prob = calculateProbability(
      theta: theta,
      discrimination: discrimination,
      difficulty: difficulty,
    );
    return discrimination * discrimination * prob * (1 - prob);
  }

  /// Update estimasi theta menggunakan Maximum Likelihood Estimation (MLE)
  /// dengan Newton-Raphson method
  void updateTheta(List<QuizResponse> responses, List<Question> questions) {
    if (responses.isEmpty) return;

    _responses.addAll(responses);

    // Newton-Raphson iteration
    const maxIterations = 10;
    const convergenceThreshold = 0.01;

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      double firstDerivative = 0.0;
      double secondDerivative = 0.0;

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        final question = questions.firstWhere((q) => q.id == response.questionId);

        final a = question.discrimination;
        final b = question.difficulty;
        final u = response.isCorrect ? 1.0 : 0.0;

        final prob = calculateProbability(
          theta: _currentTheta,
          discrimination: a,
          difficulty: b,
        );

        // First derivative (score function)
        firstDerivative += a * (u - prob);

        // Second derivative (information)
        secondDerivative -= a * a * prob * (1 - prob);
      }

      // Update theta
      final thetaChange = -firstDerivative / secondDerivative;
      _currentTheta += thetaChange;

      // Check convergence
      if (thetaChange.abs() < convergenceThreshold) {
        break;
      }
    }

    // Clamp theta to reasonable range [-4, 4]
    _currentTheta = _currentTheta.clamp(-4.0, 4.0);
  }

  /// Pilih soal berikutnya yang paling informatif (adaptive selection)
  /// Memilih soal dengan information maksimal pada theta saat ini
  Question? selectNextQuestion(
    List<Question> availableQuestions,
    List<String> answeredQuestionIds,
  ) {
    if (availableQuestions.isEmpty) return null;

    final unansweredQuestions = availableQuestions
        .where((q) => !answeredQuestionIds.contains(q.id))
        .toList();

    if (unansweredQuestions.isEmpty) return null;

    // Cari soal dengan information tertinggi
    Question? bestQuestion;
    double maxInformation = -1;

    for (final question in unansweredQuestions) {
      final info = calculateInformation(
        theta: _currentTheta,
        discrimination: question.discrimination,
        difficulty: question.difficulty,
      );

      if (info > maxInformation) {
        maxInformation = info;
        bestQuestion = question;
      }
    }

    return bestQuestion;
  }

  /// Hitung Standard Error of Measurement (SEM)
  double calculateSEM(List<Question> answeredQuestions) {
    if (answeredQuestions.isEmpty) return double.infinity;

    double totalInformation = 0.0;

    for (final question in answeredQuestions) {
      totalInformation += calculateInformation(
        theta: _currentTheta,
        discrimination: question.discrimination,
        difficulty: question.difficulty,
      );
    }

    if (totalInformation <= 0) return double.infinity;

    return 1 / sqrt(totalInformation);
  }

  /// Cek apakah placement test sudah cukup akurat
  bool isPlacementTestComplete({
    required List<Question> answeredQuestions,
    required int minimumQuestions,
    required double maxSEM,
  }) {
    if (answeredQuestions.length < minimumQuestions) {
      return false;
    }

    final sem = calculateSEM(answeredQuestions);
    return sem <= maxSEM;
  }

  /// Reset estimasi theta
  void resetTheta([double initialTheta = 0.0]) {
    _currentTheta = initialTheta;
    _responses.clear();
  }

  /// Konversi theta ke skala 0-100 untuk UI
  double thetaToPercentage(double theta) {
    // Theta biasanya dalam range -4 to 4
    // Konversi ke 0-100
    return ((theta + 4) / 8 * 100).clamp(0.0, 100.0);
  }

  /// Konversi theta ke level kesulitan kategorikal
  String thetaToLevel(double theta) {
    if (theta < -2) return 'Pemula';
    if (theta < -1) return 'Dasar';
    if (theta < 0) return 'Menengah';
    if (theta < 1) return 'Lanjut';
    if (theta < 2) return 'Mahir';
    return 'Expert';
  }
}
