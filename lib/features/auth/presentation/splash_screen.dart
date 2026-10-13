import 'package:flutter/material.dart';

/// Layar pembuka yang tampil saat sesi diperiksa.
///
/// Tanpa logika bisnis — navigasi diatur redirect router.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('AdaptiLearn', style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Belajar sesuai kemampuanmu',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text('Memuat…', style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
