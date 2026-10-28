import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../domain/irt/score_scale.dart';
import '../../domain/models/class_info.dart';
import '../../domain/models/concept_status.dart';
import '../../domain/models/quiz_session.dart';
import '../../domain/models/student_concept_state.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/supabase_service.dart';

/// Implementasi [TeacherRepository] memakai tabel `classes`,
/// `class_members`, `profiles`, `student_ability`,
/// `student_concept_state`, `gamification`, `quiz_sessions`,
/// `concepts`, dan fungsi `join_class`.
///
/// Semua baca tulis melewati RLS: guru hanya melihat murid di
/// kelasnya, siswa hanya kelas yang diikuti dan datanya sendiri.
class SupabaseTeacherRepository implements TeacherRepository {
  final SupabaseClient _client;

  SupabaseTeacherRepository(this._client);

  String _userId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AppException(
          'Sesi Anda telah berakhir. Silakan masuk kembali.', 'auth');
    }
    return user.id;
  }

  @override
  Future<List<ClassInfo>> classes() async {
    try {
      final userId = _userId();
      final rows = await _client
          .from('classes')
          .select()
          .eq('teacher_id', userId)
          .order('created_at');
      final infos = [
        for (final row in (rows as List))
          ClassInfo.fromRow(Map<String, dynamic>.from(row)),
      ];
      if (infos.isEmpty) return infos;
      final memberRows = await _client
          .from('class_members')
          .select('class_id')
          .inFilter('class_id', [for (final info in infos) info.id]);
      final counts = <String, int>{};
      for (final row in (memberRows as List)) {
        final classId = row['class_id'] as String;
        counts[classId] = (counts[classId] ?? 0) + 1;
      }
      return [
        for (final info in infos)
          info.copyWith(memberCount: counts[info.id] ?? 0),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<ClassInfo> createClass(String name) async {
    try {
      final userId = _userId();
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw const AppException('Nama kelas tidak boleh kosong.');
      }
      final row = await _client
          .from('classes')
          .insert({'teacher_id': userId, 'name': trimmed})
          .select()
          .single();
      return ClassInfo.fromRow(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<ClassReport> classReport(String classId) async {
    try {
      final classRow = await _client
          .from('classes')
          .select()
          .eq('id', classId)
          .maybeSingle();
      if (classRow == null) {
        throw const AppException('Kelas tidak ditemukan.');
      }
      final classMap = Map<String, dynamic>.from(classRow);

      final memberRows = await _client
          .from('class_members')
          .select('student_id')
          .eq('class_id', classId);
      final studentIds = [
        for (final row in (memberRows as List)) row['student_id'] as String,
      ];
      if (studentIds.isEmpty) {
        final total = await _conceptCount();
        return ClassReport(
          classId: classId,
          className: classMap['name'] as String? ?? '',
          joinCode: classMap['join_code'] as String? ?? '',
          totalConcepts: total,
        );
      }

      final profiles = await _client
          .from('profiles')
          .select('id,full_name')
          .inFilter('id', studentIds);
      final abilities = await _client
          .from('student_ability')
          .select('student_id,theta')
          .inFilter('student_id', studentIds);
      final states = await _client
          .from('student_concept_state')
          .select('student_id,status')
          .inFilter('student_id', studentIds);
      final gamification = await _client
          .from('gamification')
          .select('student_id,last_active_date')
          .inFilter('student_id', studentIds);

      String byId(List rows, String idKey, String id, String field) {
        for (final row in rows) {
          if (row[idKey] == id) return '${row[field] ?? ''}';
        }
        return '';
      }

      double percentOf(String id) {
        for (final row in (abilities as List)) {
          if (row['student_id'] == id) {
            final theta = (row['theta'] as num? ?? 0).toDouble();
            return thetaToPercent(theta);
          }
        }
        return thetaToPercent(0);
      }

      int masteredOf(String id) {
        var count = 0;
        for (final row in (states as List)) {
          if (row['student_id'] == id && row['status'] == 'mastered') count++;
        }
        return count;
      }

      DateTime? lastActiveOf(String id) {
        for (final row in (gamification as List)) {
          if (row['student_id'] == id) {
            final raw = row['last_active_date'];
            if (raw == null) return null;
            if (raw is DateTime) return raw;
            return DateTime.tryParse(raw.toString());
          }
        }
        return null;
      }

      final total = await _conceptCount();
      return ClassReport(
        classId: classId,
        className: classMap['name'] as String? ?? '',
        joinCode: classMap['join_code'] as String? ?? '',
        totalConcepts: total,
        members: [
          for (final id in studentIds)
            ClassMemberReport(
              studentId: id,
              fullName: byId(profiles as List, 'id', id, 'full_name'),
              percent: percentOf(id),
              masteredCount: masteredOf(id),
              lastActive: lastActiveOf(id),
            ),
        ],
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<List<ClassInfo>> myClasses() async {
    try {
      final userId = _userId();
      final memberRows = await _client
          .from('class_members')
          .select('class_id')
          .eq('student_id', userId);
      final classIds = [
        for (final row in (memberRows as List)) row['class_id'] as String,
      ];
      if (classIds.isEmpty) return [];
      final rows = await _client
          .from('classes')
          .select()
          .inFilter('id', classIds)
          .order('created_at');
      return [
        for (final row in (rows as List))
          ClassInfo.fromRow(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<String> joinClass(String code) async {
    try {
      _userId();
      final normalized = code.trim().toUpperCase();
      if (normalized.isEmpty) {
        throw const AppException('Kode kelas tidak boleh kosong.');
      }
      final result = await _client.rpc(
        'join_class',
        params: {'p_code': normalized},
      );
      return (result ?? '').toString();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<List<ConceptFailRate>> conceptFailRates(String classId) async {
    try {
      final memberRows = await _client
          .from('class_members')
          .select('student_id')
          .eq('class_id', classId);
      final studentIds = [
        for (final row in (memberRows as List)) row['student_id'] as String,
      ];
      if (studentIds.isEmpty) return [];
      final sessionRows = await _client
          .from('quiz_sessions')
          .select()
          .inFilter('student_id', studentIds)
          .limit(1000);
      final conceptRows = await _client
          .from('concepts')
          .select('id,tau')
          .limit(1000);
      final taus = <String, double>{};
      for (final raw in (conceptRows as List)) {
        final row = Map<String, dynamic>.from(raw);
        taus[row['id'] as String] =
            (row['tau'] as num? ?? 0).toDouble();
      }
      return rankFailedConcepts(
        sessions: [
          for (final row in (sessionRows as List))
            QuizSession.fromRow(Map<String, dynamic>.from(row)),
        ],
        taus: taus,
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<List<StudentConceptState>> memberConceptStates(
    String studentId,
  ) async {
    try {
      final rows = await _client
          .from('student_concept_state')
          .select()
          .eq('student_id', studentId);
      return [
        for (final row in (rows as List))
          StudentConceptState(
            studentId: row['student_id'] as String,
            conceptId: row['concept_id'] as String,
            status: ConceptStatus.fromString(row['status'] as String?),
            thetaC: (row['theta_c'] as num? ?? 0).toDouble(),
            nAnswered: row['n_answered'] as int? ?? 0,
          ),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<int> _conceptCount() async {
    final rows =
        await _client.from('concepts').select('id').limit(1000);
    return (rows as List).length;
  }
}

final teacherRepositoryProvider = Provider<TeacherRepository>(
  (ref) => SupabaseTeacherRepository(ref.watch(supabaseClientProvider)),
);
