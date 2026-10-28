import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/datasources/quiz_resume_store.dart';
import '../../../data/repositories/concept_repository_impl.dart';
import '../../../data/repositories/gamification_repository_impl.dart';
import '../../../data/repositories/item_repository_impl.dart';
import '../../../data/repositories/progress_repository_impl.dart';
import '../../auth/application/auth_controller.dart';
import '../../student/application/student_providers.dart';
import '../../../domain/gamification/badges.dart';
import '../../../domain/graph/knowledge_graph.dart';
import '../../../domain/irt/irt_engine.dart';
import '../../../domain/irt/score_scale.dart';
import '../../../domain/models/ability_estimate.dart';
import '../../../domain/models/concept_status.dart';
import '../../../domain/models/gamification_state.dart';
import '../../../domain/models/item.dart';
import '../../../domain/models/pending_response.dart';
import '../../../domain/models/response_record.dart';
import '../../../domain/models/student_concept_state.dart';

/// Batas waktu komputasi adaptif per langkah (mikrodetik).
///
/// Pemilihan soal dan pembaruan theta harus di bawah 2 detik.
const int quizComputeBudgetMicros = 2000000;

/// Tahapan kuis satu konsep.
enum QuizPhase {
  /// Belum ada sesi.
  idle,

  /// Memuat soal / menyimpan hasil.
  loading,

  /// Menawarkan melanjutkan sesi yang terputus.
  resumeOffer,

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

/// State kuis satu konsep (immutable).
class QuizState extends Equatable {
  final QuizPhase phase;
  final String conceptId;
  final String conceptName;
  final double tau;
  final String? originConceptId;
  final String? originConceptName;

  /// Nama tiap konsep (id -> nama) untuk layar hasil.
  final Map<String, String> names;

  final List<Item> items;
  final int index;
  final int? selected;
  final List<ResponseRecord> records;
  final List<Item> answeredItems;
  final List<QuizResumeAnswer> answerLog;

  final double thetaInit;
  final double thetaGlobal;
  final double seGlobal;
  final double thetaConcept;
  final double seConcept;
  final int consecutiveWrong;
  final int correctCount;
  final int baselineAnswered;

  final String sessionId;
  final bool? lastCorrect;
  final String? errorMessage;

  final SessionDecision? decision;
  final List<String> newlyUnlockedIds;

  /// Kode lencana yang baru diperoleh pada sesi ini.
  final List<String> newBadges;
  final RemedialPlan? remedialPlan;

  /// Potret sesi terputus yang ditawarkan untuk dilanjutkan.
  final QuizResumeSnapshot? pendingResume;

  /// Waktu pemilihan soal terakhir (mikrodetik, diukur Stopwatch).
  final int selectMicroseconds;

  /// Waktu pembaruan theta terakhir (mikrodetik, diukur Stopwatch).
  final int estimateMicroseconds;

  const QuizState({
    this.phase = QuizPhase.idle,
    this.conceptId = '',
    this.conceptName = '',
    this.tau = 0.0,
    this.originConceptId,
    this.originConceptName,
    this.names = const {},
    this.items = const [],
    this.index = 0,
    this.selected,
    this.records = const [],
    this.answeredItems = const [],
    this.answerLog = const [],
    this.thetaInit = 0.0,
    this.thetaGlobal = 0.0,
    this.seGlobal = 1.0,
    this.thetaConcept = 0.0,
    this.seConcept = 1.0,
    this.consecutiveWrong = 0,
    this.correctCount = 0,
    this.baselineAnswered = 0,
    this.sessionId = '',
    this.lastCorrect,
    this.errorMessage,
    this.decision,
    this.newlyUnlockedIds = const [],
    this.newBadges = const [],
    this.remedialPlan,
    this.pendingResume,
    this.selectMicroseconds = 0,
    this.estimateMicroseconds = 0,
  });

  /// Soal yang sedang dikerjakan, null bila tak ada.
  Item? get currentItem =>
      index >= 0 && index < items.length ? items[index] : null;

  /// Jumlah soal yang dijawab sesi ini.
  int get nAnswered => answeredItems.length;

  /// Skor kemampuan konsep dalam persen (0..100).
  double get conceptScorePercent => thetaToPercent(thetaConcept);

  /// Nomor soal berjalan (1-based) untuk tampilan.
  int get questionNumber {
    if (items.isEmpty) return 0;
    if (phase == QuizPhase.feedback ||
        phase == QuizPhase.finishing ||
        phase == QuizPhase.done) {
      return nAnswered.clamp(1, items.length);
    }
    return (nAnswered + 1).clamp(1, items.length);
  }

  /// Nama akar masalah pertama untuk kartu remedial.
  String get rootCauseName {
    final plan = remedialPlan;
    if (plan == null) return conceptName;
    if (plan.rootIds.isNotEmpty) {
      final ordered = plan.orderedPath
          .where((id) => plan.rootIds.contains(id))
          .toList();
      final first = ordered.isEmpty ? plan.rootIds.first : ordered.first;
      return names[first] ?? first;
    }
    return conceptName;
  }

  QuizState copyWith({
    QuizPhase? phase,
    String? conceptId,
    String? conceptName,
    double? tau,
    String? originConceptId,
    bool clearOrigin = false,
    String? originConceptName,
    Map<String, String>? names,
    List<Item>? items,
    int? index,
    int? selected,
    bool clearSelected = false,
    List<ResponseRecord>? records,
    List<Item>? answeredItems,
    List<QuizResumeAnswer>? answerLog,
    double? thetaInit,
    double? thetaGlobal,
    double? seGlobal,
    double? thetaConcept,
    double? seConcept,
    int? consecutiveWrong,
    int? correctCount,
    int? baselineAnswered,
    String? sessionId,
    bool? lastCorrect,
    String? errorMessage,
    bool clearError = false,
    SessionDecision? decision,
    List<String>? newlyUnlockedIds,
    List<String>? newBadges,
    RemedialPlan? remedialPlan,
    QuizResumeSnapshot? pendingResume,
    bool clearResume = false,
    int? selectMicroseconds,
    int? estimateMicroseconds,
  }) {
    return QuizState(
      phase: phase ?? this.phase,
      conceptId: conceptId ?? this.conceptId,
      conceptName: conceptName ?? this.conceptName,
      tau: tau ?? this.tau,
      originConceptId:
          clearOrigin ? null : (originConceptId ?? this.originConceptId),
      originConceptName: clearOrigin
          ? null
          : (originConceptName ?? this.originConceptName),
      names: names ?? this.names,
      items: items ?? this.items,
      index: index ?? this.index,
      selected: clearSelected ? null : (selected ?? this.selected),
      records: records ?? this.records,
      answeredItems: answeredItems ?? this.answeredItems,
      answerLog: answerLog ?? this.answerLog,
      thetaInit: thetaInit ?? this.thetaInit,
      thetaGlobal: thetaGlobal ?? this.thetaGlobal,
      seGlobal: seGlobal ?? this.seGlobal,
      thetaConcept: thetaConcept ?? this.thetaConcept,
      seConcept: seConcept ?? this.seConcept,
      consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
      correctCount: correctCount ?? this.correctCount,
      baselineAnswered: baselineAnswered ?? this.baselineAnswered,
      sessionId: sessionId ?? this.sessionId,
      lastCorrect: lastCorrect ?? this.lastCorrect,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      decision: decision ?? this.decision,
      newlyUnlockedIds: newlyUnlockedIds ?? this.newlyUnlockedIds,
      newBadges: newBadges ?? this.newBadges,
      remedialPlan: remedialPlan ?? this.remedialPlan,
      pendingResume:
          clearResume ? null : (pendingResume ?? this.pendingResume),
      selectMicroseconds: selectMicroseconds ?? this.selectMicroseconds,
      estimateMicroseconds:
          estimateMicroseconds ?? this.estimateMicroseconds,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        conceptId,
        conceptName,
        tau,
        originConceptId,
        originConceptName,
        names,
        items,
        index,
        selected,
        records,
        answeredItems,
        answerLog,
        thetaInit,
        thetaGlobal,
        seGlobal,
        thetaConcept,
        seConcept,
        consecutiveWrong,
        correctCount,
        baselineAnswered,
        sessionId,
        lastCorrect,
        errorMessage,
        decision,
        newlyUnlockedIds,
        newBadges,
        remedialPlan,
        pendingResume,
        selectMicroseconds,
        estimateMicroseconds,
      ];
}

/// Pengendali kuis adaptif satu konsep (Riverpod Notifier).
///
/// Alur: muat soal (theta awal = theta global) -> pilih soal via
/// [selectNextItem] -> jawab, simpan respons, perbarui theta global
/// dan theta konsep -> [evaluateSession] -> lanjut / mastered
/// (status, newlyUnlocked) / failed (status learning +
/// RemedialPlan) -> tutup sesi dan simpan semua state.
///
/// Respons dan theta disimpan setiap soal sehingga progres tidak
/// hilang bila aplikasi tertutup; potret sesi juga disimpan dan
/// ditawarkan untuk dilanjutkan saat dibuka lagi.
class QuizController extends Notifier<QuizState> {
  int _pendingCounter = 0;

  @override
  QuizState build() => const QuizState();

  String _studentId() {
    final id = ref.read(authControllerProvider).profile?.id;
    if (id == null || id.isEmpty) {
      throw const AppException(
          'Sesi Anda telah berakhir. Silakan masuk kembali.', 'auth');
    }
    return id;
  }

  Future<KnowledgeGraph> _loadGraph() async {
    final concepts = ref.read(conceptRepositoryProvider);
    return KnowledgeGraph(
      concepts: await concepts.fetchConcepts(),
      edges: await concepts.fetchEdges(),
    );
  }

  /// Mulai sesi kuis [conceptId]; tawarkan lanjut bila ada potret.
  Future<void> start(String conceptId, {String? originConceptId}) async {
    state = QuizState(
      phase: QuizPhase.loading,
      conceptId: conceptId,
      originConceptId: originConceptId,
    );
    try {
      final itemsRepo = ref.read(itemRepositoryProvider);
      final progress = ref.read(progressRepositoryProvider);
      final resumeStore = ref.read(quizResumeStoreProvider);

      final graph = await _loadGraph();
      final concept = graph.concept(conceptId);
      final items = await itemsRepo.fetchItems(conceptId);
      if (items.isEmpty) {
        throw const AppException(
            'Soal tidak tersedia. Periksa koneksi lalu coba lagi.');
      }
      final ability = await progress.loadAbility();
      final states = await progress.loadConceptStates();
      var baseline = 0;
      for (final s in states) {
        if (s.conceptId == conceptId) baseline = s.nAnswered;
      }
      final names = <String, String>{
        for (final id in graph.conceptIds) id: graph.concept(id).name,
      };

      final snapshot = await resumeStore.load();
      if (snapshot != null && snapshot.conceptId == conceptId) {
        state = state.copyWith(
          phase: QuizPhase.resumeOffer,
          conceptName: concept.name,
          tau: concept.tau,
          originConceptName: originConceptId == null
              ? null
              : names[originConceptId],
          names: names,
          items: items,
          thetaInit: ability.theta,
          thetaGlobal: ability.theta,
          seGlobal: ability.se,
          thetaConcept: ability.theta,
          baselineAnswered: baseline,
          pendingResume: snapshot,
        );
        return;
      }

      await _freshStart(
        conceptId: conceptId,
        conceptName: concept.name,
        tau: concept.tau,
        originConceptId: originConceptId,
        originConceptName:
            originConceptId == null ? null : names[originConceptId],
        names: names,
        items: items,
        thetaInit: ability.theta,
        seInit: ability.se,
        baselineAnswered: baseline,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        phase: QuizPhase.error,
        errorMessage: e.message,
      );
    } on ArgumentError {
      state = state.copyWith(
        phase: QuizPhase.error,
        errorMessage: 'Konsep tidak dikenal.',
      );
    } catch (_) {
      state = state.copyWith(
        phase: QuizPhase.error,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }

  /// Mulai sesi baru yang bersih (seesi lama dibuang).
  Future<void> _freshStart({
    required String conceptId,
    required String conceptName,
    required double tau,
    required String? originConceptId,
    required String? originConceptName,
    required Map<String, String> names,
    required List<Item> items,
    required double thetaInit,
    required double seInit,
    required int baselineAnswered,
  }) async {
    final progress = ref.read(progressRepositoryProvider);
    final resumeStore = ref.read(quizResumeStoreProvider);
    final sessionId = await progress.createSession(conceptId: conceptId);
    final pick = _timedPick(thetaInit, items, const {});
    if (pick.item == null) {
      throw const AppException(
          'Soal tidak tersedia. Periksa koneksi lalu coba lagi.');
    }
    await resumeStore.save(
      QuizResumeSnapshot(
        conceptId: conceptId,
        sessionId: sessionId,
        thetaInit: thetaInit,
        originConceptId: originConceptId,
      ),
    );
    state = QuizState(
      phase: QuizPhase.answering,
      conceptId: conceptId,
      conceptName: conceptName,
      tau: tau,
      originConceptId: originConceptId,
      originConceptName: originConceptName,
      names: names,
      items: items,
      index: items.indexOf(pick.item!),
      thetaInit: thetaInit,
      thetaGlobal: thetaInit,
      seGlobal: seInit,
      thetaConcept: thetaInit,
      baselineAnswered: baselineAnswered,
      sessionId: sessionId,
      selectMicroseconds: pick.microseconds,
    );
  }

  /// Lanjutkan sesi terputus dari [QuizState.pendingResume].
  Future<void> resume() async {
    final snapshot = state.pendingResume;
    if (snapshot == null) return;
    state = state.copyWith(phase: QuizPhase.loading, clearError: true);
    try {
      final itemsRepo = ref.read(itemRepositoryProvider);
      final items = await itemsRepo.fetchItems(state.conceptId);
      if (items.isEmpty) {
        throw const AppException(
            'Soal tidak tersedia. Periksa koneksi lalu coba lagi.');
      }
      final byId = {for (final item in items) item.id: item};
      final rebuilt = <Item>[];
      final rebuiltRecords = <ResponseRecord>[];
      for (final answer in snapshot.answers) {
        final item = byId[answer.itemId];
        if (item == null) {
          // Bank berubah: buang potret, mulai baru yang bersih.
          await _restartFresh();
          return;
        }
        rebuilt.add(item);
        rebuiltRecords.add(
          ResponseRecord(a: item.a, b: item.b, correct: answer.isCorrect),
        );
      }
      var correctCount = 0;
      var consecutiveWrong = 0;
      for (final answer in snapshot.answers) {
        if (answer.isCorrect) {
          correctCount++;
          consecutiveWrong = 0;
        } else {
          consecutiveWrong++;
        }
      }
      final globalEst = estimateEap(
        rebuiltRecords,
        priorMean: snapshot.thetaInit,
      );
      final conceptEst = estimateEap(
        rebuiltRecords,
        priorMean: globalEst.theta,
      );
      final usedIds = {for (final item in rebuilt) item.id};
      final pick = _timedPick(conceptEst.theta, items, usedIds);
      if (pick.item == null) {
        await _finishTerminal(
          rebuiltRecords: rebuiltRecords,
          answeredItems: rebuilt,
          answerLog: snapshot.answers,
          thetaGlobal: globalEst.theta,
          seGlobal: globalEst.se,
          thetaConcept: conceptEst.theta,
          seConcept: conceptEst.se,
          correctCount: correctCount,
          consecutiveWrong: consecutiveWrong,
          selectMicroseconds: pick.microseconds,
        );
        return;
      }
      state = state.copyWith(
        phase: QuizPhase.answering,
        items: items,
        index: items.indexOf(pick.item!),
        records: rebuiltRecords,
        answeredItems: rebuilt,
        answerLog: snapshot.answers,
        thetaGlobal: globalEst.theta,
        seGlobal: globalEst.se,
        thetaConcept: conceptEst.theta,
        seConcept: conceptEst.se,
        correctCount: correctCount,
        consecutiveWrong: consecutiveWrong,
        sessionId: snapshot.sessionId,
        clearResume: true,
        clearSelected: true,
        selectMicroseconds: pick.microseconds,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        phase: QuizPhase.error,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        phase: QuizPhase.error,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }

  /// Buang potret terputus lalu mulai sesi baru.
  Future<void> restart() async {
    await _restartFresh();
  }

  Future<void> _restartFresh() async {
    final conceptId = state.conceptId;
    final originConceptId = state.originConceptId;
    try {
      await ref.read(quizResumeStoreProvider).clear();
    } catch (_) {
      // Abaikan; mulai baru tetap berjalan.
    }
    await start(conceptId, originConceptId: originConceptId);
  }

  /// Pilih opsi jawaban (hanya saat menjawab).
  void select(int optionIndex) {
    if (state.phase != QuizPhase.answering) return;
    state = state.copyWith(selected: optionIndex);
  }

  /// Nilai jawaban, simpan respons + theta, tampilkan umpan balik.
  Future<void> answer() async {
    final item = state.currentItem;
    final selected = state.selected;
    if (state.phase != QuizPhase.answering ||
        item == null ||
        selected == null) {
      return;
    }
    final correct = selected == item.correctIndex;
    final records = [
      ...state.records,
      ResponseRecord(a: item.a, b: item.b, correct: correct),
    ];

    final estimateSw = Stopwatch()..start();
    final conceptEst = estimateEap(records, priorMean: state.thetaGlobal);
    final globalEst = estimateEap(records, priorMean: state.thetaInit);
    estimateSw.stop();

    final consecutiveWrong = correct ? 0 : state.consecutiveWrong + 1;
    final answerLog = [
      ...state.answerLog,
      QuizResumeAnswer(
        itemId: item.id,
        selectedIndex: selected,
        isCorrect: correct,
      ),
    ];

    // Simpan setiap soal: respons, theta global, progres konsep,
    // dan potret sesi. Kegagalan tak menghentikan sesi.
    try {
      final progress = ref.read(progressRepositoryProvider);
      final studentId = _studentId();
      try {
        await progress.saveResponse(
          PendingResponse(
            id: 'quiz-${DateTime.now().microsecondsSinceEpoch}-'
                '${_pendingCounter++}',
            sessionId: state.sessionId,
            itemId: item.id,
            selectedIndex: selected,
            isCorrect: correct,
            thetaAfter: globalEst.theta,
          ),
        );
      } catch (_) {
        // Respons tetap tercatat untuk estimasi; riwayat menyusul.
      }
      try {
        await progress.saveAbility(globalEst);
      } catch (_) {
        // Theta final disimpan ulang saat sesi selesai.
      }
      try {
        await progress.upsertConceptState(
          StudentConceptState(
            studentId: studentId,
            conceptId: state.conceptId,
            status: ConceptStatus.learning,
            thetaC: conceptEst.theta,
            nAnswered: state.baselineAnswered + records.length,
          ),
        );
      } catch (_) {
        // State final disimpan ulang saat sesi selesai.
      }
      try {
        await ref.read(quizResumeStoreProvider).save(
              QuizResumeSnapshot(
                conceptId: state.conceptId,
                sessionId: state.sessionId,
                thetaInit: state.thetaInit,
                originConceptId: state.originConceptId,
                answers: answerLog,
              ),
            );
      } catch (_) {
        // Pemulihan bersifat best-effort.
      }
    } catch (_) {
      // Mis. sesi auth berakhir: sesi lanjut tanpa penyimpanan.
    }

    state = state.copyWith(
      phase: QuizPhase.feedback,
      records: records,
      answeredItems: [...state.answeredItems, item],
      answerLog: answerLog,
      thetaGlobal: globalEst.theta,
      seGlobal: globalEst.se,
      thetaConcept: conceptEst.theta,
      seConcept: conceptEst.se,
      consecutiveWrong: consecutiveWrong,
      correctCount: state.correctCount + (correct ? 1 : 0),
      lastCorrect: correct,
      estimateMicroseconds: estimateSw.elapsedMicroseconds,
    );
  }

  /// Lanjut ke soal berikutnya, atau finalisasi bila sesi tuntas.
  Future<void> next() async {
    if (state.phase != QuizPhase.feedback) return;
    final decision = evaluateSession(
      estimate: AbilityEstimate(
        theta: state.thetaConcept,
        se: state.seConcept,
      ),
      nAnswered: state.nAnswered,
      consecutiveWrong: state.consecutiveWrong,
      tau: state.tau,
    );
    if (decision != SessionDecision.ongoing) {
      await _finishTerminal(
        rebuiltRecords: state.records,
        answeredItems: state.answeredItems,
        answerLog: state.answerLog,
        thetaGlobal: state.thetaGlobal,
        seGlobal: state.seGlobal,
        thetaConcept: state.thetaConcept,
        seConcept: state.seConcept,
        correctCount: state.correctCount,
        consecutiveWrong: state.consecutiveWrong,
        selectMicroseconds: state.selectMicroseconds,
      );
      return;
    }
    if (state.nAnswered >= state.items.length) {
      await _finishByTheta();
      return;
    }
    final usedIds = {for (final item in state.answeredItems) item.id};
    final pick = _timedPick(state.thetaConcept, state.items, usedIds);
    if (pick.item == null) {
      await _finishByTheta();
      return;
    }
    state = state.copyWith(
      phase: QuizPhase.answering,
      index: state.items.indexOf(pick.item!),
      clearSelected: true,
      selectMicroseconds: pick.microseconds,
    );
  }

  /// Finalisasi saat bank habis: tuntas menurut theta akhir.
  Future<void> _finishByTheta() async {
    await _finishTerminal(
      rebuiltRecords: state.records,
      answeredItems: state.answeredItems,
      answerLog: state.answerLog,
      thetaGlobal: state.thetaGlobal,
      seGlobal: state.seGlobal,
      thetaConcept: state.thetaConcept,
      seConcept: state.seConcept,
      correctCount: state.correctCount,
      consecutiveWrong: state.consecutiveWrong,
      selectMicroseconds: state.selectMicroseconds,
      forcedDecision: state.thetaConcept >= state.tau
          ? SessionDecision.mastered
          : SessionDecision.failed,
    );
  }

  /// Finalisasi: simpan status, remedial, tutup sesi.
  Future<void> _finishTerminal({
    required List<ResponseRecord> rebuiltRecords,
    required List<Item> answeredItems,
    required List<QuizResumeAnswer> answerLog,
    required double thetaGlobal,
    required double seGlobal,
    required double thetaConcept,
    required double seConcept,
    required int correctCount,
    required int consecutiveWrong,
    required int selectMicroseconds,
    SessionDecision? forcedDecision,
  }) async {
    if (state.items.isEmpty) {
      await start(state.conceptId,
          originConceptId: state.originConceptId);
      return;
    }
    final decision = forcedDecision ??
        evaluateSession(
          estimate: AbilityEstimate(theta: thetaConcept, se: seConcept),
          nAnswered: answeredItems.length,
          consecutiveWrong: consecutiveWrong,
          tau: state.tau,
        );
    state = state.copyWith(phase: QuizPhase.finishing, clearError: true);
    try {
      final studentId = _studentId();
      final progress = ref.read(progressRepositoryProvider);
      final gamification = ref.read(gamificationRepositoryProvider);
      final graph = await _loadGraph();
      final stored = await progress.loadConceptStates();
      final statesById = {for (final s in stored) s.conceptId: s};
      final nAnswered = state.baselineAnswered + answeredItems.length;

      List<String> newlyUnlockedIds = const [];
      final newBadges = <String>[];
      RemedialPlan? plan;

      Future<void> awardBadgeIfNew(String code) async {
        try {
          if (await gamification.awardBadge(code)) newBadges.add(code);
        } catch (_) {
          // Lencana best-effort; hasil sesi tetap tersimpan.
        }
      }

      if (decision == SessionDecision.mastered) {
        await progress.upsertConceptState(
          StudentConceptState(
            studentId: studentId,
            conceptId: state.conceptId,
            status: ConceptStatus.mastered,
            thetaC: thetaConcept,
            nAnswered: nAnswered,
          ),
        );
        final statusesBefore = graph.computeStatuses(statesById);
        final unlocked = graph.newlyUnlocked(state.conceptId, statusesBefore);
        final order = graph.topologicalOrder();
        newlyUnlockedIds = unlocked.toList()
          ..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
        await awardBadgeIfNew(badgeFirstMastery.code);
        if (state.originConceptId != null) {
          await awardBadgeIfNew(badgeRemedialHero.code);
        }
      } else {
        await progress.upsertConceptState(
          StudentConceptState(
            studentId: studentId,
            conceptId: state.conceptId,
            status: ConceptStatus.learning,
            thetaC: thetaConcept,
            nAnswered: nAnswered,
          ),
        );
        final statusesAfter = graph.computeStatuses({
          ...statesById,
          state.conceptId: StudentConceptState(
            studentId: studentId,
            conceptId: state.conceptId,
            status: ConceptStatus.learning,
            thetaC: thetaConcept,
            nAnswered: nAnswered,
          ),
        });
        plan = graph.buildRemedialPlan(state.conceptId, statusesAfter);
      }

      GamificationState? streakState;
      try {
        streakState = await gamification.updateStreak();
      } catch (_) {
        // Streak best-effort.
      }
      if ((streakState?.streak ?? 0) >= 3) {
        await awardBadgeIfNew(badgeStreak3.code);
      }
      await awardBadgeIfNew(badgeFirstSteps.code);

      await progress.saveAbility(
        AbilityEstimate(theta: thetaGlobal, se: seGlobal),
      );
      await progress.finishSession(
        sessionId: state.sessionId,
        finalTheta: thetaConcept,
      );
      try {
        await ref.read(quizResumeStoreProvider).clear();
      } catch (_) {
        // Abaikan.
      }

      refreshStudentProviders(ref);
      state = state.copyWith(
        phase: QuizPhase.done,
        records: rebuiltRecords,
        answeredItems: answeredItems,
        answerLog: answerLog,
        thetaGlobal: thetaGlobal,
        seGlobal: seGlobal,
        thetaConcept: thetaConcept,
        seConcept: seConcept,
        correctCount: correctCount,
        consecutiveWrong: consecutiveWrong,
        decision: decision,
        newlyUnlockedIds: newlyUnlockedIds,
        newBadges: newBadges,
        remedialPlan: plan,
        clearResume: true,
        selectMicroseconds: selectMicroseconds,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        phase: QuizPhase.error,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        phase: QuizPhase.error,
        errorMessage: 'Terjadi kesalahan. Silakan coba lagi.',
      );
    }
  }

  /// Coba lagi: mulai ulang sesi yang bersih untuk konsep ini.
  Future<void> retry() async {
    if (state.conceptId.isEmpty) return;
    await _restartFresh();
  }

  /// Pilih soal berikutnya sambil mengukur waktunya.
  _Pick _timedPick(double theta, List<Item> items, Set<String> usedIds) {
    final sw = Stopwatch()..start();
    final item = selectNextItem(theta, items, usedIds);
    sw.stop();
    return _Pick(item, sw.elapsedMicroseconds);
  }
}

class _Pick {
  final Item? item;
  final int microseconds;

  const _Pick(this.item, this.microseconds);
}

final quizControllerProvider =
    NotifierProvider<QuizController, QuizState>(QuizController.new);
