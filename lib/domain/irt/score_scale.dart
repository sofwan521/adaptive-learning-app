// Konversi skor kemampuan (theta) ke persentase untuk tampilan.
//
// Mesin IRT tetap bekerja pada skala theta (-4..4). Seluruh nilai
// yang ditampilkan ke pengguna memakai persentase 0..100.
//
// Logika murni — tanpa import Flutter.
import 'dart:math';

/// Batas bawah skala theta.
const double minThetaScale = -4.0;

/// Batas atas skala theta.
const double maxThetaScale = 4.0;

/// Ubah theta menjadi persentase 0..100.
///
/// Memakai kurva logistik sehingga theta 0 setara 50%.
double thetaToPercent(double theta) {
  final clamped = theta.clamp(minThetaScale, maxThetaScale);
  return 100.0 / (1.0 + exp(-clamped));
}

/// Ubah persentase 0..100 kembali menjadi theta.
double percentToTheta(double percent) {
  final ratio = (percent.clamp(0.0, 100.0)) / 100.0;
  const epsilon = 1e-6;
  final safe = ratio.clamp(epsilon, 1.0 - epsilon);
  return log(safe / (1.0 - safe));
}

/// Format persentase untuk teks UI, mis. `72%`.
String formatPercent(double percent) =>
    '${percent.clamp(0.0, 100.0).round()}%';
