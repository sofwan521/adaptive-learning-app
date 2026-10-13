import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../domain/gamification/gamification_rules.dart';
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
        level: xpToLevel(total),
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
      if (last != null) {
        final lastDay = DateTime(last.year, last.month, last.day);
        if (today.difference(lastDay).inDays == 0) return current;
      }
      final streak = computeStreak(
        lastActiveDate: last,
        today: now,
        currentStreak: current.streak,
      );
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

  @override
  Future<Set<String>> loadBadgeCodes() async {
    try {
      final userId = _userId();
      final rows = await _client
          .from('user_badges')
          .select('badge_id, badges(code)')
          .eq('user_id', userId);
      final codes = <String>{};
      for (final row in (rows as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        final badge = map['badges'];
        final code = badge is Map
            ? (Map<String, dynamic>.from(badge)['code'] as String?)
            : null;
        if (code != null && code.isNotEmpty) codes.add(code);
      }
      return codes;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<bool> awardBadge(String code) async {
    try {
      final userId = _userId();
      final badgeRow = await _client
          .from('badges')
          .select('id')
          .eq('code', code)
          .maybeSingle();
      if (badgeRow == null) return false;
      final badgeId = (badgeRow as Map)['id'] as String;
      final existing = await _client
          .from('user_badges')
          .select('badge_id')
          .eq('user_id', userId)
          .eq('badge_id', badgeId)
          .maybeSingle();
      if (existing != null) return false;
      try {
        await _client.from('user_badges').insert({
          'user_id': userId,
          'badge_id': badgeId,
        });
      } catch (_) {
        // Balapan pemberian ganda: anggap sudah dimiliki.
        return false;
      }
      return true;
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => SupabaseGamificationRepository(ref.watch(supabaseClientProvider)),
);
