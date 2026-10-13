// Kontrak repository guru (domain, tanpa import Flutter).
import '../models/class_info.dart';

/// Kelas dan laporan kemajuan murid. Galat berupa [AppException].
abstract class TeacherRepository {
  /// Kelas yang diajar guru aktif.
  Future<List<ClassInfo>> classes();

  /// Buat kelas baru (kode gabung dibuat backend).
  Future<ClassInfo> createClass(String name);

  /// Laporan kemajuan murid satu kelas.
  Future<ClassReport> classReport(String classId);
}
