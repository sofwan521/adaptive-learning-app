// Kontrak repository guru dan keanggotaan kelas (domain, tanpa import Flutter).
import '../models/class_info.dart';
import '../models/student_concept_state.dart';

/// Kelas, laporan kemajuan murid, dan gabung kelas.
/// Galat berupa [AppException].
///
/// Cakupan data ditegakkan RLS di backend (guru hanya membaca murid
/// di kelasnya; siswa hanya kelas yang diikuti): filter UI hanyalah
/// penyajian, bukan pengaman.
abstract class TeacherRepository {
  /// Kelas yang diajar guru aktif.
  Future<List<ClassInfo>> classes();

  /// Buat kelas baru (kode gabung dibuat backend).
  Future<ClassInfo> createClass(String name);

  /// Laporan kemajuan murid satu kelas.
  Future<ClassReport> classReport(String classId);

  /// Kelas yang diikuti siswa aktif.
  Future<List<ClassInfo>> myClasses();

  /// Gabungkan siswa aktif ke kelas berkode [code].
  ///
  /// Mengembalikan id kelas. Kode dinormalisasi (trim + huruf kapital)
  /// mengikuti fungsi `join_class`; kode tak dikenal melempar.
  Future<String> joinClass(String code);

  /// Konsep paling sering gagal di satu kelas, terurut menurun.
  Future<List<ConceptFailRate>> conceptFailRates(String classId);

  /// State konsep satu murid. RLS membatasi ke murid di kelas guru.
  Future<List<StudentConceptState>> memberConceptStates(String studentId);
}
