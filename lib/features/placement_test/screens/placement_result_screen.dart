import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlacementResultScreen extends StatelessWidget {
  final num theta;
  final Object level;

  const PlacementResultScreen({
    super.key,
    required this.theta,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Placement Test'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.emoji_events,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Test Selesai!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Level kamu'),
                    const SizedBox(height: 8),
                    Text(
                      level.toString(),
                      style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Kemampuan (theta): ${theta.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mulai Belajar'),
            ),
          ],
        ),
      ),
    );
  }
}