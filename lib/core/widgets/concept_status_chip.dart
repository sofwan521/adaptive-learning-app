import 'package:flutter/material.dart';

import '../../domain/models/concept_status.dart';

/// Chip status konsep dengan ikon DAN warna (bukan warna saja).
///
/// Setiap status punya ikon, label Bahasa Indonesia, serta pasangan
/// warna latar/depan yang kontras agar tetap terbaca.
class ConceptStatusChip extends StatelessWidget {
  final ConceptStatus status;

  const ConceptStatusChip({super.key, required this.status});

  (_StatusStyle, IconData) get _style {
    switch (status) {
      case ConceptStatus.locked:
        return (
          const _StatusStyle(
            background: Color(0xFFE2E8E4),
            foreground: Color(0xFF3D4A43),
          ),
          Icons.lock
        );
      case ConceptStatus.open:
        return (
          const _StatusStyle(
            background: Color(0xFFD8E8FB),
            foreground: Color(0xFF174A7C),
          ),
          Icons.lock_open
        );
      case ConceptStatus.learning:
        return (
          const _StatusStyle(
            background: Color(0xFFFFECB3),
            foreground: Color(0xFF6B4E00),
          ),
          Icons.menu_book
        );
      case ConceptStatus.mastered:
        return (
          const _StatusStyle(
            background: Color(0xFFCDEEDC),
            foreground: Color(0xFF0B5C36),
          ),
          Icons.check_circle
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (style, icon) = _style;
    return Tooltip(
      message: status.label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: style.foreground.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: style.foreground),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: style.foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color background;
  final Color foreground;

  const _StatusStyle({required this.background, required this.foreground});
}
