import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../domain/models/class_info.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/supabase_service.dart';

/// Implementasi [TeacherRepository] memakai tabel `classes`,
/// `class_members`, `profiles`, `student_ability`,
/// `student_concept_state`, dan `gamification`.
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
      return [
        for (final row in (rows as List))
          ClassInfo.fromRow(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<ClassInfo> createClass(String name) async {
    try {
      final userId = _userId();
      final row = await _client
          .from('classes')
          .insert({'teacher_id': userId, 'name': name})
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
          .select('student_id,xp')
          .inFilter('student_id', studentIds);

      String byId(List rows, String idKey, String id, String field) {
        for (final row in rows) {
          if (row[idKey] == id) return '${row[field] ?? ''}';
        }
        return '';
      }

      double thetaOf(String id) {
        for (final row in (abilities as List)) {
          if (row['student_id'] == id) {
            return (row['theta'] as num? ?? 0).toDouble();
          }
        }
        return 0;
      }

      int masteredOf(String id) {
        var count = 0;
        for (final row in (states as List)) {
          if (row['student_id'] == id && row['status'] == 'mastered') count++;
        }
        return count;
      }

      int xpOf(String id) {
        for (final row in (gamification as List)) {
          if (row['student_id'] == id) return row['xp'] as int? ?? 0;
        }
        return 0;
      }

      final total = await _conceptCount();
      return ClassReport(
        classId: classId,
        className: classMap['name'] as String? ?? '',
        totalConcepts: total,
        members: [
          for (final id in studentIds)
            ClassMemberReport(
              studentId: id,
              fullName: byId(profiles as List, 'id', id, 'full_name'),
              theta: thetaOf(id),
              masteredCount: masteredOf(id),
              xp: xpOf(id),
            ),
        ],
      );
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
