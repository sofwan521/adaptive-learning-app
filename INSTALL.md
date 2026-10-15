# Adaptive Learning App - Instalasi dan Running

## Langkah Cepat untuk Running Aplikasi

### 1. Buka di Android Studio

1. Buka Android Studio
2. Pilih **File** → **Open**
3. Navigasi ke folder: `C:\Users\sofwa\adaptive_learning_app`
4. Klik **OK**

### 2. Install Dependencies

Setelah project terbuka, Android Studio akan otomatis mendeteksi `pubspec.yaml`. Jika tidak:

1. Buka Terminal di Android Studio (Alt+F12)
2. Jalankan:
```bash
flutter pub get
```

Tunggu sampai semua package terdownload (bisa 1-3 menit tergantung koneksi).

### 3. Setup Emulator atau Device

**Option A - Menggunakan Emulator:**
1. Klik icon **Device Manager** di toolbar
2. Buat emulator baru atau gunakan yang ada
3. Pastikan minimal:
   - Android API Level 21 (Android 5.0) atau lebih
   - RAM minimal 3 GB
4. Start emulator

**Option B - Menggunakan Physical Device:**
1. Aktifkan **Developer Options** di HP Android
2. Aktifkan **USB Debugging**
3. Sambungkan HP ke komputer via USB
4. Klik **Allow** pada HP ketika muncul prompt

### 4. Run Aplikasi

**Cara 1 - Via Android Studio:**
1. Pastikan device sudah terpilih di toolbar (klik dropdown device)
2. Klik tombol **Run** (▶️) hijau di toolbar
3. Atau tekan **Shift + F10**

**Cara 2 - Via Terminal (wajib sertakan kredensial Supabase):**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=isi-anon-key-di-sini
```

> Tanpa `--dart-define`, aplikasi tidak terhubung ke backend dan akan
> terpental ke halaman login (ada spanduk peringatan di layar Masuk).
> Ambil nilainya dari dashboard Supabase → *Project Settings → Data API*.

### 5. Login ke Aplikasi

Setelah aplikasi terbuka, gunakan akun demo:

**Akun Siswa:**
- Email: `student@test.com`
- Password: `password`

**Akun Guru:**
- Email: `teacher@test.com`  
- Password: `password`

## Troubleshooting

### Error: "flutter command not found"
- Pastikan Flutter SDK sudah terinstall
- Tambahkan Flutter ke PATH environment variable
- Restart terminal/command prompt

### Error: "Gradle build failed"
- Jalankan: `flutter clean` kemudian `flutter pub get`
- Pastikan koneksi internet stabil
- Coba jalankan lagi

### Error: "No devices found"
- Pastikan emulator sudah running
- Atau USB debugging sudah aktif di HP
- Jalankan `flutter devices` untuk cek device

### Aplikasi lambat/lag
- Gunakan mode release: `flutter run --release`
- Pastikan emulator/device memiliki RAM cukup
- Close aplikasi lain yang running

### Hot Reload tidak bekerja
- Tekan `r` di terminal untuk hot reload manual
- Tekan `R` untuk hot restart
- Atau gunakan icon lightning di Android Studio

## Fitur Utama yang Bisa Dicoba

1. **Placement Test** - Klik tombol "Mulai Test" di home screen
2. **Peta Konsep** - Menu drawer → Peta Konsep
3. **Kuis Adaptif** - Pilih konsep → Mulai Kuis
4. **Progress Tracking** - Menu drawer → Progress
5. **Profile & Gamification** - Menu drawer → Profile

## Build APK untuk Install di HP

Jika ingin install tanpa kabel:

```bash
flutter build apk --release
```

File APK akan ada di:
`build/app/outputs/flutter-apk/app-release.apk`

Copy file tersebut ke HP dan install.

## Kontak Support

Jika ada masalah:
- Dika Muhammad: 240605110158
- Sofwan Hakim: 240605110181

---

**Selamat Mencoba! 🚀**
