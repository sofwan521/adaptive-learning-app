// Mesin IRT 2PL AdaptiLearn sesuai AGENTS.md.
//
// - Peluang: P(theta) = 1 / (1 + exp(-a * (theta - b)))
// - Informasi: a^2 * P * (1 - P)
// - Estimasi EAP: grid -4..4 langkah 0.1, prior Normal.
// - Aturan henti sesi: minimal 4 soal, SE <= 0.6 atau 8 soal,
//   gagal dini bila 3 salah berturut-turut.
//
// Logika murni — tanpa import Flutter.
import 'dart:math';

import '../models/ability_estimate.dart';
import '../models/item.dart';
import '../models/response_record.dart';

/// Batas grid EAP.
const double eapMinTheta = -4.0;

/// Batas grid EAP.
const double eapMaxTheta = 4.0;

/// Langkah grid EAP.
const double eapStep = 0.1;

/// Keputusan sesi kuis.
///
/// `ongoing` berarti lanjut (spesifikasi menyebutnya "continue").
enum SessionDecision {
  /// Lanjut ke soal berikutnya.
  ongoing,

  /// Konsep dikuasai (theta_konsep >= tau saat berhenti).
  mastered,

  /// Gagal (dini atau saat berhenti theta_konsep < tau).
  failed,
}

/// Peluang jawab benar model 2PL.
double probability(double theta, double a, double b) {
  final exponent = -a * (theta - b);
  return 1.0 / (1.0 + exp(exponent));
}

/// Informasi Fisher model 2PL pada [theta].
double information(double theta, double a, double b) {
  final p = probability(theta, a, b);
  return a * a * p * (1.0 - p);
}

/// Estimasi kemampuan dengan Expected A Posteriori (EAP).
///
/// Grid [eapMinTheta]..[eapMaxTheta] langkah [eapStep] dengan prior
/// Normal([priorMean], [priorSd]). Dihitung stabil secara numerik
/// memakai log-likelihood + log-sum-exp, sehingga peluang 0/1 tidak
/// menghasilkan NaN. Tanpa respons, hasilnya mendekati prior.
AbilityEstimate estimateEap(
  List<ResponseRecord> responses, {
  double priorMean = 0.0,
  double priorSd = 1.0,
}) {
  assert(priorSd > 0, 'priorSd harus positif');
  const epsilon = 1e-12;

  final gridSize = ((eapMaxTheta - eapMinTheta) / eapStep).round() + 1;
  final logWeights = List<double>.filled(gridSize, 0.0);

  for (var i = 0; i < gridSize; i++) {
    var theta = eapMinTheta + i * eapStep;
    if (theta > eapMaxTheta) theta = eapMaxTheta;

    var logLikelihood = 0.0;
    for (final record in responses) {
      final p =
          probability(theta, record.a, record.b).clamp(epsilon, 1.0 - epsilon);
      logLikelihood += record.correct ? log(p) : log(1.0 - p);
    }

    final z = (theta - priorMean) / priorSd;
    logWeights[i] = logLikelihood - 0.5 * z * z;
  }

  // Normalisasi stabil (log-sum-exp).
  final maxLog = logWeights.reduce(max);
  var total = 0.0;
  final weights = List<double>.filled(gridSize, 0.0);
  for (var i = 0; i < gridSize; i++) {
    weights[i] = exp(logWeights[i] - maxLog);
    total += weights[i];
  }

  var mean = 0.0;
  for (var i = 0; i < gridSize; i++) {
    final theta = eapMinTheta + i * eapStep;
    mean += (weights[i] / total) * theta;
  }

  var variance = 0.0;
  for (var i = 0; i < gridSize; i++) {
    final theta = eapMinTheta + i * eapStep;
    final diff = theta - mean;
    variance += (weights[i] / total) * diff * diff;
  }

  return AbilityEstimate(theta: mean, se: sqrt(max(variance, epsilon)));
}

/// Pilih soal berikutnya dengan informasi Fisher maksimum pada [theta].
///
/// Kandidat yang id-nya ada di [usedIds] dilewati. Bila beberapa soal
/// berbagi informasi tertinggi (seri), pemenang dipilih acak terkontrol
/// lewat [random] (diinjeksikan agar tes deterministik).
/// Mengembalikan null bila tidak ada kandidat tersisa.
Item? selectNextItem(
  double theta,
  List<Item> candidates,
  Set<String> usedIds, {
  Random? random,
}) {
  const tolerance = 1e-12;
  final tied = <Item>[];
  var best = double.negativeInfinity;

  for (final item in candidates) {
    if (usedIds.contains(item.id)) continue;
    final info = information(theta, item.a, item.b);
    if (info > best + tolerance) {
      best = info;
      tied
        ..clear()
        ..add(item);
    } else if ((info - best).abs() <= tolerance) {
      tied.add(item);
    }
  }

  if (tied.isEmpty) return null;
  if (tied.length == 1) return tied.first;
  return tied[(random ?? Random()).nextInt(tied.length)];
}

/// Terapkan aturan henti sesi sesuai AGENTS.md.
///
/// - Gagal dini bila [consecutiveWrong] mencapai [maxConsecutiveWrong].
/// - Wajib minimal [minItems] soal sebelum boleh berhenti.
/// - Berhenti bila SE <= [maxSe] atau soal mencapai [maxItems].
/// - Saat berhenti: [SessionDecision.mastered] bila theta >= [tau],
///   [SessionDecision.failed] bila di bawahnya.
SessionDecision evaluateSession({
  required AbilityEstimate estimate,
  required int nAnswered,
  required int consecutiveWrong,
  required double tau,
  int minItems = 4,
  int maxItems = 8,
  double maxSe = 0.6,
  int maxConsecutiveWrong = 3,
}) {
  if (consecutiveWrong >= maxConsecutiveWrong) {
    return SessionDecision.failed;
  }
  if (nAnswered >= maxItems) {
    return estimate.theta >= tau
        ? SessionDecision.mastered
        : SessionDecision.failed;
  }
  if (nAnswered >= minItems && estimate.se <= maxSe) {
    return estimate.theta >= tau
        ? SessionDecision.mastered
        : SessionDecision.failed;
  }
  return SessionDecision.ongoing;
}
