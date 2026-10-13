// Aturan gamifikasi AdaptiLearn sebagai fungsi murni.
//
// - XP: jawaban benar +10, sesi lulus +50, konsep baru dikuasai +100.
// - Level: floor(sqrt(xp / 100)) + 1.
// - Streak harian: bertambah bila belajar pada hari berbeda
//   berturut-turut, bertahan bila hari yang sama, reset ke 1 bila
//   terlewat satu hari penuh.
//
// Logika murni — tanpa import Flutter — sehingga mudah diuji.
import 'dart:math';

/// XP untuk satu jawaban benar.
const int xpPerCorrectAnswer = 10;

/// XP bonus saat sesi kuis lulus (dikuasai).
const int xpPerSessionPass = 50;

/// XP bonus saat konsep baru dikuasai pertama kali.
const int xpPerNewMastery = 100;

/// Level dari total [xp]: floor(sqrt(xp / 100)) + 1.
///
/// XP negatif diperlakukan sebagai 0.
int xpToLevel(int xp) {
  final safe = xp < 0 ? 0 : xp;
  return sqrt(safe / 100).floor() + 1;
}

/// Ambang XP untuk mencapai [level] (level >= 1).
///
/// Balikan dari [xpToLevel]: level L mulai pada (L-1)^2 * 100 XP.
int xpThresholdForLevel(int level) {
  final safe = level < 1 ? 1 : level;
  return (safe - 1) * (safe - 1) * 100;
}

/// Fraksi progres 0..1 dari [xp] menuju level berikutnya.
double xpProgressToNextLevel(int xp) {
  final level = xpToLevel(xp);
  final base = xpThresholdForLevel(level);
  final next = xpThresholdForLevel(level + 1);
  if (next <= base) return 1.0;
  return ((xp - base) / (next - base)).clamp(0.0, 1.0);
}

/// Hitung streak harian baru.
///
/// - [lastActiveDate] null (belum pernah aktif) -> 1.
/// - [today] sama dengan hari [lastActiveDate] -> [currentStreak] tetap.
/// - Selisih tepat 1 hari -> [currentStreak] + 1.
/// - Terlewat >= 1 hari penuh (selisih >= 2 hari) atau tanggal
///   berjalan mundur -> reset ke 1.
///
/// Perbandingan memakai tanggal kalender (zona waktu perangkat).
int computeStreak({
  required DateTime? lastActiveDate,
  required DateTime today,
  required int currentStreak,
}) {
  final todayDay = DateTime(today.year, today.month, today.day);
  if (lastActiveDate == null) return 1;
  final lastDay = DateTime(
    lastActiveDate.year,
    lastActiveDate.month,
    lastActiveDate.day,
  );
  final gap = todayDay.difference(lastDay).inDays;
  if (gap <= 0) return currentStreak;
  if (gap == 1) return currentStreak + 1;
  return 1;
}
