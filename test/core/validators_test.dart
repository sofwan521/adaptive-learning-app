import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/core/validators.dart';

void main() {
  group('validateEmail', () {
    test('menerima surel valid', () {
      expect(validateEmail('siswa@contoh.id'), isNull);
      expect(validateEmail('  guru@sekolah.sch.id  '), isNull);
    });

    test('menolak surel kosong dan format salah', () {
      expect(validateEmail(null), 'Surel tidak boleh kosong.');
      expect(validateEmail('  '), 'Surel tidak boleh kosong.');
      expect(validateEmail('tanpa-at'), 'Format surel tidak valid.');
      expect(validateEmail('a@b'), 'Format surel tidak valid.');
      expect(validateEmail('a@b.'), 'Format surel tidak valid.');
    });
  });

  group('validatePassword', () {
    test('menerima sandi kuat', () {
      expect(validatePassword('sandi123'), isNull);
      expect(validatePassword('Belajar2026'), isNull);
    });

    test('menolak sandi lemah dengan pesan tepat', () {
      expect(validatePassword(null), 'Kata sandi tidak boleh kosong.');
      expect(validatePassword('Abc12'), 'Kata sandi minimal 8 karakter.');
      expect(
        validatePassword('sandidulu'),
        'Kata sandi harus mengandung huruf dan angka.',
      );
      expect(
        validatePassword('12345678'),
        'Kata sandi harus mengandung huruf dan angka.',
      );
    });
  });

  group('validateName', () {
    test('menerima nama 3 sampai 50 karakter', () {
      expect(validateName('Budi'), isNull);
      expect(validateName('A' * 50), isNull);
    });

    test('menolak nama terlalu pendek atau panjang', () {
      expect(validateName('Bo'), 'Nama minimal 3 karakter.');
      expect(validateName('  '), 'Nama minimal 3 karakter.');
      expect(validateName('A' * 51), 'Nama maksimal 50 karakter.');
    });
  });

  group('validateConfirmPassword', () {
    test('menerima konfirmasi yang sama', () {
      expect(validateConfirmPassword('sandi123', 'sandi123'), isNull);
    });

    test('menolak konfirmasi kosong atau berbeda', () {
      expect(
        validateConfirmPassword('sandi123', ''),
        'Konfirmasi kata sandi tidak boleh kosong.',
      );
      expect(
        validateConfirmPassword('sandi123', 'sandi124'),
        'Konfirmasi kata sandi tidak sama.',
      );
    });
  });

  group('validateClassCode', () {
    test('menerima kode 6 karakter alfanumerik', () {
      expect(validateClassCode('AB12CD'), isNull);
      expect(validateClassCode('  xk9q2z  '), isNull);
    });

    test('menolak kode salah dengan pesan tepat', () {
      expect(validateClassCode(null), 'Kode kelas tidak boleh kosong.');
      expect(validateClassCode('AB12'), 'Kode kelas harus 6 karakter.');
      expect(validateClassCode('AB12CD3'), 'Kode kelas harus 6 karakter.');
      expect(
        validateClassCode('AB-12C'),
        'Kode kelas hanya boleh huruf dan angka.',
      );
    });
  });
}
