import 'package:flutter/material.dart';

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
