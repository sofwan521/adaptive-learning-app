import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../domain/models/ability_estimate.dart';
import '../../domain/models/concept_status.dart';
import '../../domain/models/pending_response.dart';
import '../../domain/models/quiz_session.dart';
import '../../domain/models/response_history.dart';
import '../../domain/models/student_concept_state.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/pending_response_store.dart';
import '../datasources/supabase_service.dart';

/// Mengirim satu baris `responses` ke backend.
///
/// Diekstrak sebagai fungsi agar logika antrean dapat diuji dengan
/// injeksi ganda; implementasi bawaan memakai rantai Supabase.
typedef ResponseSender = Future<void> Function(Map<String, dynamic> row);

Future<void> _supabaseResponseSender(
  SupabaseClient client,
  Map<String, dynamic> row,
) async {
  await client.from('responses').insert(row);
}

/// Implementasi [ProgressRepository] memakai Supabase.
///
/// [saveResponse] mengantrekan respons ke [PendingResponseStore] bila
/// perangkat luring; [flushPending] mengirim antrean saat aplikasi aktif.
class SupabaseProgressRepository implements ProgressRepository {
  final SupabaseClient _client;
  final PendingResponseStore _pendingStore;
  final ResponseSender _responseSender;
  final Random _random;

  SupabaseProgressRepository({
    required SupabaseClient client,
    required PendingResponseStore pendingStore,
    ResponseSender? responseSender,
    Random? random,
  })  : _client = client,
        _pendingStore = pendingStore,
        _responseSender =
            responseSender ?? ((row) => _supabaseResponseSender(client, row)),
        _random = random ?? Random();

  String _userId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AppException(
          'Sesi Anda telah berakhir. Silakan masuk kembali.', 'auth');
    }
    return user.id;
  }

  Map<String, dynamic> _responseRow(PendingResponse response, String userId) {
    return {
      'session_id': response.sessionId,
      'student_id': userId,
      'item_id': response.itemId,
      'selected_index': response.selectedIndex,
      'is_correct': response.isCorrect,
      'theta_after': response.thetaAfter,
    };
  }

  String _newPendingId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

  @override
  Future<AbilityEstimate> loadAbility() async {
    try {
      final userId = _userId();
      final row = await _client
          .from('student_ability')
          .select('theta,se')
          .eq('student_id', userId)
          .maybeSingle();
      if (row == null) return const AbilityEstimate(theta: 0, se: 1);
      final map = Map<String, dynamic>.from(row);
      return AbilityEstimate(
        theta: (map['theta'] as num? ?? 0).toDouble(),
        se: (map['se'] as num? ?? 1).toDouble(),
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<void> saveAbility(AbilityEstimate estimate) async {
    try {
      final userId = _userId();
      await _client.from('student_ability').upsert(
        {
          'student_id': userId,
          'theta': estimate.theta,
          'se': estimate.se,
        },
        onConflict: 'student_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<List<StudentConceptState>> loadConceptStates() async {
    try {
      final userId = _userId();
      final rows = await _client
          .from('student_concept_state')
          .select()
          .eq('student_id', userId);
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

  @override
  Future<void> upsertConceptState(StudentConceptState state) async {
    try {
      await _client.from('student_concept_state').upsert(
        {
          'student_id': state.studentId,
          'concept_id': state.conceptId,
          'status': state.status.name,
          'theta_c': state.thetaC,
          'n_answered': state.nAnswered,
        },
        onConflict: 'student_id,concept_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<ResponseSyncStatus> saveResponse(PendingResponse response) async {
    final userId = _userId();
    try {
      await _responseSender(_responseRow(response, userId));
      return ResponseSyncStatus.sent;
    } catch (e) {
      if (!isOfflineError(e)) throw mapToAppException(e);
      final queued = await _pendingStore.loadAll();
      final withId = response.id.isEmpty
          ? PendingResponse(
              id: _newPendingId(),
              sessionId: response.sessionId,
              itemId: response.itemId,
              selectedIndex: response.selectedIndex,
              isCorrect: response.isCorrect,
              thetaAfter: response.thetaAfter,
            )
          : response;
      await _pendingStore.saveAll([...queued, withId]);
      return ResponseSyncStatus.queued;
    }
  }

  @override
  Future<int> flushPending() async {
    final userId = _userId();
    final pending = await _pendingStore.loadAll();
    if (pending.isEmpty) return 0;
    final failed = <PendingResponse>[];
    var sent = 0;
    for (var i = 0; i < pending.length; i++) {
      final response = pending[i];
      try {
        await _responseSender(_responseRow(response, userId));
        sent++;
      } catch (e) {
        if (!isOfflineError(e)) {
          // Galat non-jaringan: simpan sisa antrean lalu lempar.
          await _pendingStore.saveAll([...failed, ...pending.sublist(i)]);
          throw mapToAppException(e);
        }
        failed.add(response);
      }
    }
    await _pendingStore.saveAll(failed);
    return sent;
  }

  @override
  Future<int> pendingCount() async {
    return (await _pendingStore.loadAll()).length;
  }

  @override
  Future<int> countResponsesToday() async {
    try {
      final userId = _userId();
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final rows = await _client
          .from('responses')
          .select('id')
          .eq('student_id', userId)
          .gte('answered_at', startOfDay.toIso8601String())
          .limit(1000);
      return (rows as List).length;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<String> createSession({String? conceptId}) async {
    try {
      final userId = _userId();
      final row = await _client
          .from('quiz_sessions')
          .insert({'student_id': userId, 'concept_id': conceptId})
          .select('id')
          .single();
      return (row as Map)['id'] as String;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<void> finishSession({
    required String sessionId,
    required double finalTheta,
  }) async {
    try {
      await _client.from('quiz_sessions').update({
        'status': 'selesai',
        'final_theta': finalTheta,
        'finished_at': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<List<QuizSession>> history({int limit = 20}) async {
    try {
      final userId = _userId();
      final rows = await _client
          .from('quiz_sessions')
          .select()
          .eq('student_id', userId)
          .order('started_at', ascending: false)
          .limit(limit);
      return [
        for (final row in (rows as List))
          QuizSession.fromRow(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  @override
  Future<List<ResponseHistoryEntry>> loadResponseHistory({
    int limit = 300,
  }) async {
    try {
      final userId = _userId();
      final rows = await _client
          .from('responses')
          .select('session_id,is_correct,theta_after,answered_at')
          .eq('student_id', userId)
          .order('answered_at', ascending: true)
          .limit(limit);
      return [
        for (final row in (rows as List))
          ResponseHistoryEntry.fromRow(Map<String, dynamic>.from(row)),
      ].whereType<ResponseHistoryEntry>().toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => SupabaseProgressRepository(
    client: ref.watch(supabaseClientProvider),
    pendingStore: const SharedPreferencesPendingStore(),
  ),
);
