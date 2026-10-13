import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/app.dart';
import 'package:adaptive_learning_app/features/auth/presentation/splash_screen.dart';

void main() {
  testWidgets('Splash menampilkan nama aplikasi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen()),
    );

    expect(find.text('AdaptiLearn'), findsOneWidget);
    expect(find.text('Memuat…'), findsOneWidget);
  });

  testWidgets('Aplikasi dibuka lalu login saat belum masuk',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AdaptiLearnApp()));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Pemeriksaan sesi selesai (tanpa backend) -> diarahkan ke login.
    expect(find.text('Lanjutkan belajarmu di AdaptiLearn'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
  });
}
