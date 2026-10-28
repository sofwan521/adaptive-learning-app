import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/repositories/concept_repository_impl.dart';
import '../../../data/repositories/item_repository_impl.dart';
import '../../../data/repositories/progress_repository_impl.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/placement_provider.dart';
import '../../../domain/graph/knowledge_graph.dart';
import '../../../domain/irt/irt_engine.dart';
import '../../../domain/irt/score_scale.dart';
import '../../../domain/models/ability_estimate.dart';
import '../../../domain/models/concept_status.dart';
import '../../../domain/models/item.dart';
import '../../../domain/models/pending_response.dart';
import '../../../domain/models/response_record.dart';
import '../../../domain/models/student_concept_state.dart';

/// Jumlah soal placement test lintas konsep.
const int placementItemCount = 12;

/// Tahapan placement test.
enum PlacementPhase {
  /// Pengantar, menunggu mulai.
  intro,

  /// Memuat soal / menyimpan hasil.
  loading,

  /// Menjawab soal berjalan.
  answering,

  /// Umpan balik benar/salah + pembahasan.
  feedback,

  /// Menyimpan hasil akhir.
  finishing,

  /// Selesai, hasil siap ditampilkan.
  done,

  /// Galat dengan tombol coba lagi.
  error,
}

/// State placement test (immutable).
class PlacementState extends Equatable {
  final PlacementPhase phase;
  final List<Item> items;
  final int index;
  final int? selected;
  final List<ResponseRecord> records;
  final List<Item> answeredItems;
  final double theta;
  final double se;
  final String sessionId;
  final int correctCount;
  final bool? lastCorrect;
  final String? errorMessage;
  final List<String> masteredIds;

  const PlacementState({
    this.phase = PlacementPhase.intro,
    this.items = const [],
    this.index = 0,
    this.selected,
    this.records = const [],
    this.answeredItems = const [],
    this.theta = 0.0,
    this.se = 1.0,
    this.sessionId = '',
    this.correctCount = 0,
    this.lastCorrect,
    this.errorMessage,
    this.masteredIds = const [],
  });

  /// Soal yang sedang dikerjakan, null bila tak ada.
  Item? get currentItem =>
      index >= 0 && index < items.length ? items[index] : null;

  /// Jumlah soal dalam sesi ini.
  int get total => items.length;

  /// Skor kemampuan dalam persen (0..100).
  double get scorePercent => thetaToPercent(theta);

  /// Nomor soal berjalan (1-based) untuk tampilan.
  ///
  /// Berbasis jumlah soal yang sudah dijawab agar berurutan 1..N
  /// walau urutan soal adaptif melompat-lompat dalam bank.
  int get questionNumber {
    if (items.isEmpty) return 0;
    if (phase == PlacementPhase.feedback ||
        phase == PlacementPhase.finishing ||
        phase == PlacementPhase.done) {
      return answeredItems.length.clamp(1, items.length);
    }
    return (answeredItems.length + 1).clamp(1, items.length);
  }

  /// True bila soal berjalan adalah soal terakhir.
  bool get isLast => items.isNotEmpty && questionNumber >= items.length;

  PlacementState copyWith({
    PlacementPhase? phase,
    List<Item>? items,
    int? index,
    int? selected,
    bool clearSelected = false,
    List<ResponseRecord>? records,
    List<Item>? answeredItems,
    double? theta,
    double? se,
    String? sessionId,
    int? correctCount,
    bool? lastCorrect,
    String? errorMessage,
    bool clearError = false,
    List<String>? masteredIds,
  }) {
    return PlacementState(
      phase: phase ?? this.phase,
      items: items ?? this.items,
      index: index ?? this.index,
      selected: clearSelected ? null : (selected ?? this.selected),
      records: records ?? this.records,
      answeredItems: answeredItems ?? this.answeredItems,
      theta: theta ?? this.theta,
      se: se ?? this.se,
      sessionId: sessionId ?? this.sessionId,
      correctCount: correctCount ?? this.correctCount,
      lastCorrect: lastCorrect ?? this.lastCorrect,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      masteredIds: masteredIds ?? this.masteredIds,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        items,
        index,
        selected,
        records,
        answeredItems,
        theta,
        se,
        sessionId,
        correctCount,
        lastCorrect,
        errorMessage,
        masteredIds,
      ];
}

/// Nama tingkat kemampuan dalam bahasa awam berdasarkan persen.
String placementLevelName(double percent) {
  if (percent < 38) return 'Pemula';
  if (percent <= 73) return 'Menengah';
  return 'Mahir';
}

/// Susun status awal tiap konsep dari hasil placement.
///
/// Konsep dengan rata-rata b soal yang dikerjakan <= theta - 0.5 dan
/// seluruh prasyaratnya mastered diberi mastered (diproses sesuai
/// urutan topologis), lalu status sisanya dihitung ulang lewat
/// [KnowledgeGraph.computeStatuses]. Siap di-upsert apa adanya.
Map<String, StudentConceptState> buildInitialStates({
  required KnowledgeGraph graph,
  required double theta,
  required List<Item> answeredItems,
  required String studentId,
}) {
  final byConcept = <String, List<Item>>{};
  for (final item in answeredItems) {
    byConcept.putIfAbsent(item.conceptId, () => []).add(item);
  }
  final averageB = <String, double>{
    for (final entry in byConcept.entries)
      entry.key: entry.value.map((i) => i.b).reduce((a, b) => a + b) /
          entry.value.length,
  };
  final counts = <String, int>{
    for (final entry in byConcept.entries) entry.key: entry.value.length,
  };

  final mastered = <String>{};
  for (final id in graph.topologicalOrder()) {
    final b = averageB[id];
    if (b == null) continue;
    final prereqsOk =
        graph.prerequisitesOf(id).every(mastered.contains);
    if (prereqsOk && b <= theta - 0.5) mastered.add(id);
  }

  final seed = <String, StudentConceptState>{
    for (final id in graph.conceptIds)
      id: StudentConceptState(
        studentId: studentId,
        conceptId: id,
        status:
            mastered.contains(id) ? ConceptStatus.mastered : ConceptStatus.locked,
      ),
  };
  final statuses = graph.computeStatuses(seed);
  return {
    for (final id in graph.conceptIds)
      id: StudentConceptState(
        studentId: studentId,
        conceptId: id,
        status: statuses[id] ?? ConceptStatus.locked,
        thetaC: mastered.contains(id) ? theta : 0.0,
        nAnswered: mastered.contains(id) ? (counts[id] ?? 0) : 0,
      ),
  };
}

/// Pengendali placement test adaptif (Riverpod Notifier).
class PlacementController extends Notifier<PlacementState> {
  int _pendingCounter = 0;

  @override
  PlacementState build() => const PlacementState();

  String _studentId() {
    final id = ref.read(authControllerProvider).profile?.id;
    if (id == null || id.isEmpty) {
      throw const AppException(
          'Sesi Anda telah berakhir. Silakan masuk kembali.', 'auth');
    }
    return id;
  }

  /// Mulai sesi: muat 12 soal, buat sesi, pilih soal pertama (b ~ 0).
  Future<void> start() async {
    state = state.copyWith(phase: PlacementPhase.loading, clearError: true);
    try {
      final itemsRepo = ref.read(itemRepositoryProvider);
      final progress = ref.read(progressRepositoryProvider);
      final fetched = await itemsRepo.fetchPlacementItems(
        limit: placementItemCount,
      );
      if (fetched.isEmpty) {
        throw const AppException(
            'Soal tidak tersedia. Periksa koneksi lalu coba lagi.');
      }
      final sessionId = await progress.createSession();
      final first = _firstItem(fetched);
      state = PlacementState(
        phase: PlacementPhase.answering,
        items: fetched,
        index: fetched.indexOf(first),
        sessionId: sessionId,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        phase: PlacementPhase.error,
        errorMessage: e.message,
      );
    }
  }

  /// Soal pertama: b terdekat 0 (di antara kandidat, seri ke b terkecil).
  Item _firstItem(List<Item> items) {
    var best = items.first;
    for (final item in items.skip(1)) {
      final currentGap = (item.b - 0).abs();
      final bestGap = (best.b - 0).abs();
      if (currentGap < bestGap - 1e-12 ||
          ((currentGap - bestGap).abs() <= 1e-12 && item.b < best.b)) {
        best = item;
      }
    }
    return best;
  }

  /// Pilih opsi jawaban (hanya saat menjawab).
  void select(int optionIndex) {
    if (state.phase != PlacementPhase.answering) return;
    state = state.copyWith(selected: optionIndex);
  }

  /// Nilai jawaban, simpan respons, hitung ulang theta berjalan.
  Future<void> answer() async {
    final item = state.currentItem;
    final selected = state.selected;
    if (state.phase != PlacementPhase.answering ||
        item == null ||
        selected == null) {
      return;
    }
    final correct = selected == item.correctIndex;
    final records = [
      ...state.records,
      ResponseRecord(a: item.a, b: item.b, correct: correct),
    ];
    final estimate = estimateEap(records);
    final answeredItems = [...state.answeredItems, item];

    // Simpan segera; kegagalan apa pun tidak menghentikan sesi
    // (respons tetap tercatat untuk estimasi; riwayat menyusul).
    try {
      final progress = ref.read(progressRepositoryProvider);
      await progress.saveResponse(
        PendingResponse(
          id: 'placement-${DateTime.now().microsecondsSinceEpoch}-'
              '${_pendingCounter++}',
          sessionId: state.sessionId,
          itemId: item.id,
          selectedIndex: selected,
          isCorrect: correct,
          thetaAfter: estimate.theta,
        ),
      );
    } catch (_) {
      // Lanjut sesi; finalisasi yang memastikan ketekalan data.
    }

    state = state.copyWith(
      phase: PlacementPhase.feedback,
      records: records,
      answeredItems: answeredItems,
      theta: estimate.theta,
      se: estimate.se,
      correctCount: state.correctCount + (correct ? 1 : 0),
      lastCorrect: correct,
    );
  }

  /// Lanjut ke soal berikutnya, atau finalisasi bila sudah tuntas.
  Future<void> next() async {
    if (state.phase != PlacementPhase.feedback) return;
    if (state.answeredItems.length >= state.items.length) {
      await finish();
      return;
    }
    final usedIds = {for (final item in state.answeredItems) item.id};
    final nextItem = selectNextItem(state.theta, state.items, usedIds);
    if (nextItem == null) {
      await finish();
      return;
    }
    state = state.copyWith(
      phase: PlacementPhase.answering,
      index: state.items.indexOf(nextItem),
      clearSelected: true,
    );
  }

  /// Finalisasi: simpan theta/SE, status awal konsep, tutup sesi.
  Future<void> finish() async {
    if (state.items.isEmpty) {
      await start();
      return;
    }
    state = state.copyWith(phase: PlacementPhase.finishing, clearError: true);
    try {
      final studentId = _studentId();
      final progress = ref.read(progressRepositoryProvider);
      final concepts = ref.read(conceptRepositoryProvider);
      final estimate = estimateEap(state.records);

      await progress.saveAbility(
        AbilityEstimate(theta: estimate.theta, se: estimate.se),
      );

      final graph = KnowledgeGraph(
        concepts: await concepts.fetchConcepts(),
        edges: await concepts.fetchEdges(),
      );
      final initial = buildInitialStates(
        graph: graph,
        theta: estimate.theta,
        answeredItems: state.answeredItems,
        studentId: studentId,
      );
      for (final entry in initial.entries) {
        await progress.upsertConceptState(entry.value);
      }
      await progress.finishSession(
        sessionId: state.sessionId,
        finalTheta: estimate.theta,
      );

      ref.invalidate(placementCompletedProvider);
      state = state.copyWith(
        phase: PlacementPhase.done,
        theta: estimate.theta,
        se: estimate.se,
        masteredIds: [
          for (final entry in initial.entries)
            if (entry.value.status == ConceptStatus.mastered) entry.key,
        ],
      );
    } on AppException catch (e) {
      state = state.copyWith(
        phase: PlacementPhase.error,
        errorMessage: e.message,
      );
    }
  }

  /// Coba lagi dari langkah terakhir yang gagal (mulai atau finalisasi).
  Future<void> retry() async {
    if (state.items.isEmpty || state.sessionId.isEmpty) {
      await start();
    } else {
      await finish();
    }
  }
}

final placementControllerProvider =
    NotifierProvider<PlacementController, PlacementState>(
  PlacementController.new,
);
