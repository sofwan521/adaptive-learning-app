import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/concept_repository_impl.dart';
import '../../../data/repositories/progress_repository_impl.dart';
import '../../../domain/graph/knowledge_graph.dart';
import '../../../domain/models/concept_status.dart';
import '../../../domain/models/quiz_session.dart';
import '../../../domain/models/response_history.dart';
import '../../../domain/models/student_concept_state.dart';

/// Jumlah titik theta terbanyak pada grafik.
const int thetaChartMaxPoints = 30;

/// Satu titik perkembangan theta.
class ThetaPoint extends Equatable {
  final DateTime time;
  final double theta;

  const ThetaPoint(this.time, this.theta);

  @override
  List<Object?> get props => [time, theta];
}

/// Bar penguasaan satu konsep.
class ConceptBarData extends Equatable {
  final String conceptId;
  final String code;
  final String name;
  final double thetaC;
  final ConceptStatus status;

  const ConceptBarData({
    required this.conceptId,
    required this.code,
    required this.name,
    required this.thetaC,
    required this.status,
  });

  @override
  List<Object?> get props => [conceptId, code, name, thetaC, status];
}

/// Satu baris riwayat kuis.
class HistoryItemData extends Equatable {
  final String sessionId;
  final String title;
  final DateTime? date;
  final String resultLabel;
  final String? scoreText;
  final double? theta;

  const HistoryItemData({
    required this.sessionId,
    required this.title,
    this.date,
    required this.resultLabel,
    this.scoreText,
    this.theta,
  });

  @override
  List<Object?> get props =>
      [sessionId, title, date, resultLabel, scoreText, theta];
}

/// Agregat dasbor progres siswa.
///
/// Logika murni — tanpa import Flutter — dibangun oleh
/// [buildProgressDashboard] agar mudah diuji.
class ProgressDashboard extends Equatable {
  /// Titik theta menaik waktu (maks [thetaChartMaxPoints]).
  final List<ThetaPoint> thetaPoints;

  /// Sumber titik: 'respons' (per jawaban) atau 'sesi'.
  final String thetaSource;

  final int masteredCount;
  final int totalConcepts;

  /// Akurasi 7 hari terakhir, null bila tak ada jawaban.
  final double? accuracy7d;

  final int totalAnswered;
  final List<ConceptBarData> bars;
  final List<HistoryItemData> history;

  const ProgressDashboard({
    this.thetaPoints = const [],
    this.thetaSource = 'respons',
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
        thetaPoints,
        thetaSource,
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
/// - Titik theta: `theta_after` per respons (30 terakhir); bila kosong,
///   memakai `final_theta` per sesi.
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

  var thetaPoints = <ThetaPoint>[];
  var thetaSource = 'respons';
  final withTheta = [
    for (final r in byTime)
      if (r.thetaAfter != null) ThetaPoint(r.answeredAt, r.thetaAfter!),
  ];
  if (withTheta.length > thetaChartMaxPoints) {
    thetaPoints =
        withTheta.sublist(withTheta.length - thetaChartMaxPoints);
  } else {
    thetaPoints = withTheta;
  }
  if (thetaPoints.isEmpty) {
    thetaSource = 'sesi';
    final sessionPoints = <ThetaPoint>[];
    final byStart = [...sessions]
      ..sort((a, b) => _sessionTime(a).compareTo(_sessionTime(b)));
    for (final session in byStart) {
      final theta = session.finalTheta;
      if (theta != null) {
        sessionPoints.add(ThetaPoint(_sessionTime(session), theta));
      }
    }
    thetaPoints = sessionPoints.length > thetaChartMaxPoints
        ? sessionPoints.sublist(sessionPoints.length - thetaChartMaxPoints)
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
    bars.add(
      ConceptBarData(
        conceptId: id,
        code: concept.code,
        name: concept.name,
        thetaC: statesById[id]?.thetaC ?? 0.0,
        status: statuses[id] ?? ConceptStatus.locked,
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
        theta: session.finalTheta,
      ),
    );
  }

  return ProgressDashboard(
    thetaPoints: thetaPoints,
    thetaSource: thetaSource,
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
    final sessions = await progress.history(limit: thetaChartMaxPoints);
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
