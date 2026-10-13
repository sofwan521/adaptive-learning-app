PROYEK: AdaptiLearn, aplikasi mobile pembelajaran adaptif untuk siswa SMP/SMA (Matematika dasar) berbasis Knowledge Graph (relasi prasyarat antar-konsep) dan Item Response Theory 2PL untuk estimasi kemampuan siswa (theta).

STACK: Flutter + Dart, Riverpod, go_router, supabase_flutter, fl_chart, flutter_local_notifications, shared_preferences. Tanpa code generation (tanpa freezed/json_serializable/build_runner): gunakan class Dart biasa.

ARSITEKTUR: lib/core, lib/domain (logika murni tanpa import Flutter: irt/, graph/, models/), lib/data (repository + supabase service), lib/features/<fitur>/{presentation, application}.

ATURAN: bahasa UI Bahasa Indonesia; null-safety; tidak ada logika bisnis di widget; semua logika IRT dan graf harus punya unit test; satu commit per langkah dengan format Conventional Commits; jangan commit kunci rahasia (gunakan file .env yang di-gitignore atau --dart-define).

PERAN: student, teacher, admin. Status konsep: locked, open, learning, mastered.

RUMUS: P(theta)=1/(1+exp(-a*(theta-b))); informasi=a^2P(1-P); theta diestimasi EAP (grid -4..4 langkah 0.1, prior N(0,1)). Konsep dikuasai jika minimal 4 soal, theta_konsep>=tau dan SE<=0.6 (atau 8 soal tercapai). Gagal dini bila 3 salah berturut-turut.

KRITERIA SELESAI umum: flutter analyze bersih, flutter test lulus, aplikasi bisa dijalankan.
