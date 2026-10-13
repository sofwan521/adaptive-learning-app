import 'package:flutter/material.dart';

import '../../../domain/models/concept_status.dart';

/// Gaya visual satu status pada peta konsep.
///
/// Selaras dengan [ConceptStatusChip]: tiap status punya ikon dan
/// pasangan warna isi/garis yang kontras (bukan warna saja).
class KnowledgeMapStatusStyle {
  /// Warna isi kartu node.
  final Color fill;

  /// Warna garis tepi dan ikon.
  final Color border;

  /// Ikon status: gembok, bintang, buku, centang.
  final IconData icon;

  const KnowledgeMapStatusStyle({
    required this.fill,
    required this.border,
    required this.icon,
  });
}

/// Gaya kartu node untuk [status].
KnowledgeMapStatusStyle mapStatusStyle(ConceptStatus status) {
  switch (status) {
    case ConceptStatus.locked:
      return const KnowledgeMapStatusStyle(
        fill: Color(0xFFE2E8E4),
        border: Color(0xFF3D4A43),
        icon: Icons.lock,
      );
    case ConceptStatus.open:
      return const KnowledgeMapStatusStyle(
        fill: Color(0xFFD8E8FB),
        border: Color(0xFF174A7C),
        icon: Icons.star,
      );
    case ConceptStatus.learning:
      return const KnowledgeMapStatusStyle(
        fill: Color(0xFFFFECB3),
        border: Color(0xFF6B4E00),
        icon: Icons.menu_book,
      );
    case ConceptStatus.mastered:
      return const KnowledgeMapStatusStyle(
        fill: Color(0xFFCDEEDC),
        border: Color(0xFF0B5C36),
        icon: Icons.check_circle,
      );
  }
}
