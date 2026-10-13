import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Satu jawaban tersimpan untuk pemulihan sesi kuis.
class QuizResumeAnswer extends Equatable {
  final String itemId;
  final int selectedIndex;
  final bool isCorrect;

  const QuizResumeAnswer({
    required this.itemId,
    required this.selectedIndex,
    required this.isCorrect,
  });

  factory QuizResumeAnswer.fromJson(Map<String, dynamic> json) {
    return QuizResumeAnswer(
      itemId: json['itemId'] as String,
      selectedIndex: json['selectedIndex'] as int? ?? 0,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'selectedIndex': selectedIndex,
      'isCorrect': isCorrect,
    };
  }

  @override
  List<Object?> get props => [itemId, selectedIndex, isCorrect];
}

/// Potret sesi kuis yang belum selesai agar bisa dilanjutkan
/// bila aplikasi tertutup mendadak.
class QuizResumeSnapshot extends Equatable {
  final String conceptId;
  final String sessionId;
  final double thetaInit;
  final String? originConceptId;
  final List<QuizResumeAnswer> answers;

  const QuizResumeSnapshot({
    required this.conceptId,
    required this.sessionId,
    required this.thetaInit,
    this.originConceptId,
    this.answers = const [],
  });

  factory QuizResumeSnapshot.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    return QuizResumeSnapshot(
      conceptId: json['conceptId'] as String,
      sessionId: json['sessionId'] as String? ?? '',
      thetaInit: (json['thetaInit'] as num? ?? 0.0).toDouble(),
      originConceptId: json['originConceptId'] as String?,
      answers: [
        if (rawAnswers is List)
          for (final entry in rawAnswers)
            if (entry is Map)
              QuizResumeAnswer.fromJson(Map<String, dynamic>.from(entry)),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conceptId': conceptId,
      'sessionId': sessionId,
      'thetaInit': thetaInit,
      'originConceptId': originConceptId,
      'answers': [for (final answer in answers) answer.toJson()],
    };
  }

  @override
  List<Object?> get props =>
      [conceptId, sessionId, thetaInit, originConceptId, answers];
}

/// Penyimpanan potret sesi kuis yang belum selesai.
///
/// Seluruh operasi menelan galat (termasuk plugin yang belum siap
/// di uji widget) agar alur kuis tidak pernah terhenti karenanya:
/// gagal baca berarti tidak ada sesi tersimpan, gagal tulis
/// berarti pemulihan dilewati.
abstract class QuizResumeStore {
  Future<QuizResumeSnapshot?> load();
  Future<void> save(QuizResumeSnapshot snapshot);
  Future<void> clear();
}

/// Implementasi [QuizResumeStore] memakai SharedPreferences.
class SharedPreferencesQuizResumeStore implements QuizResumeStore {
  static const storageKey = 'quiz_resume_v1';

  /// Batas tunggu akses plugin agar sesi tak menggantung selamanya.
  static const accessTimeout = Duration(seconds: 3);

  const SharedPreferencesQuizResumeStore();

  Future<SharedPreferences?> _prefsOrNull() async {
    try {
      return await SharedPreferences.getInstance().timeout(accessTimeout);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<QuizResumeSnapshot?> load() async {
    try {
      final prefs = await _prefsOrNull();
      final raw = prefs?.getString(storageKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final snapshot = QuizResumeSnapshot.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (snapshot.conceptId.isEmpty) return null;
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(QuizResumeSnapshot snapshot) async {
    try {
      final prefs = await _prefsOrNull();
      if (prefs == null) return;
      await prefs
          .setString(storageKey, jsonEncode(snapshot.toJson()))
          .timeout(accessTimeout);
    } catch (_) {
      // Pemulihan bersifat best-effort; abaikan kegagalan tulis.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await _prefsOrNull();
      if (prefs == null) return;
      await prefs.remove(storageKey).timeout(accessTimeout);
    } catch (_) {
      // Abaikan; tidak ada sesi berarti tidak ada yang dilanjutkan.
    }
  }
}

final quizResumeStoreProvider = Provider<QuizResumeStore>(
  (ref) => const SharedPreferencesQuizResumeStore(),
);
