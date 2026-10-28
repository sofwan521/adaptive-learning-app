import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/data/repositories/concept_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/item_repository_impl.dart';
import 'package:adaptive_learning_app/data/repositories/progress_repository_impl.dart';
import 'package:adaptive_learning_app/domain/graph/knowledge_graph.dart';
import 'package:adaptive_learning_app/domain/models/ability_estimate.dart';
import 'package:adaptive_learning_app/domain/models/concept_status.dart';
import 'package:adaptive_learning_app/domain/models/item.dart';
import 'package:adaptive_learning_app/domain/models/pending_response.dart';
import 'package:adaptive_learning_app/domain/models/quiz_session.dart';
import 'package:adaptive_learning_app/domain/models/response_history.dart';
import 'package:adaptive_learning_app/domain/repositories/item_repository.dart';
import 'package:adaptive_learning_app/domain/repositories/progress_repository.dart';
import 'package:adaptive_learning_app/features/auth/application/auth_controller.dart';
import 'package:adaptive_learning_app/features/auth/application/placement_provider.dart';
import 'package:adaptive_learning_app/domain/models/student_concept_state.dart';
import 'package:adaptive_learning_app/features/placement/application/placement_controller.dart';

import '../helpers/repository_fakes.dart';

/// Bank 12 soal: 3 konsep x 4, b berbeda, kunci 0, ada pembahasan.
List<Item> placementBank() {
  const specs = [
    ('K01', -1.5),
    ('K01', -0.5),
    ('K01', 0.5),
    ('K01', 1.5),
    ('K02', -1.0),
    ('K02', 0.0),
    ('K02', 1.0),
    ('K02', 2.0),
    ('K03', -2.0),
    ('K03', -0.8),
    ('K03', 0.8),
    ('K03', 1.8),
  ];
  return [
    for (var i = 0; i < specs.length; i++)
      Item(
        id: 'p${i + 1}',
        conceptId: specs[i].$1,
        question: 'Soal placement ${i + 1}',
        options: const ['A', 'B', 'C', 'D'],
        correctIndex: 0,
        a: 1.0,
        b: specs[i].$2,
        explanation: 'Pembahasan P${i + 1}',
      ),
  ];
}

class FakeItemRepository implements ItemRepository {
  List<Item> bank;
  AppException? failure;

  FakeItemRepository({List<Item>? bank}) : bank = bank ?? placementBank();

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
  AbilityEstimate? savedAbility;
  final Map<String, StudentConceptState> states = {};
  int sessionsCreated = 0;
  int sessionsFinished = 0;
  Object? saveFailure;

  @override
  Future<List<StudentConceptState>> loadConceptStates() async =>
      states.values.toList();

  @override
  Future<AbilityEstimate> loadAbility() async =>
      savedAbility ?? const AbilityEstimate(theta: 0, se: 1);

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
    if (saveFailure != null) throw saveFailure!;
    savedResponses.add(response);
    return ResponseSyncStatus.sent;
  }

  @override
  Future<int> countResponsesToday() async => savedResponses.length;

  @override
  Future<String> createSession({String? conceptId}) async {
    sessionsCreated++;
    return 'sesi-1';
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
  FakeConceptRepository? concepts,
}) {
  return ProviderContainer.test(
    overrides: [
      authControllerProvider.overrideWith(() => FixedAuthController()),
      itemRepositoryProvider.overrideWithValue(items ?? FakeItemRepository()),
      progressRepositoryProvider.overrideWithValue(
        progress ?? RecordingProgressRepository(),
      ),
      conceptRepositoryProvider.overrideWithValue(
        concepts ?? FakeConceptRepository(),
      ),
    ],
    retry: (_, __) => null,
  );
}

Item _bankItem(List<Item> bank, double b) =>
    bank.firstWhere((i) => i.b == b);

void main() {
  group('PlacementController', () {
    test('mulai memuat 12 soal dan soal pertama b terdekat 0', () async {
      final container = _container();

      await container.read(placementControllerProvider.notifier).start();
      final state = container.read(placementControllerProvider);

      expect(state.phase, PlacementPhase.answering);
      expect(state.items, hasLength(12));
      expect(state.sessionId, 'sesi-1');
      expect(state.currentItem?.b, 0.0);
      expect(state.questionNumber, 1);
    });

    test('jawab benar memajukan sesi dan menyimpan respons', () async {
      final progress = RecordingProgressRepository();
      final container = _container(progress: progress);
      final controller =
          container.read(placementControllerProvider.notifier);

      await controller.start();
      controller.select(0);
      await controller.answer();
      final state = container.read(placementControllerProvider);

      expect(state.phase, PlacementPhase.feedback);
      expect(state.lastCorrect, isTrue);
      expect(state.correctCount, 1);
      expect(state.theta, greaterThan(0.0));
      expect(progress.savedResponses, hasLength(1));
      expect(progress.savedResponses.single.isCorrect, isTrue);
      expect(progress.savedResponses.single.sessionId, 'sesi-1');
    });

    test('lanjut memilih soal adaptif yang belum dipakai', () async {
      final container = _container();
      final controller =
          container.read(placementControllerProvider.notifier);

      await controller.start();
      final firstId = container
          .read(placementControllerProvider)
          .currentItem!
          .id;
      controller.select(0);
      await controller.answer();
      await controller.next();
      final state = container.read(placementControllerProvider);

      expect(state.phase, PlacementPhase.answering);
      expect(state.selected, isNull);
      expect(state.currentItem?.id, isNot(firstId));
      expect(state.questionNumber, 2);
    });

    test('jawab tanpa memilih tidak berbuat apa-apa', () async {
      final container = _container();
      final controller =
          container.read(placementControllerProvider.notifier);

      await controller.start();
      await controller.answer();

      final state = container.read(placementControllerProvider);
      expect(state.phase, PlacementPhase.answering);
      expect(state.records, isEmpty);
    });

    test('sesi 12 benar tuntas dan menyimpan status peta', () async {
      final progress = RecordingProgressRepository();
      final container = _container(progress: progress);
      final controller =
          container.read(placementControllerProvider.notifier);

      await controller.start();
      for (var n = 0; n < 12; n++) {
        controller.select(0);
        await controller.answer();
        await controller.next();
      }
      final state = container.read(placementControllerProvider);

      expect(state.phase, PlacementPhase.done);
      expect(state.records, hasLength(12));
      expect(progress.savedResponses, hasLength(12));
      expect(state.correctCount, 12);
      expect(progress.savedAbility, isNotNull);
      expect(progress.savedAbility!.theta.isFinite, isTrue);
      expect(progress.savedAbility!.se, greaterThan(0));
      // Semua konsep K01..K03 tersimpan sehingga terlihat di peta.
      expect(progress.states.keys.toSet(), {'K01', 'K02', 'K03'});
      expect(state.masteredIds, isNotEmpty);
      expect(progress.sessionsFinished, 1);
      // Placement ditandai selesai (state tersimpan).
      expect(await container.read(placementCompletedProvider.future), isTrue);
    });

    test('sesi salah semua bertingkat Pemula tanpa mastered', () async {
      final progress = RecordingProgressRepository();
      final container = _container(progress: progress);
      final controller =
          container.read(placementControllerProvider.notifier);

      await controller.start();
      for (var n = 0; n < 12; n++) {
        controller.select(1);
        await controller.answer();
        await controller.next();
      }
      final state = container.read(placementControllerProvider);

      expect(state.phase, PlacementPhase.done);
      expect(state.theta, lessThan(0.0));
      expect(state.scorePercent, lessThan(50));
      expect(placementLevelName(state.scorePercent), 'Pemula');
      expect(state.masteredIds, isEmpty);
      expect(progress.states.keys.toSet(), {'K01', 'K02', 'K03'});
    });

    test('galat simpan respons tak menghentikan sesi', () async {
      final progress = RecordingProgressRepository()
        ..saveFailure = const PostgrestException(
          message: 'ditolak',
          code: '42501',
        );
      final container = _container(progress: progress);
      final controller =
          container.read(placementControllerProvider.notifier);

      await controller.start();
      controller.select(0);
      await controller.answer();

      expect(
        container.read(placementControllerProvider).phase,
        PlacementPhase.feedback,
      );
    });

    test('gagal muat lalu coba lagi berhasil', () async {
      final items = FakeItemRepository()
        ..failure = const AppException('Tidak ada koneksi internet.');
      final container = _container(items: items);
      final controller =
          container.read(placementControllerProvider.notifier);

      await controller.start();
      expect(
        container.read(placementControllerProvider).phase,
        PlacementPhase.error,
      );
      expect(
        container.read(placementControllerProvider).errorMessage,
        'Tidak ada koneksi internet.',
      );

      items.failure = null;
      await controller.retry();
      expect(
        container.read(placementControllerProvider).phase,
        PlacementPhase.answering,
      );
    });
  });

  group('buildInitialStates', () {
    KnowledgeGraph miniGraph() => KnowledgeGraph(
          concepts: testConcepts(),
          edges: testEdges(),
        );

    test('mastered berurutan topologis sesuai ambang', () {
      final states = buildInitialStates(
        graph: miniGraph(),
        theta: 1.0,
        answeredItems: [
          _bankItem(placementBank(), -1.5).copyWith(conceptId: 'K01'),
          _bankItem(placementBank(), -0.5).copyWith(conceptId: 'K01'),
          _bankItem(placementBank(), 0.0).copyWith(conceptId: 'K02'),
          _bankItem(placementBank(), 1.8).copyWith(conceptId: 'K03'),
        ],
        studentId: 'siswa-1',
      );

      // Ambang 0.5: K01 (rerata -1.0) dan K02 (rerata 0.0) lulus;
      // K03 (rerata 1.8) tidak, lalu berstatus open.
      expect(states['K01']?.status, ConceptStatus.mastered);
      expect(states['K01']?.nAnswered, 2);
      expect(states['K01']?.thetaC, 1.0);
      expect(states['K02']?.status, ConceptStatus.mastered);
      expect(states['K03']?.status, ConceptStatus.open);
      expect(states['K03']?.nAnswered, 0);
    });

    test('prasyarat lemah memblokir konsep lanjutan', () {
      final states = buildInitialStates(
        graph: miniGraph(),
        theta: 2.0,
        answeredItems: [
          _bankItem(placementBank(), -1.5).copyWith(conceptId: 'K01'),
          _bankItem(placementBank(), 1.8).copyWith(conceptId: 'K02'),
          _bankItem(placementBank(), -2.0).copyWith(conceptId: 'K03'),
        ],
        studentId: 'siswa-1',
      );

      // Ambang 1.5: K01 lulus; K02 (rerata 1.8) tidak; K03 walau mudah
      // tetap terkunci karena K02 belum mastered.
      expect(states['K01']?.status, ConceptStatus.mastered);
      expect(states['K02']?.status, isNot(ConceptStatus.mastered));
      expect(states['K03']?.status, ConceptStatus.locked);
    });
  });

  group('placementLevelName', () {
    test('batas Pemula, Menengah, Mahir', () {
      expect(placementLevelName(0), 'Pemula');
      expect(placementLevelName(37.9), 'Pemula');
      expect(placementLevelName(38), 'Menengah');
      expect(placementLevelName(60), 'Menengah');
      expect(placementLevelName(73), 'Menengah');
      expect(placementLevelName(73.1), 'Mahir');
      expect(placementLevelName(100), 'Mahir');
    });
  });
}
