import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/domain/gamification/gamification_rules.dart';

void main() {
  group('xpToLevel', () {
    test('level 1 untuk 0 sampai 99 XP', () {
      expect(xpToLevel(0), 1);
      expect(xpToLevel(50), 1);
      expect(xpToLevel(99), 1);
    });

    test('floor(sqrt(xp/100)) + 1 pada batas level', () {
      expect(xpToLevel(100), 2);
      expect(xpToLevel(399), 2);
      expect(xpToLevel(400), 3);
      expect(xpToLevel(899), 3);
      expect(xpToLevel(900), 4);
      expect(xpToLevel(1600), 5);
    });

    test('XP negatif diperlakukan sebagai 0', () {
      expect(xpToLevel(-50), 1);
    });
  });

  group('xpThresholdForLevel', () {
    test('ambang awal tiap level', () {
      expect(xpThresholdForLevel(1), 0);
      expect(xpThresholdForLevel(2), 100);
      expect(xpThresholdForLevel(3), 400);
      expect(xpThresholdForLevel(4), 900);
    });

    test('konsisten bulat-balik dengan xpToLevel', () {
      for (var xp = 0; xp < 2000; xp += 7) {
        final level = xpToLevel(xp);
        expect(xpThresholdForLevel(level), lessThanOrEqualTo(xp));
        expect(xpThresholdForLevel(level + 1), greaterThan(xp));
      }
    });
  });

  group('xpProgressToNextLevel', () {
    test('nol di awal level, satu di ambang berikut', () {
      expect(xpProgressToNextLevel(0), 0.0);
      expect(xpProgressToNextLevel(100), 0.0);
      expect(xpProgressToNextLevel(250), closeTo(0.5, 1e-9));
    });
  });

  group('computeStreak', () {
    final today = DateTime(2026, 10, 13, 9, 30);

    test('aktivitas pertama memulai streak 1', () {
      expect(
        computeStreak(
          lastActiveDate: null,
          today: today,
          currentStreak: 0,
        ),
        1,
      );
    });

    test('hari yang sama mempertahankan streak', () {
      expect(
        computeStreak(
          lastActiveDate: DateTime(2026, 10, 13, 7),
          today: today,
          currentStreak: 4,
        ),
        4,
      );
    });

    test('hari berbeda berturut-turut menambah satu', () {
      expect(
        computeStreak(
          lastActiveDate: DateTime(2026, 10, 12, 23, 59),
          today: today,
          currentStreak: 4,
        ),
        5,
      );
    });

    test('terlewat satu hari penuh mereset ke 1', () {
      expect(
        computeStreak(
          lastActiveDate: DateTime(2026, 10, 11, 10),
          today: today,
          currentStreak: 7,
        ),
        1,
      );
    });

    test('lewat tengah malam dihitung per tanggal kalender', () {
      expect(
        computeStreak(
          lastActiveDate: DateTime(2026, 10, 12, 23, 55),
          today: DateTime(2026, 10, 13, 0, 5),
          currentStreak: 2,
        ),
        3,
      );
    });

    test('tanggal berjalan mundur tidak menambah streak', () {
      expect(
        computeStreak(
          lastActiveDate: DateTime(2026, 10, 14),
          today: today,
          currentStreak: 5,
        ),
        5,
      );
    });
  });
}
