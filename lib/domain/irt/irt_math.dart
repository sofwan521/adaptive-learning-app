// Fungsi murni IRT 2PL sesuai AGENTS.md.
//
// - Peluang: `P(theta) = 1 / (1 + exp(-a * (theta - b)))`
// - Informasi: `a^2 * P * (1 - P)`
//
// Tanpa import Flutter.
import 'dart:math' as math;

/// Peluang jawab benar model 2PL.
double probability2pl({
  required double theta,
  required double a,
  required double b,
}) {
  final exponent = -a * (theta - b);
  return 1.0 / (1.0 + math.exp(exponent));
}

/// Informasi item model 2PL pada [theta].
double information2pl({
  required double theta,
  required double a,
  required double b,
}) {
  final p = probability2pl(theta: theta, a: a, b: b);
  return a * a * p * (1.0 - p);
}

/// Densitas Normal standar N(0,1) untuk prior EAP.
double standardNormalPdf(double x) {
  const invSqrt2pi = 0.3989422804014327;
  return invSqrt2pi * math.exp(-0.5 * x * x);
}
