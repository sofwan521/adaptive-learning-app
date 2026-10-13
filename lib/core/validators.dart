// Fungsi validasi murni untuk formulir. Mengembalikan pesan galat
// Bahasa Indonesia, atau null bila nilai valid.
//
// Logika murni — tanpa import Flutter.
String? validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Surel tidak boleh kosong.';
  final emailPattern =
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
  if (!emailPattern.hasMatch(text)) return 'Format surel tidak valid.';
  return null;
}

/// Kata sandi minimal 8 karakter dan mengandung huruf serta angka.
String? validatePassword(String? value) {
  final text = value ?? '';
  if (text.isEmpty) return 'Kata sandi tidak boleh kosong.';
  if (text.length < 8) return 'Kata sandi minimal 8 karakter.';
  if (!RegExp(r'[A-Za-z]').hasMatch(text) ||
      !RegExp(r'[0-9]').hasMatch(text)) {
    return 'Kata sandi harus mengandung huruf dan angka.';
  }
  return null;
}

/// Nama 3 sampai 50 karakter (dirapikan dari spasi tepi).
String? validateName(String? value) {
  final text = value?.trim() ?? '';
  if (text.length < 3) return 'Nama minimal 3 karakter.';
  if (text.length > 50) return 'Nama maksimal 50 karakter.';
  return null;
}

/// Konfirmasi kata sandi harus sama dengan kata sandi.
String? validateConfirmPassword(String? password, String? confirm) {
  if ((confirm ?? '').isEmpty) {
    return 'Konfirmasi kata sandi tidak boleh kosong.';
  }
  if (password != confirm) return 'Konfirmasi kata sandi tidak sama.';
  return null;
}

/// Kode kelas: tepat 6 karakter alfanumerik.
String? validateClassCode(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Kode kelas tidak boleh kosong.';
  if (text.length != 6) return 'Kode kelas harus 6 karakter.';
  if (!RegExp(r'^[A-Za-z0-9]{6}$').hasMatch(text)) {
    return 'Kode kelas hanya boleh huruf dan angka.';
  }
  return null;
}
