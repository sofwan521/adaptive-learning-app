import 'package:equatable/equatable.dart';

/// Katalog lencana AdaptiLearn.
///
/// Kode stabil dipakai sebagai kunci di tabel `badges`/`user_badges`
/// dan diuji lewat kontrak repository. Ikon dipetakan di lapisan
/// presentasi agar domain tetap murni.
///
/// Logika murni — tanpa import Flutter.
class AppBadge extends Equatable {
  /// Kode stabil (kolom `code`).
  final String code;

  /// Nama tampilan Bahasa Indonesia.
  final String name;

  /// Syarat memperoleh, Bahasa Indonesia.
  final String description;

  const AppBadge({
    required this.code,
    required this.name,
    required this.description,
  });

  @override
  List<Object?> get props => [code, name, description];
}

/// Lencana sesi kuis pertama yang diselesaikan.
const badgeFirstSteps = AppBadge(
  code: 'langkah-pertama',
  name: 'Langkah Pertama',
  description: 'Menyelesaikan sesi kuis pertama.',
);

/// Lencana belajar 3 hari berturut-turut.
const badgeStreak3 = AppBadge(
  code: 'beruntun-3',
  name: '3 Hari Beruntun',
  description: 'Belajar 3 hari berturut-turut.',
);

/// Lencana konsep pertama yang dikuasai.
const badgeFirstMastery = AppBadge(
  code: 'konsep-pertama',
  name: 'Konsep Pertama Dikuasai',
  description: 'Menguasai 1 konsep pertama.',
);

/// Lencana penguasaan lewat jalur remedial.
const badgeRemedialHero = AppBadge(
  code: 'pahlawan-remedial',
  name: 'Pahlawan Remedial',
  description: 'Menguasai konsep lewat jalur remedial.',
);

/// Seluruh lencana berurutan tampil.
const List<AppBadge> kAppBadges = [
  badgeFirstSteps,
  badgeStreak3,
  badgeFirstMastery,
  badgeRemedialHero,
];
