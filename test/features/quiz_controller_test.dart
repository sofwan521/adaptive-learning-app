import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/data/datasources/quiz_resume_store.dart';
import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/gamification_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/item_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/domain/irt/irt_engine.dart';
import 'package:adaptive_learning_app/domain/models/ability_estimate.dart';
import 'package:adaptive_learning_app/domain/models/concept_status.dart';
import 'package:adaptive_learning_app/domain/models/gamification_state.dart';
import 'package:adaptive_learning_app/domain/models/item.dart';
import 'package:adaptive_learning_app/domain/models/pending_response.dart';
import 'package:adaptive_learning_app/domain/models/quiz_session.dart';
import 'package:adaptive_learning_app/domain/models/response_history.dart';
import 'package:adaptive_learning_app/domain/models/response_record.dart';
import 'package:adaptive_learning_app/domain/models/student_concept_state.dart';
import 'package:adaptive_learning_app/domain/repositories/gamification_repository.dart';
import 'package:adaptive_learning_app/domain/repositories/item_repository.dart';
import 'package:adaptive_learning_app/domain/repositories/progress_repository.dart';
import 'package:adaptive_learning_app/features/auth/application/auth_controller.dart';
import 'package:adaptive_learning_app/features/quiz/application/quiz_controller.dart';

import '../helpers/repository_fakes.dart';

/// Bank 8 soal K02 seperti seed: b menaik -2..2, kunci 0, ada pembahasan.
List<Item> quizBank() {
  const difficulties = [-2.0, -1.5, -1.0, -0.5, 0.0, 0.7, 1.4, 2.0];
  return [
    for (var i = 0; i < difficulties.length; i++)
      Item(
        id: 'k02-q${i + 1}',
        conceptId: 'K02',
        question: 'Soal K02 nomor ${i + 1}',
        options: const ['A', 'B', 'C', 'D'],
        correctIndex: 0,
        a: 1.0,
        b: difficulties[i],
        explanation: 'Pembahasan K02-${i + 1}',
      ),
  ];
}

class FakeItemRepository implements ItemRepository {
  List<Item> bank;
  AppException? failure;

  FakeItemRepository({List<Item>? bank}) : bank = bank ?? quizBank();

  @override
  Future<List<Item>> fetchPlacementItems({int limit = 20}) async {
    if (failure != null) throw failure!;
    return bank.take(limit).toList();
  }

  @override
  Future<List<Item>> fetchItems(String conceptId) async {
    if (failure != null) throw failure!;
    return bank.where((i) => i.conceptId == conceptId).toList();
  }
}

class RecordingProgressRepository implements ProgressRepository {
  final List<PendingResponse> savedResponses = [];
  AbilityEstimate savedAbility = const AbilityEstimate(theta: 0, se: 1);
  final Map<String, StudentConceptState> states = {};
  int sessionsCreated = 0;
  int sessionsFinished = 0;

  @override
  Future<List<StudentConceptState>> loadConceptStates() async =>
      states.values.toList();

  @override
  Future<AbilityEstimate> loadAbility() async => savedAbility;

  @override
  Future<void> saveAbility(AbilityEstimate estimate) async {
    savedAbility = estimate;
  }

  @override
  Future<void> upsertConceptState(StudentConceptState state) async {
    states[state.conceptId] = state;
  }

  @override
  Future<ResponseSyncStatus> saveResponse(PendingResponse response) async {
    savedResponses.add(response);
    return ResponseSyncStatus.sent;
  }

  @override
  Future<int> countResponsesToday() async => savedResponses.length;

  @override
  Future<String> createSession({String? conceptId}) async {
    sessionsCreated++;
    return 'sesi-kuis-1';
  }

  @override
  Future<void> finishSession({
    required String sessionId,
    required double finalTheta,
  }) async {
    sessionsFinished++;
  }

  @override
  Future<int> flushPending() async => 0;

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<List<QuizSession>> history({int limit = 20}) async => [];

  @override
  Future<List<ResponseHistoryEntry>> loadResponseHistory({
    int limit = 300,
  }) async =>
      [];
}

class RecordingGamificationRepository implements GamificationRepository {
  GamificationState state = const GamificationState(
    studentId: 'siswa-1',
    xp: 120,
    level: 2,
    streak: 4,
  );
  int addXpCalls = 0;
  int streakCalls = 0;
  final Set<String> badgeCodes = {};
  final List<String> awardedOrder = [];

  @override
  Future<GamificationState> load() async => state;

  @override
  Future<GamificationState> addXp(int xp) async {
    addXpCalls++;
    state = GamificationState(
      studentId: state.studentId,
      xp: state.xp + xp,
      level: (state.xp + xp) ~/ 100 + 1,
      streak: state.streak,
      lastActiveDate: state.lastActiveDate,
    );
    return state;
  }

  @override
  Future<GamificationState> updateStreak() async {
    streakCalls++;
    return state;
  }

  @override
  Future<Set<String>> loadBadgeCodes() async => Set.of(badgeCodes);

  @override
  Future<bool> awardBadge(String code) async {
    if (!badgeCodes.add(code)) return false;
    awardedOrder.add(code);
    return true;
  }
}

class MemoryResumeStore implements QuizResumeStore {
  QuizResumeSnapshot? snapshot;

  @override
  Future<QuizResumeSnapshot?> load() async => snapshot;

  @override
  Future<void> save(QuizResumeSnapshot value) async {
    snapshot = value;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}

class FixedAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticated,
        profile: testStudent,
      );
}

ProviderContainer _container({
  FakeItemRepository? items,
  RecordingProgressRepository? progress,
  RecordingGamificationRepository? gamification,
  MemoryResumeStore? resume,
  FakeConceptRepository? concepts,
}) {
  return ProviderContainer.test(
    overrides: [
      authControllerProvider.overrideWith(() => FixedAuthController()),
      itemRepositoryProvider.overrideWithValue(items ?? FakeItemRepository()),
      progressRepositoryProvider.overrideWithValue(
        progress ?? RecordingProgressRepository(),
      ),
      gamificationRepositoryProvider.overrideWithValue(
        gamification ?? RecordingGamificationRepository(),
      ),
      quizResumeStoreProvider.overrideWithValue(resume ?? MemoryResumeStore()),
      conceptRepositoryProvider.overrideWithValue(
        concepts ?? FakeConceptRepository(),
      ),
    ],
    retry: (_, __) => null,
  );
}

Future<void> _answerCorrect(QuizController controller) async {
  final item = controller.state.currentItem!;
  controller.select(item.correctIndex);
  await controller.answer();
  await controller.next();
}

Future<void> _answerWrong(QuizController controller) async {
  final item = controller.state.currentItem!;
  controller.select((item.correctIndex + 1) % item.options.length);
  await controller.answer();
  await controller.next();
}

void main() {
  group('QuizController mulai', () {
    test('theta awal = theta global; soal pertama paling informatif',
        () async {
      final progress = RecordingProgressRepository()
        ..savedAbility = const AbilityEstimate(theta: 0.5, se: 0.9);
      final container = _container(progress: progress);
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      final state = container.read(quizControllerProvider);

      expect(state.phase, QuizPhase.answering);
      expect(state.thetaGlobal, 0.5);
      expect(state.thetaInit, 0.5);
      expect(state.sessionId, 'sesi-kuis-1');
      // Soal pertama = informasi Fisher maksimum pada theta 0.5.
      final expected = selectNextItem(0.5, quizBank(), const {});
      expect(state.currentItem?.id, expected?.id);
      expect(state.questionNumber, 1);
    });

    test('bank kosong menjadi galat lalu retry berhasil', () async {
      final items = FakeItemRepository()..bank = [];
      final container = _container(items: items);
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      expect(
        container.read(quizControllerProvider).phase,
        QuizPhase.error,
      );

      items.bank = quizBank();
      await controller.retry();
      expect(
        container.read(quizControllerProvider).phase,
        QuizPhase.answering,
      );
    });

    test('konsep tak dikenal menjadi galat ramah', () async {
      final container = _container();
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('ZZZ');
      final state = container.read(quizControllerProvider);

      expect(state.phase, QuizPhase.error);
      expect(state.errorMessage, isNotEmpty);
    });
  });

  group('QuizController menjawab', () {
    test('jawaban tersimpan tiap soal: respons, theta, state, potret',
        () async {
      final progress = RecordingProgressRepository();
      final resume = MemoryResumeStore();
      final container =
          _container(progress: progress, resume: resume);
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      final item = container.read(quizControllerProvider).currentItem!;
      controller.select(item.correctIndex);
      await controller.answer();
      final state = container.read(quizControllerProvider);

      expect(state.phase, QuizPhase.feedback);
      expect(state.lastCorrect, isTrue);
      expect(state.records, hasLength(1));
      expect(progress.savedResponses, hasLength(1));
      expect(progress.savedResponses.single.sessionId, 'sesi-kuis-1');
      // Theta global dan konsep diperbarui.
      expect(progress.savedAbility.theta, greaterThan(0.0));
      expect(state.thetaConcept, greaterThan(0.0));
      // Progres konsep berjalan tersimpan (tahan crash).
      expect(progress.states['K02']?.status, ConceptStatus.learning);
      expect(progress.states['K02']?.nAnswered, 1);
      // Potret sesi tersimpan untuk tawaran lanjut.
      expect(resume.snapshot?.conceptId, 'K02');
      expect(resume.snapshot?.answers, hasLength(1));
    });

    test('lanjut memilih soal adaptif yang belum dipakai', () async {
      final container = _container();
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      final firstId =
          container.read(quizControllerProvider).currentItem!.id;
      final item = container.read(quizControllerProvider).currentItem!;
      controller.select(item.correctIndex);
      await controller.answer();
      await controller.next();
      final state = container.read(quizControllerProvider);

      expect(state.phase, QuizPhase.answering);
      expect(state.currentItem?.id, isNot(firstId));
      expect(state.questionNumber, 2);
    });

    test('jawab tanpa memilih tidak berbuat apa-apa', () async {
      final container = _container();
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      await controller.answer();

      final state = container.read(quizControllerProvider);
      expect(state.phase, QuizPhase.answering);
      expect(state.records, isEmpty);
    });
  });

  group('QuizController lulus', () {
    test('8 benar tuntas mastered + XP + konsep terbuka', () async {
      final progress = RecordingProgressRepository()
        ..states['K01'] = masteredState('K01');
      final gamification = RecordingGamificationRepository();
      final resume = MemoryResumeStore();
      final container = _container(
        progress: progress,
        gamification: gamification,
        resume: resume,
      );
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      for (var n = 0; n < 8; n++) {
        await _answerCorrect(controller);
      }
      final state = container.read(quizControllerProvider);

      expect(state.phase, QuizPhase.done);
      expect(state.decision, SessionDecision.mastered);
      expect(progress.states['K02']?.status, ConceptStatus.mastered);
      expect(progress.states['K02']?.nAnswered, 8);
      // K03 terbuka karena K01 dan K02 kini mastered.
      expect(state.newlyUnlockedIds, contains('K03'));
      // XP diberikan dan sesi ditutup; potret dibersihkan.
      // 8 benar (80) + lulus (50) + konsep baru (100) = 230.
      expect(gamification.addXpCalls, 1);
      expect(state.xpEarned, 230);
      expect(state.xpTotal, 120 + 230);
      expect(state.leveledUp, isFalse);
      // Lencana langkah pertama dan konsep pertama diperoleh.
      expect(state.newBadges, contains('langkah-pertama'));
      expect(state.newBadges, contains('konsep-pertama'));
      expect(
        gamification.badgeCodes,
        containsAll(['langkah-pertama', 'konsep-pertama']),
      );
      expect(progress.sessionsFinished, 1);
      expect(resume.snapshot, isNull);
      expect(progress.savedResponses, hasLength(8));
    });

    test('bonus besar menaikkan level', () async {
      final progress = RecordingProgressRepository()
        ..states['K01'] = masteredState('K01');
      final gamification = RecordingGamificationRepository()
        ..state = const GamificationState(
          studentId: 'siswa-1',
          xp: 390,
          level: 2,
          streak: 4,
        );
      final container = _container(
        progress: progress,
        gamification: gamification,
      );
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      for (var n = 0; n < 8; n++) {
        await _answerCorrect(controller);
      }
      final state = container.read(quizControllerProvider);

      expect(state.decision, SessionDecision.mastered);
      expect(state.xpEarned, 230);
      expect(state.xpTotal, 620);
      expect(state.leveledUp, isTrue);
    });

    test('lulus remedial memberi lencana pahlawan remedial', () async {
      final progress = RecordingProgressRepository()
        ..states['K01'] = masteredState('K01');
      final gamification = RecordingGamificationRepository();
      final container = _container(
        progress: progress,
        gamification: gamification,
      );
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02', originConceptId: 'K03');
      for (var n = 0; n < 8; n++) {
        await _answerCorrect(controller);
      }
      final state = container.read(quizControllerProvider);

      expect(state.decision, SessionDecision.mastered);
      expect(state.newBadges, contains('pahlawan-remedial'));
    });
  });

  group('QuizController gagal dan remedial', () {
    test('3 salah beruntun gagal dini + rencana remedial', () async {
      final progress = RecordingProgressRepository();
      final gamification = RecordingGamificationRepository();
      final container = _container(
        progress: progress,
        gamification: gamification,
      );
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      for (var n = 0; n < 3; n++) {
        await _answerWrong(controller);
      }
      final state = container.read(quizControllerProvider);

      expect(state.phase, QuizPhase.done);
      expect(state.decision, SessionDecision.failed);
      expect(progress.states['K02']?.status, ConceptStatus.learning);
      expect(gamification.addXpCalls, 0);
      expect(state.xpEarned, 0);
      // Akar masalah K01 (satu-satunya prasyarat lemah K02).
      final plan = state.remedialPlan!;
      expect(plan.orderedPath.last, 'K02');
      expect(plan.rootIds, contains('K01'));
      expect(state.rootCauseName, 'Bilangan Bulat');
      expect(progress.sessionsFinished, 1);
      // Lencana langkah pertama tetap diperoleh walau gagal.
      expect(state.newBadges, contains('langkah-pertama'));
    });

    test('gagal dengan jawaban benar tetap memberi XP jawaban', () async {
      final progress = RecordingProgressRepository();
      final gamification = RecordingGamificationRepository();
      final container = _container(
        progress: progress,
        gamification: gamification,
      );
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      await _answerCorrect(controller);
      await _answerCorrect(controller);
      await _answerWrong(controller);
      await _answerWrong(controller);
      await _answerWrong(controller);
      final state = container.read(quizControllerProvider);

      expect(state.phase, QuizPhase.done);
      expect(state.decision, SessionDecision.failed);
      // 2 benar (20), tanpa bonus lulus/penguasaan.
      expect(gamification.addXpCalls, 1);
      expect(state.xpEarned, 20);
      expect(state.leveledUp, isFalse);
    });
  });

  group('QuizController lanjutkan sesi', () {
    test('tawarkan lanjut lalu resume memulihkan progres', () async {
      final resume = MemoryResumeStore();
      final container = _container(resume: resume);
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      for (var n = 0; n < 2; n++) {
        final item = container.read(quizControllerProvider).currentItem!;
        controller.select(item.correctIndex);
        await controller.answer();
        await controller.next();
      }
      expect(resume.snapshot?.answers, hasLength(2));

      // Buka lagi: ditawari melanjutkan.
      await controller.start('K02');
      expect(
        container.read(quizControllerProvider).phase,
        QuizPhase.resumeOffer,
      );

      await controller.resume();
      final resumed = container.read(quizControllerProvider);
      expect(resumed.phase, QuizPhase.answering);
      expect(resumed.records, hasLength(2));
      expect(resumed.correctCount, 2);
      expect(resumed.sessionId, 'sesi-kuis-1');
      expect(resumed.questionNumber, 3);
    });

    test('mulai baru membuang potret dan mengosongkan jawaban', () async {
      final resume = MemoryResumeStore();
      final container = _container(resume: resume);
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      final item = container.read(quizControllerProvider).currentItem!;
      controller.select(item.correctIndex);
      await controller.answer();

      await controller.start('K02');
      expect(
        container.read(quizControllerProvider).phase,
        QuizPhase.resumeOffer,
      );
      await controller.restart();

      final state = container.read(quizControllerProvider);
      expect(state.phase, QuizPhase.answering);
      expect(state.records, isEmpty);
      expect(resume.snapshot?.answers, isEmpty);
    });
  });

  group('QuizController kinerja', () {
    test('pemilihan soal + pembaruan theta di bawah 2 detik', () async {
      final container = _container();
      final controller = container.read(quizControllerProvider.notifier);

      await controller.start('K02');
      for (var n = 0; n < 4; n++) {
        final item = container.read(quizControllerProvider).currentItem!;
        controller.select(item.correctIndex);
        await controller.answer();
        if (n < 3) await controller.next();
      }
      final state = container.read(quizControllerProvider);

      expect(state.selectMicroseconds, lessThan(quizComputeBudgetMicros));
      expect(state.estimateMicroseconds, lessThan(quizComputeBudgetMicros));
    });

    test('komputasi murni 64 soal + 10 respons di bawah 2 detik', () {
      final bank = [
        for (var i = 0; i < 64; i++)
          Item(
            id: 'm$i',
            conceptId: 'K03',
            question: 'Soal $i',
            options: const ['A', 'B', 'C', 'D'],
            correctIndex: 0,
            a: 1.0,
            b: -2.0 + i * (4.0 / 63),
          ),
      ];
      final records = [
        for (var i = 0; i < 10; i++)
          ResponseRecord(a: 1.0, b: 0.0, correct: i.isEven),
      ];

      final sw = Stopwatch()..start();
      final pick = selectNextItem(0.3, bank, {'m0', 'm1'});
      final estimate = estimateEap(records, priorMean: 0.3);
      sw.stop();

      expect(pick, isNotNull);
      expect(estimate.theta.isFinite, isTrue);
      expect(sw.elapsedMicroseconds, lessThan(quizComputeBudgetMicros));
    });
  });
}
