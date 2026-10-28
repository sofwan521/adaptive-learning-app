import 'dart:async';

import 'package:adaptive_learning_app/core/error/app_exception.dart';
import 'package:adaptive_learning_app/domain/models/ability_estimate.dart';
import 'package:adaptive_learning_app/domain/models/concept.dart';
import 'package:adaptive_learning_app/domain/models/concept_edge.dart';
import 'package:adaptive_learning_app/domain/models/concept_status.dart';
import 'package:adaptive_learning_app/domain/models/gamification_state.dart';
import 'package:adaptive_learning_app/domain/models/learning_material.dart';
import 'package:adaptive_learning_app/domain/models/pending_response.dart';
import 'package:adaptive_learning_app/domain/models/quiz_session.dart';
import 'package:adaptive_learning_app/domain/models/response_history.dart';
import 'package:adaptive_learning_app/domain/models/student_concept_state.dart';
import 'package:adaptive_learning_app/domain/models/user_profile.dart';
import 'package:adaptive_learning_app/domain/models/user_role.dart';
import 'package:adaptive_learning_app/domain/repositories/auth_repository.dart';
import 'package:adaptive_learning_app/domain/repositories/concept_repository.dart';
import 'package:adaptive_learning_app/domain/repositories/gamification_repository.dart';
import 'package:adaptive_learning_app/domain/repositories/progress_repository.dart';

/// Profil siswa untuk uji.
const testStudent = UserProfile(
  id: 'siswa-1',
  fullName: 'Siswa Uji',
  role: UserRole.student,
);

/// Graf mini K01 -> K02 -> K03 untuk uji.
List<Concept> testConcepts() => const [
      Concept(
        id: 'K01',
        code: 'K01',
        name: 'Bilangan Bulat',
        description: 'Operasi bilangan bulat.',
        tau: 0.0,
      ),
      Concept(
        id: 'K02',
        code: 'K02',
        name: 'Operasi Aljabar',
        description: 'Bentuk aljabar.',
        tau: 0.0,
      ),
      Concept(
        id: 'K03',
        code: 'K03',
        name: 'Persamaan Linear',
        description: 'PLSV.',
        tau: 0.2,
      ),
    ];

List<ConceptEdge> testEdges() => const [
      ConceptEdge(prerequisiteId: 'K01', conceptId: 'K02'),
      ConceptEdge(prerequisiteId: 'K02', conceptId: 'K03'),
    ];

StudentConceptState masteredState(String conceptId) => StudentConceptState(
      studentId: testStudent.id,
      conceptId: conceptId,
      status: ConceptStatus.mastered,
      nAnswered: 8,
    );

StudentConceptState learningState(String conceptId) => StudentConceptState(
      studentId: testStudent.id,
      conceptId: conceptId,
      status: ConceptStatus.learning,
      nAnswered: 5,
    );

class FakeAuthRepository implements AuthRepository {
  UserProfile? profile;

  FakeAuthRepository({this.profile = testStudent});

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    profile = testStudent;
    return profile!;
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    profile = UserProfile(id: 'baru-1', fullName: fullName, role: role);
    return profile!;
  }

  @override
  Future<void> signOut() async => profile = null;

  @override
  Future<UserProfile?> currentProfile() async => profile;

  @override
  Stream<UserProfile?> authStateChanges() => Stream.value(profile);
}

class FakeConceptRepository implements ConceptRepository {
  List<Concept> concepts;
  List<ConceptEdge> edges;
  AppException? failure;
  Future<void> gate = Future.value();

  FakeConceptRepository({
    List<Concept>? concepts,
    List<ConceptEdge>? edges,
  })  : concepts = concepts ?? testConcepts(),
        edges = edges ?? testEdges();

  @override
  Future<List<Concept>> fetchConcepts() async {
    await gate;
    if (failure != null) throw failure!;
    return concepts;
  }

  @override
  Future<List<ConceptEdge>> fetchEdges() async {
    await gate;
    if (failure != null) throw failure!;
    return edges;
  }

  @override
  Future<LearningMaterial> fetchMaterial(String conceptId) {
    throw UnimplementedError();
  }
}

class FakeProgressRepository implements ProgressRepository {
  List<StudentConceptState> states;
  List<QuizSession> sessions;
  List<ResponseHistoryEntry> responses;
  int answeredToday;
  AppException? failure;

  FakeProgressRepository({
    List<StudentConceptState>? states,
    List<QuizSession>? sessions,
    List<ResponseHistoryEntry>? responses,
    this.answeredToday = 0,
  })  : states = states ?? [],
        sessions = sessions ?? [],
        responses = responses ?? [];

  @override
  Future<List<StudentConceptState>> loadConceptStates() async {
    if (failure != null) throw failure!;
    return states;
  }

  @override
  Future<int> countResponsesToday() async {
    if (failure != null) throw failure!;
    return answeredToday;
  }

  @override
  Future<AbilityEstimate> loadAbility() async =>
      const AbilityEstimate(theta: 0, se: 1);

  @override
  Future<void> saveAbility(AbilityEstimate estimate) async {}

  @override
  Future<void> upsertConceptState(StudentConceptState state) async {}

  @override
  Future<ResponseSyncStatus> saveResponse(PendingResponse response) async =>
      ResponseSyncStatus.sent;

  @override
  Future<int> flushPending() async => 0;

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<String> createSession({String? conceptId}) async => 'sesi-1';

  @override
  Future<void> finishSession({
    required String sessionId,
    required double finalTheta,
  }) async {}

  @override
  Future<List<QuizSession>> history({int limit = 20}) async {
    if (failure != null) throw failure!;
    return sessions.take(limit).toList();
  }

  @override
  Future<List<ResponseHistoryEntry>> loadResponseHistory({
    int limit = 300,
  }) async {
    if (failure != null) throw failure!;
    return responses.take(limit).toList();
  }
}

class FakeGamificationRepository implements GamificationRepository {
  GamificationState state;
  AppException? failure;
  final Set<String> badgeCodes = {};

  FakeGamificationRepository({GamificationState? state})
      : state = state ??
            const GamificationState(
              studentId: 'siswa-1',
              streak: 4,
            );

  @override
  Future<GamificationState> load() async {
    if (failure != null) throw failure!;
    return state;
  }

  @override
  Future<GamificationState> updateStreak() async => state;

  @override
  Future<Set<String>> loadBadgeCodes() async => Set.of(badgeCodes);

  @override
  Future<bool> awardBadge(String code) async {
    return badgeCodes.add(code);
  }
}
