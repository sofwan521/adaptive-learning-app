import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/core/theme/app_theme.dart';
import 'package:adaptive_learning_app/core/widgets/widgets.dart';
import 'package:adaptive_learning_app/domain/models/concept_status.dart';
import 'package:adaptive_learning_app/features/dev/presentation/gallery_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.light(), home: Scaffold(body: child));
}

void main() {
  testWidgets('Galeri menampilkan semua komponen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const GalleryScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Galeri Komponen'), findsOneWidget);
    expect(find.text('Tombol Primer'), findsOneWidget);
    expect(find.text('Tombol Sekunder'), findsOneWidget);
    for (final status in ConceptStatus.values) {
      expect(find.text(status.label), findsWidgets);
    }
    expect(find.text('50 XP'), findsOneWidget);
    expect(find.text('Memuat materi…'), findsOneWidget);
  });

  testWidgets('AppButton loading menonaktifkan tombol', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      _wrap(
        AppButton(
          label: 'Simpan',
          isLoading: true,
          onPressed: () => pressed = true,
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(pressed, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppTextField sandi bisa dilihat', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppTextField(label: 'Kata sandi', obscureText: true)),
    );

    expect(find.byIcon(Icons.visibility), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });

  testWidgets('ErrorView menampilkan tombol coba lagi', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      _wrap(ErrorView(message: 'Gagal', onRetry: () => retried = true)),
    );

    await tester.tap(find.text('Coba lagi'));
    expect(retried, isTrue);
  });

  test('Tema memakai warna dan ukuran yang ditentukan', () {
    final theme = AppTheme.light();
    expect(theme.colorScheme.primary, const Color(0xFF1B8A5A));
    expect(theme.colorScheme.secondary, const Color(0xFFFFC107));
    expect(theme.colorScheme.error, const Color(0xFFD32F2F));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF7FAF8));
    expect(theme.textTheme.bodyMedium?.fontSize, 16);
    expect(
      theme.filledButtonTheme.style?.minimumSize?.resolve({}),
      const Size(48, 48),
    );
  });
}
