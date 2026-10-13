import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider aplikasi untuk layar awal.
///
/// Placeholder berarti: judul + status屏 siap dalam Bahasa Indonesia.
final appTitleProvider = Provider<String>((ref) => 'AdaptiLearn');

/// Status pesan selamat datang.
final welcomeMessageProvider = Provider<String>(
  (ref) => 'Selamat datang di AdaptiLearn',
);
