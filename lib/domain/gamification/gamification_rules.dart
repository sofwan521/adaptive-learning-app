// Aturan gamifikasi AdaptiLearn sebagai fungsi murni.
//
// - Streak harian: bertambah bila belajar pada hari berbeda
//   berturut-turut, bertahan bila hari yang sama, reset ke 1 bila
//   terlewat satu hari penuh.
//
// Logika murni — tanpa import Flutter — sehingga mudah diuji.

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
