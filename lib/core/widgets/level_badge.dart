import 'package:flutter/material.dart';

/// Lencana level dengan animasi kecil saat level naik.
///
/// [AnimatedSwitcher] yang dikunci pada nilai [level] membuat
/// pergantian angka terasa memantul setiap kali level bertambah.
class LevelBadge extends StatelessWidget {
  final int level;

  const LevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.tertiary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.military_tech,
            size: 16,
            color: colors.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
              ),
              child: child,
            ),
            child: Text(
              'Level $level',
              key: ValueKey<int>(level),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ikon lencana per kode (pemetaan terpusat agar konsisten
/// di Beranda, Profil, dan layar hasil).
IconData badgeIconFor(String code) {
  switch (code) {
    case 'langkah-pertama':
      return Icons.directions_walk;
    case 'beruntun-3':
      return Icons.local_fire_department;
    case 'konsep-pertama':
      return Icons.workspace_premium_outlined;
    case 'pahlawan-remedial':
      return Icons.health_and_safety_outlined;
    default:
      return Icons.emoji_events_outlined;
  }
}
