import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/concept_repository_impl.dart';
import '../../../data/repositories/progress_repository_impl.dart';
import '../../../domain/graph/knowledge_graph.dart';
import '../../../domain/irt/score_scale.dart';
import '../../../domain/models/concept_status.dart';
import '../../../domain/models/quiz_session.dart';
import '../../../domain/models/response_history.dart';
import '../../../domain/models/student_concept_state.dart';

/// Jumlah titik skor terbanyak pada grafik.
const int scoreChartMaxPoints = 30;

/// Satu titik perkembangan skor (persen).
class ScorePoint extends Equatable {
  final DateTime time;
  final double percent;

  const ScorePoint(this.time, this.percent);

  @override
  List<Object?> get props => [time, percent];
}

/// Bar penguasaan satu konsep.
class ConceptBarData extends Equatable {
  final String conceptId;
  final String code;
  final String name;
  final double percent;
  final ConceptStatus status;

  const ConceptBarData({
    required this.conceptId,
    required this.code,
    required this.name,
    required this.percent,
    required this.status,
  });

  @override
  List<Object?> get props => [conceptId, code, name, percent, status];
}

/// Satu baris riwayat kuis.
class HistoryItemData extends Equatable {
  final String sessionId;
  final String title;
  final DateTime? date;
  final String resultLabel;
  final String? scoreText;

  /// Skor sesi dalam persen (0..100), null bila belum ada.
  final double? percent;

  const HistoryItemData({
    required this.sessionId,
    required this.title,
    this.date,
    required this.resultLabel,
    this.scoreText,
    this.percent,
  });

  @override
  List<Object?> get props =>
      [sessionId, title, date, resultLabel, scoreText, percent];
}

/// Agregat dasbor progres siswa.
///
/// Logika murni — tanpa import Flutter — dibangun oleh
/// [buildProgressDashboard] agar mudah diuji.
class ProgressDashboard extends Equatable {
  /// Titik skor menaik waktu (maks [scoreChartMaxPoints]).
  final List<ScorePoint> scorePoints;

  /// Sumber titik: 'respons' (per jawaban) atau 'sesi'.
  final String scoreSource;

  final int masteredCount;
  final int totalConcepts;

  /// Akurasi 7 hari terakhir, null bila tak ada jawaban.
  final double? accuracy7d;

  final int totalAnswered;
  final List<ConceptBarData> bars;
  final List<HistoryItemData> history;

  const ProgressDashboard({
    this.scorePoints = const [],
    this.scoreSource = 'respons',
    this.masteredCount = 0,
    this.totalConcepts = 0,
    this.accuracy7d,
    this.totalAnswered = 0,
    this.bars = const [],
    this.history = const [],
  });

  /// True bila siswa belum punya data apa pun (siswa baru).
  bool get isEmpty =>
      totalAnswered == 0 && history.isEmpty && masteredCount == 0;

  @override
  List<Object?> get props => [
        scorePoints,
        scoreSource,
        masteredCount,
        totalConcepts,
        accuracy7d,
        totalAnswered,
        bars,
        history,
      ];
}

/// Susun dasbor dari data mentah repository.
///
/// - Titik skor: `theta_after` per respons (30 terakhir) yang diubah
///   menjadi persen; bila kosong, memakai `final_theta` per sesi.
/// - Akurasi: jawaban 7 hari terakhir.
/// - Riwayat: sesi terbaru digabung skor benar/total per sesi.
ProgressDashboard buildProgressDashboard({
  required Map<String, ({String code, String name})> concepts,
  required List<String> orderedIds,
  required Map<String, StudentConceptState> statesById,
  required Map<String, ConceptStatus> statuses,
  required List<QuizSession> sessions,
  required List<ResponseHistoryEntry> responses,
  required DateTime now,
}) {
  final byTime = [...responses]
    ..sort((a, b) => a.answeredAt.compareTo(b.answeredAt));

  var scorePoints = <ScorePoint>[];
  var scoreSource = 'respons';
  final withScore = [
    for (final r in byTime)
      if (r.thetaAfter != null)
        ScorePoint(r.answeredAt, thetaToPercent(r.thetaAfter!)),
  ];
  if (withScore.length > scoreChartMaxPoints) {
    scorePoints =
        withScore.sublist(withScore.length - scoreChartMaxPoints);
  } else {
    scorePoints = withScore;
  }
  if (scorePoints.isEmpty) {
    scoreSource = 'sesi';
    final sessionPoints = <ScorePoint>[];
    final byStart = [...sessions]
      ..sort((a, b) => _sessionTime(a).compareTo(_sessionTime(b)));
    for (final session in byStart) {
      final theta = session.finalTheta;
      if (theta != null) {
        sessionPoints.add(
          ScorePoint(_sessionTime(session), thetaToPercent(theta)),
        );
      }
    }
    scorePoints = sessionPoints.length > scoreChartMaxPoints
        ? sessionPoints.sublist(sessionPoints.length - scoreChartMaxPoints)
        : sessionPoints;
  }

  var masteredCount = 0;
  for (final state in statesById.values) {
    if (state.status == ConceptStatus.mastered) masteredCount++;
  }

  final weekAgo = now.subtract(const Duration(days: 7));
  final recent = [
    for (final r in byTime)
      if (!r.answeredAt.isBefore(weekAgo)) r,
  ];
  double? accuracy7d;
  if (recent.isNotEmpty) {
    final correct = recent.where((r) => r.isCorrect).length;
    accuracy7d = correct / recent.length;
  }

  final bars = <ConceptBarData>[];
  for (final id in orderedIds) {
    final concept = concepts[id];
    if (concept == null) continue;
    final status = statuses[id] ?? ConceptStatus.locked;
    final state = statesById[id];
    final percent = state == null || status == ConceptStatus.locked
        ? 0.0
        : thetaToPercent(state.thetaC);
    bars.add(
      ConceptBarData(
        conceptId: id,
        code: concept.code,
        name: concept.name,
        percent: percent,
        status: status,
      ),
    );
  }

  final scores = <String, ({int correct, int total})>{};
  for (final r in byTime) {
    final current = scores[r.sessionId] ?? (correct: 0, total: 0);
    scores[r.sessionId] = (
      correct: current.correct + (r.isCorrect ? 1 : 0),
      total: current.total + 1,
    );
  }
  final byRecent = [...sessions]
    ..sort((a, b) => _sessionTime(b).compareTo(_sessionTime(a)));
  final history = <HistoryItemData>[];
  for (final session in byRecent) {
    final score = scores[session.id];
    final conceptId = session.conceptId;
    history.add(
      HistoryItemData(
        sessionId: session.id,
        title: conceptId == null
            ? 'Tes Penempatan'
            : concepts[conceptId]?.name ?? 'Kuis',
        date: session.finishedAt ?? session.startedAt,
        resultLabel: switch (session.status) {
          QuizSessionStatus.finished => 'Selesai',
          QuizSessionStatus.ongoing => 'Berjalan',
          QuizSessionStatus.cancelled => 'Dibatalkan',
        },
        scoreText: score == null
            ? null
            : '${score.correct}/${score.total} benar',
        percent: session.finalTheta == null
            ? null
            : thetaToPercent(session.finalTheta!),
      ),
    );
  }

  return ProgressDashboard(
    scorePoints: scorePoints,
    scoreSource: scoreSource,
    masteredCount: masteredCount,
    totalConcepts: concepts.length,
    accuracy7d: accuracy7d,
    totalAnswered: byTime.length,
    bars: bars,
    history: history,
  );
}

DateTime _sessionTime(QuizSession session) {
  // Epoch bila tanpa waktu agar terurut paling awal, bukan kini.
  return session.startedAt ??
      session.finishedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

/// Dasbor progres dari backend untuk siswa aktif.
final progressDashboardProvider = FutureProvider<ProgressDashboard>(
  (ref) async {
    final conceptsRepo = ref.watch(conceptRepositoryProvider);
    final progress = ref.watch(progressRepositoryProvider);
    final concepts = await conceptsRepo.fetchConcepts();
    final edges = await conceptsRepo.fetchEdges();
    final graph = KnowledgeGraph(concepts: concepts, edges: edges);
    final states = await progress.loadConceptStates();
    final sessions = await progress.history(limit: scoreChartMaxPoints);
    final responses = await progress.loadResponseHistory(limit: 300);

    final statesById = {for (final s in states) s.conceptId: s};
    return buildProgressDashboard(
      concepts: {
        for (final c in concepts) c.id: (code: c.code, name: c.name),
      },
      orderedIds: graph.topologicalOrder(),
      statesById: statesById,
      statuses: graph.computeStatuses(statesById),
      sessions: sessions,
      responses: responses,
      now: DateTime.now(),
    );
  },
);
