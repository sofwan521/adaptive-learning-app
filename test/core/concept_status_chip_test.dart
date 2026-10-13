import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/core/widgets/concept_status_chip.dart';
import 'package:adaptive_learning_app/domain/models/concept_status.dart';

Future<void> _pumpChip(WidgetTester tester, ConceptStatus status) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(child: ConceptStatusChip(status: status)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ConceptStatusChip', () {
    testWidgets('menampilkan label Bahasa Indonesia tiap status', (
      tester,
    ) async {
      const expectations = {
        ConceptStatus.locked: 'Terkunci',
        ConceptStatus.open: 'Terbuka',
        ConceptStatus.learning: 'Dipelajari',
        ConceptStatus.mastered: 'Dikuasai',
      };
      for (final entry in expectations.entries) {
        await _pumpChip(tester, entry.key);
        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('memakai ikon berbeda tiap status', (tester) async {
      const expectations = {
        ConceptStatus.locked: Icons.lock,
        ConceptStatus.open: Icons.lock_open,
        ConceptStatus.learning: Icons.menu_book,
        ConceptStatus.mastered: Icons.check_circle,
      };
      for (final entry in expectations.entries) {
        await _pumpChip(tester, entry.key);
        expect(find.byIcon(entry.value), findsOneWidget);
      }
    });

    testWidgets('tooltip sama dengan label status', (tester) async {
      await _pumpChip(tester, ConceptStatus.mastered);

      expect(
        find.byTooltip('Dikuasai'),
        findsOneWidget,
      );
    });

    testWidgets('teks kontras di atas latar chip semua status', (
      tester,
    ) async {
      for (final status in ConceptStatus.values) {
        await _pumpChip(tester, status);

        final text = tester.widget<Text>(find.text(status.label));
        final color = text.style?.color;
        expect(color, isNotNull);

        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.text(status.label),
                matching: find.byType(Container),
              )
              .first,
        );
        final background =
            (container.decoration as BoxDecoration?)?.color;
        expect(background, isNotNull);

        // Kontras luminance latar vs teks harus memadai (WCAG AA).
        final contrast = _contrastRatio(background!, color!);
        expect(
          contrast,
          greaterThanOrEqualTo(4.5),
          reason: 'kontras chip $status = $contrast',
        );
      }
    });
  });
}

/// Rasio kontras WCAG antara dua warna.
double _contrastRatio(Color background, Color foreground) {
  double linearize(double c) {
    return c <= 0.04045
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  double luminance(Color color) {
    return 0.2126 * linearize(color.r) +
        0.7152 * linearize(color.g) +
        0.0722 * linearize(color.b);
  }

  final lumaBackground = luminance(background);
  final lumaForeground = luminance(foreground);
  final lighter = math.max(lumaBackground, lumaForeground);
  final darker = math.min(lumaBackground, lumaForeground);
  return (lighter + 0.05) / (darker + 0.05);
}
