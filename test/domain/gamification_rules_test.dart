import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/domain/gamification/gamification_rules.dart';

void main() {
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
