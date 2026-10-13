import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../domain/models/gamification_state.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../datasources/supabase_service.dart';

/// Implementasi [GamificationRepository] memakai tabel `gamification`.
class SupabaseGamificationRepository implements GamificationRepository {
  final SupabaseClient _client;

  SupabaseGamificationRepository(this._client);

  String _userId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AppException(
          'Sesi Anda telah berakhir. Silakan masuk kembali.', 'auth');
    }
    return user.id;
  }

  Future<void> _save(GamificationState state) async {
    await _client.from('gamification').upsert(
      {
        'student_id': state.studentId,
        'xp': state.xp,
        'level': state.level,
        'streak': state.streak,
        'last_active_date': state.lastActiveDate
            ?.toIso8601String()
            .substring(0, 10),
      },
      onConflict: 'student_id',
    );
  }

  @override
  Future<GamificationState> load() async {
    try {
      final userId = _userId();
      final row = await _client
          .from('gamification')
          .select()
          .eq('student_id', userId)
          .maybeSingle();
      if (row == null) return GamificationState(studentId: userId);
      return GamificationState.fromRow(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<GamificationState> addXp(int xp) async {
    try {
      final current = await load();
      final total = current.xp + xp;
      final updated = GamificationState(
        studentId: current.studentId,
        xp: total,
        level: total ~/ 100 + 1,
        streak: current.streak,
        lastActiveDate: current.lastActiveDate,
      );
      await _save(updated);
      return updated;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<GamificationState> updateStreak() async {
    try {
      final current = await load();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final last = current.lastActiveDate;
      final lastDay =
          last == null ? null : DateTime(last.year, last.month, last.day);

      final int streak;
      if (lastDay == null) {
        streak = 1;
      } else {
        final gap = today.difference(lastDay).inDays;
        if (gap == 0) {
          return current;
        } else if (gap == 1) {
          streak = current.streak + 1;
        } else {
          streak = 1;
        }
      }
      final updated = GamificationState(
        studentId: current.studentId,
        xp: current.xp,
        level: current.level,
        streak: streak,
        lastActiveDate: today,
      );
      await _save(updated);
      return updated;
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => SupabaseGamificationRepository(ref.watch(supabaseClientProvider)),
);
