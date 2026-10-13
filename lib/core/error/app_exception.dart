// Galat aplikasi dengan pesan Bahasa Indonesia yang ramah.
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Galat domain/aplikasi. Semua repository memetakan galat mentah
/// (Supabase, jaringan) ke galat ini agar UI cukup menampilkan [message].
class AppException implements Exception {
  /// Pesan Bahasa Indonesia yang ramah untuk pengguna.
  final String message;

  /// Kode teknis opsional (mis. kode Postgrest) untuk diagnostik.
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: $message';
}

/// Memetakan galat mentah ke [AppException] berbahasa Indonesia.
AppException mapToAppException(
  Object error, {
  String fallback = 'Terjadi kesalahan. Silakan coba lagi.',
}) {
  if (error is AppException) return error;
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return const AppException(
          'Surel atau kata sandi salah. Silakan coba lagi.');
    }
    if (message.contains('user already registered') ||
        message.contains('already exists')) {
      return const AppException(
          'Surel sudah terdaftar. Silakan masuk.');
    }
    if (message.contains('email not confirmed') ||
        message.contains('not confirmed')) {
      return const AppException(
          'Surel belum diverifikasi. Periksa kotak masuk Anda.');
    }
    if (message.contains('password')) {
      return const AppException(
          'Kata sandi tidak memenuhi syarat. Gunakan minimal 6 karakter.');
    }
    return const AppException('Gagal autentikasi. Silakan coba lagi.');
  }
  if (error is PostgrestException) {
    if (error.code == '42501') {
      return AppException(
          'Anda tidak memiliki akses untuk data ini.', error.code);
    }
    if (error.code == 'PGRST116') {
      return AppException('Data tidak ditemukan.', error.code);
    }
    return const AppException('Gagal memuat data. Silakan coba lagi.');
  }
  if (isOfflineError(error)) {
    return const AppException(
        'Tidak ada koneksi internet. Silakan coba lagi.');
  }
  return AppException(fallback);
}

/// True bila [error] menandakan perangkat sedang luring.
bool isOfflineError(Object error) {
  if (error is SocketException || error is TimeoutException) return true;
  if (error is http.ClientException) return true;
  if (error is PostgrestException) {
    final message = error.message.toLowerCase();
    return message.contains('failed to fetch') ||
        message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection');
  }
  return false;
}
