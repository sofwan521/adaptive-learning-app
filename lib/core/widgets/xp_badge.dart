import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Lencana XP dengan ikon bintang dan teks.
class XpBadge extends StatelessWidget {
  final int xp;

  const XpBadge({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Color(0xFF6B4E00)),
          const SizedBox(width: 6),
          Text(
            '$xp XP',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF6B4E00),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
