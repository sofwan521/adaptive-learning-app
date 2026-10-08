# Adaptive Learning App

Aplikasi mobile pembelajaran adaptif berbasis **Knowledge Graph** dan **Item Response Theory (IRT)** untuk mata pelajaran Matematika.

## 📱 Fitur Utama

- **Placement Test Adaptif** - Mengukur kemampuan siswa menggunakan algoritma IRT 2PL
- **Knowledge Graph** - Peta konsep dengan visualisasi dependencies antar materi
- **Adaptive Learning** - Materi dan soal menyesuaikan kemampuan siswa secara real-time
- **Remedial Path** - Sistem otomatis merekomendasikan materi prasyarat yang perlu dipelajari
- **Progress Dashboard** - Tracking kemampuan dengan grafik dan analitik
- **Gamification** - XP, Level, dan Streak untuk meningkatkan motivasi belajar

## 🏗️ Teknologi

- **Flutter** 3.0+
- **Provider** - State Management
- **Go Router** - Navigation
- **Shared Preferences** - Local Storage
- **FL Chart** - Data Visualization
- **GraphView** - Knowledge Graph Visualization

## 📋 Prasyarat

- Flutter SDK 3.0 atau lebih baru
- Android Studio / VS Code dengan Flutter extension
- Android SDK (untuk Android) atau Xcode (untuk iOS)
- Dart SDK

## 🚀 Cara Menjalankan

### 1. Install Dependencies

```bash
cd C:\Users\sofwa\adaptive_learning_app
flutter pub get
```

### 2. Jalankan Aplikasi

**Menggunakan Android Studio:**
1. Buka folder `adaptive_learning_app` di Android Studio
2. Buka file `lib/main.dart`
3. Pilih device/emulator
4. Klik tombol Run (▶️) atau tekan `Shift + F10`

**Menggunakan Command Line:**
```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Pilih device spesifik
flutter devices
flutter run -d <device-id>
```

### 3. Build APK (Optional)

```bash
# Build APK untuk testing
flutter build apk

# Build APK split per ABI (ukuran lebih kecil)
flutter build apk --split-per-abi

# Output: build/app/outputs/flutter-apk/
```

## 👤 Akun Demo

**Siswa:**
- Email: `student@test.com`
- Password: `password`

**Guru:**
- Email: `teacher@test.com`
- Password: `password`

## 📁 Struktur Folder

```
lib/
├── main.dart                          # Entry point aplikasi
├── core/                              # Core functionality
│   ├── models/                        # Data models
│   │   ├── user.dart
│   │   ├── concept.dart
│   │   ├── question.dart
│   │   └── quiz_response.dart
│   ├── services/                      # Business logic
│   │   ├── auth_service.dart
│   │   ├── irt_service.dart          # IRT implementation
│   │   └── knowledge_graph_service.dart
│   └── routes/
│       └── app_router.dart            # Navigation
└── features/                          # Feature modules
    ├── auth/
    │   ├── providers/
    │   └── screens/
    ├── home/
    ├── placement_test/
    ├── learning/
    │   ├── providers/
    │   └── screens/
    │       ├── concept_map_screen.dart
    │       ├── quiz_screen.dart
    │       └── learning_material_screen.dart
    ├── progress/
    └── profile/
```

## 🧮 Algoritma IRT (Item Response Theory)

Aplikasi menggunakan **2PL (Two-Parameter Logistic) Model**:

```
P(θ) = 1 / (1 + e^(-a(θ - b)))
```

Dimana:
- `θ` (theta) = Kemampuan siswa
- `a` = Discrimination parameter (daya pembeda soal)
- `b` = Difficulty parameter (tingkat kesulitan soal)
- `P(θ)` = Probabilitas jawaban benar

**Adaptive Selection:**
Soal dipilih berdasarkan **maximum information** pada theta siswa saat ini:

```
I(θ) = a² * P(θ) * (1 - P(θ))
```

## 🗺️ Knowledge Graph

Knowledge Graph merepresentasikan:
- **Nodes** = Konsep matematika
- **Edges** = Hubungan prasyarat (prerequisite)

**Algoritma yang digunakan:**
- **Topological Sort** - Menentukan urutan belajar optimal
- **DFS/BFS** - Penelusuran graf untuk remedial path
- **Lock/Unlock Logic** - Konsep terkunci sampai prasyarat dikuasai

## 🎯 Fitur yang Akan Datang

- [ ] Teacher dashboard untuk monitoring siswa
- [ ] Bank soal dinamis dari server
- [ ] Video pembelajaran terintegrasi
- [ ] Chat dengan guru/AI tutor
- [ ] Leaderboard dan achievements
- [ ] Export laporan PDF
- [ ] Mode offline lengkap
- [ ] Multi-subject (Fisika, Kimia, dll)

## 👨‍💻 Developer

**Kelompok 2:**
- Dika Muhammad Iqbal Marangga (240605110158)
- Sofwan Hakim Sayyidan (240605110181)

**Dosen Pengampu:**
- SUPRIYONO, M.Kom

**Institusi:**
Program Studi Teknik Informatika  
Fakultas Sains dan Teknologi  
Universitas Islam Negeri Maulana Malik Ibrahim Malang  
2026

## 📄 Lisensi

Project ini dibuat untuk keperluan akademik Tugas Akhir.

## 🐛 Bug Report

Jika menemukan bug atau ingin memberikan saran, silakan buat issue atau hubungi developer.

---

**Happy Learning! 📚✨**
