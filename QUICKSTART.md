# 🎓 Adaptive Learning App - Panduan Lengkap

## ✅ Status Project

Project Flutter untuk Adaptive Learning App **SUDAH SIAP RUNNING!**

### File yang Sudah Dibuat:

#### 📱 Core Files
- ✅ `lib/main.dart` - Entry point aplikasi
- ✅ `pubspec.yaml` - Dependencies dan konfigurasi
- ✅ `analysis_options.yaml` - Dart analyzer config
- ✅ `.gitignore` - Git ignore rules

#### 🧠 Core Services & Models
- ✅ `lib/core/models/user.dart`
- ✅ `lib/core/models/concept.dart`
- ✅ `lib/core/models/question.dart`
- ✅ `lib/core/models/quiz_response.dart`
- ✅ `lib/core/services/auth_service.dart`
- ✅ `lib/core/services/irt_service.dart` - **IRT 2PL Implementation**
- ✅ `lib/core/services/knowledge_graph_service.dart` - **Graph Algorithms**
- ✅ `lib/core/routes/app_router.dart`

#### 🎨 UI Screens
- ✅ `lib/features/auth/screens/login_screen.dart`
- ✅ `lib/features/auth/screens/register_screen.dart`
- ✅ `lib/features/home/screens/home_screen.dart`
- ✅ `lib/features/placement_test/screens/placement_test_screen.dart`
- ✅ `lib/features/placement_test/screens/placement_result_screen.dart`
- ✅ `lib/features/learning/screens/concept_map_screen.dart`
- ✅ `lib/features/learning/screens/quiz_screen.dart`
- ✅ `lib/features/learning/screens/learning_material_screen.dart`
- ✅ `lib/features/progress/screens/progress_screen.dart`
- ✅ `lib/features/profile/screens/profile_screen.dart`

#### 📊 State Management (Providers)
- ✅ `lib/features/auth/providers/auth_provider.dart`
- ✅ `lib/features/learning/providers/learning_provider.dart`
- ✅ `lib/features/progress/providers/progress_provider.dart`

#### 🤖 Android Configuration
- ✅ `android/app/build.gradle`
- ✅ `android/build.gradle`
- ✅ `android/settings.gradle`
- ✅ `android/app/src/main/AndroidManifest.xml`
- ✅ `android/app/src/main/kotlin/.../MainActivity.kt`

#### 📖 Documentation
- ✅ `README.md` - Dokumentasi lengkap
- ✅ `INSTALL.md` - Panduan instalasi step-by-step

---

## 🚀 CARA RUNNING APLIKASI

### Opsi 1: Via Android Studio (RECOMMENDED)

1. **Buka Android Studio**

2. **Open Project**
   - File → Open
   - Pilih folder: `C:\Users\sofwa\adaptive_learning_app`
   - Klik OK

3. **Install Dependencies**
   - Android Studio akan auto-detect pubspec.yaml
   - Klik "Pub get" yang muncul di banner atas
   - Atau buka Terminal dan jalankan:
     ```bash
     flutter pub get
     ```

4. **Setup Device**
   - Start emulator Android (Device Manager di toolbar)
   - Atau sambungkan HP Android dengan USB debugging aktif

5. **Run!**
   - Klik tombol Run (▶️) hijau di toolbar
   - Atau tekan `Shift + F10`

### Opsi 2: Via Command Line

```bash
# Masuk ke folder project
cd C:\Users\sofwa\adaptive_learning_app

# Install dependencies
flutter pub get

# Check devices
flutter devices

# Run aplikasi
flutter run

# Atau dalam release mode (lebih cepat)
flutter run --release
```

---

## 👤 LOGIN KE APLIKASI

Setelah aplikasi terbuka, gunakan akun demo:

### Akun Siswa (Recommended untuk testing lengkap)
```
Email: student@test.com
Password: password
```

### Akun Guru
```
Email: teacher@test.com
Password: password
```

---

## 🎯 FITUR YANG BISA DICOBA

### 1. Placement Test (⭐ FITUR UTAMA)
- Login sebagai siswa
- Klik tombol "Mulai Test" di home screen
- Jawab 5 soal adaptif
- Sistem akan mengukur kemampuan menggunakan **IRT 2PL**
- Lihat hasil theta dan level kemampuan

### 2. Peta Konsep (Knowledge Graph)
- Buka menu drawer (☰)
- Pilih "Peta Konsep"
- Lihat visualisasi konsep matematika
- Konsep dengan ✅ = sudah dikuasai
- Konsep dengan 🔵 = tersedia untuk dipelajari
- Konsep dengan 🔒 = terkunci (perlu prasyarat)

### 3. Belajar & Quiz
- Pilih konsep yang tersedia (warna biru)
- Pelajari materi
- Klik "Mulai Kuis"
- Jawab soal dengan adaptif
- Dapatkan XP dan level up!

### 4. Progress Tracking
- Menu drawer → Progress
- Lihat grafik pembelajaran
- Cek akurasi jawaban
- Monitor streak harian

### 5. Gamification
- Kumpulkan XP dari quiz
- Level up (setiap 100 XP = 1 level)
- Pertahankan streak belajar harian
- Lihat achievement di Profile

---

## 🧮 TEKNOLOGI & ALGORITMA

### IRT (Item Response Theory)
```dart
// Model 2PL
P(θ) = 1 / (1 + e^(-a(θ - b)))

// Adaptive Selection - Maximum Information
I(θ) = a² * P(θ) * (1 - P(θ))
```

**Implementasi:**
- `lib/core/services/irt_service.dart`
- Newton-Raphson untuk estimasi theta
- Adaptive question selection
- Standard Error of Measurement (SEM)

### Knowledge Graph
```dart
// Topological Sort untuk learning path
// DFS/BFS untuk remedial path
// Lock/Unlock berdasarkan prerequisites
```

**Implementasi:**
- `lib/core/services/knowledge_graph_service.dart`
- Graph traversal algorithms
- Dependency resolution
- Automatic remedial recommendations

---

## 📦 DEPENDENCIES UTAMA

```yaml
flutter_sdk: flutter
provider: ^6.1.1          # State management
go_router: ^13.0.0        # Navigation
shared_preferences: ^2.2.2 # Local storage
fl_chart: ^0.66.0         # Charts
graphview: ^1.2.0         # Graph visualization
google_fonts: ^6.1.0      # Typography
crypto: ^3.0.3            # Password hashing
```

---

## 🐛 TROUBLESHOOTING

### Error: "flutter command not found"
**Solusi:**
```bash
# Pastikan Flutter di PATH
# Atau jalankan dengan full path
C:\path\to\flutter\bin\flutter pub get
```

### Error: "Gradle build failed"
**Solusi:**
```bash
flutter clean
flutter pub get
flutter run
```

### Error: "No devices found"
**Solusi:**
- Start emulator dari Android Studio
- Atau aktifkan USB debugging di HP
- Cek dengan: `flutter devices`

### Aplikasi lambat di emulator
**Solusi:**
```bash
# Gunakan release mode
flutter run --release
```

### Hot reload tidak bekerja
**Solusi:**
- Tekan `r` di terminal untuk hot reload
- Tekan `R` untuk hot restart
- Atau gunakan icon di Android Studio

---

## 📱 BUILD APK

Untuk install di HP tanpa kabel:

```bash
# Build APK release
flutter build apk --release

# Atau split per ABI (ukuran lebih kecil)
flutter build apk --split-per-abi

# File output:
# build/app/outputs/flutter-apk/app-release.apk
```

Copy APK ke HP dan install.

---

## 🎨 STRUKTUR PROJECT

```
adaptive_learning_app/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── core/
│   │   ├── models/                  # Data models
│   │   ├── services/                # Business logic
│   │   │   ├── irt_service.dart     # ⭐ IRT implementation
│   │   │   └── knowledge_graph_service.dart  # ⭐ Graph algorithms
│   │   └── routes/
│   └── features/
│       ├── auth/
│       ├── home/
│       ├── placement_test/          # ⭐ Adaptive test
│       ├── learning/
│       │   └── screens/
│       │       ├── concept_map_screen.dart   # ⭐ Knowledge graph UI
│       │       └── quiz_screen.dart          # ⭐ Adaptive quiz
│       ├── progress/
│       └── profile/
├── android/                         # Android configuration
├── pubspec.yaml                     # Dependencies
└── README.md
```

---

## 📊 DATA MOCK

Aplikasi menggunakan data mock untuk demo:

### Konsep Matematika:
1. **Bilangan Bulat** (Level 1) - Tidak ada prasyarat
2. **Pecahan** (Level 2) - Prasyarat: Bilangan Bulat
3. **Persamaan Linear** (Level 2) - Prasyarat: Bilangan Bulat
4. **Persamaan Kuadrat** (Level 3) - Prasyarat: Persamaan Linear
5. **Fungsi** (Level 3) - Prasyarat: Persamaan Linear

### Parameter IRT Soal:
- Difficulty (b): -1.5 hingga 1.0
- Discrimination (a): 1.0 hingga 1.5
- Soal dipilih adaptif berdasarkan theta siswa

---

## 🔮 FITUR FUTURE

- [ ] Backend API integration
- [ ] Teacher dashboard
- [ ] Real-time multiplayer quiz
- [ ] AI-powered tutoring
- [ ] Video pembelajaran
- [ ] Export PDF reports
- [ ] Multi-subject support
- [ ] Leaderboard & social features

---

## 👨‍💻 DEVELOPER

**Kelompok 2:**
- Dika Muhammad Iqbal Marangga - 240605110158
- Sofwan Hakim Sayyidan - 240605110181

**Dosen Pengampu:**
SUPRIYONO, M.Kom

**Program Studi Teknik Informatika**  
Fakultas Sains dan Teknologi  
Universitas Islam Negeri Maulana Malik Ibrahim Malang  
2026

---

## 📞 SUPPORT

Ada masalah atau pertanyaan?
- Buka issue di repository
- Atau hubungi developer

---

## ⚡ QUICK START CHECKLIST

- [ ] Buka project di Android Studio
- [ ] Jalankan `flutter pub get`
- [ ] Start emulator atau sambungkan HP
- [ ] Klik Run (▶️)
- [ ] Login dengan `student@test.com` / `password`
- [ ] Coba Placement Test
- [ ] Explore Knowledge Graph
- [ ] Ambil quiz dan dapatkan XP!

---

**🎉 SELAMAT MENGGUNAKAN ADAPTIVE LEARNING APP! 🎉**

Aplikasi siap running dan semua fitur utama sudah terimplementasi!
