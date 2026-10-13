import 'package:flutter/foundation.dart';
import '../../../core/models/concept.dart';
import '../../../core/models/question.dart';
import '../../../core/models/quiz_response.dart';
import '../../../core/services/irt_service.dart';
import '../../../core/services/knowledge_graph_service.dart';

class LearningProvider with ChangeNotifier {
  final IRTService _irtService;
  final KnowledgeGraphService _graphService;

  List<Concept> _concepts = [];
  final Set<String> _masteredConceptIds = {};
  Question? _currentQuestion;
  final List<QuizResponse> _responses = [];
  final bool _isLoading = false;

  LearningProvider(this._irtService, this._graphService) {
    _initializeMockData();
  }

  List<Concept> get concepts => _concepts;
  Set<String> get masteredConceptIds => _masteredConceptIds;
  Question? get currentQuestion => _currentQuestion;
  double get currentTheta => _irtService.currentTheta;
  bool get isLoading => _isLoading;

  void _initializeMockData() {
    // Mock data konsep matematika dasar
    _concepts = [
      Concept(
        id: 'c1',
        name: 'Bilangan Bulat',
        description: 'Operasi dasar bilangan bulat',
        prerequisites: [],
        subject: 'Matematika',
        difficulty: 1,
      ),
      Concept(
        id: 'c2',
        name: 'Pecahan',
        description: 'Operasi pecahan dan desimal',
        prerequisites: ['c1'],
        subject: 'Matematika',
        difficulty: 2,
      ),
      Concept(
        id: 'c3',
        name: 'Persamaan Linear',
        description: 'Menyelesaikan persamaan linear satu variabel',
        prerequisites: ['c1'],
        subject: 'Matematika',
        difficulty: 2,
      ),
      Concept(
        id: 'c4',
        name: 'Persamaan Kuadrat',
        description: 'Menyelesaikan persamaan kuadrat',
        prerequisites: ['c3'],
        subject: 'Matematika',
        difficulty: 3,
      ),
      Concept(
        id: 'c5',
        name: 'Fungsi',
        description: 'Konsep fungsi dan grafiknya',
        prerequisites: ['c3'],
        subject: 'Matematika',
        difficulty: 3,
      ),
    ];

    _graphService.initializeGraph(_concepts);
  }

  List<Question> getMockQuestions(String conceptId) {
    // Mock questions untuk placement test
    return [
      Question(
        id: 'q1_$conceptId',
        conceptId: conceptId,
        text: 'Berapakah hasil dari 15 + 28?',
        options: ['41', '42', '43', '44'],
        correctAnswerIndex: 2,
        difficulty: -1.5,
        discrimination: 1.2,
      ),
      Question(
        id: 'q2_$conceptId',
        conceptId: conceptId,
        text: 'Berapakah hasil dari 7 × 8?',
        options: ['54', '56', '58', '60'],
        correctAnswerIndex: 1,
        difficulty: -1.0,
        discrimination: 1.0,
      ),
      Question(
        id: 'q3_$conceptId',
        conceptId: conceptId,
        text: 'Jika x + 5 = 12, maka x = ?',
        options: ['5', '6', '7', '8'],
        correctAnswerIndex: 2,
        difficulty: 0.0,
        discrimination: 1.5,
      ),
      Question(
        id: 'q4_$conceptId',
        conceptId: conceptId,
        text: 'Berapakah hasil dari 3/4 + 1/4?',
        options: ['1/2', '3/4', '1', '4/8'],
        correctAnswerIndex: 2,
        difficulty: 0.5,
        discrimination: 1.3,
      ),
      Question(
        id: 'q5_$conceptId',
        conceptId: conceptId,
        text: 'Selesaikan: 2x - 6 = 10',
        options: ['x = 6', 'x = 7', 'x = 8', 'x = 9'],
        correctAnswerIndex: 2,
        difficulty: 1.0,
        discrimination: 1.4,
      ),
    ];
  }

  void startPlacementTest() {
    _irtService.resetTheta();
    _responses.clear();
    notifyListeners();
  }

  Question? selectNextQuestion(List<Question> availableQuestions) {
    final answeredIds = _responses.map((r) => r.questionId).toList();
    _currentQuestion = _irtService.selectNextQuestion(
      availableQuestions,
      answeredIds,
    );
    notifyListeners();
    return _currentQuestion;
  }

  void submitAnswer({
    required String questionId,
    required int selectedAnswer,
    required bool isCorrect,
    required int timeSpent,
  }) {
    final response = QuizResponse(
      questionId: questionId,
      selectedAnswerIndex: selectedAnswer,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
      timeSpentSeconds: timeSpent,
    );

    _responses.add(response);
    notifyListeners();
  }

  void updateThetaEstimation(List<Question> questions) {
    _irtService.updateTheta(_responses, questions);
    notifyListeners();
  }

  bool isPlacementTestComplete(List<Question> answeredQuestions) {
    return _irtService.isPlacementTestComplete(
      answeredQuestions: answeredQuestions,
      minimumQuestions: 5,
      maxSEM: 0.5,
    );
  }

  List<Concept> getAvailableConcepts() {
    return _graphService.getAvailableConcepts(_masteredConceptIds);
  }

  List<Concept> getRemediallPath(String conceptId) {
    return _graphService.getRemediallPath(conceptId, _masteredConceptIds);
  }

  void markConceptAsMastered(String conceptId) {
    _masteredConceptIds.add(conceptId);
    _graphService.updateConceptStatus(conceptId, isMastered: true);
    notifyListeners();
  }

  bool isConceptLocked(String conceptId) {
    return _graphService.isConceptLocked(conceptId, _masteredConceptIds);
  }

  double getProgressPercentage() {
    return _graphService.getProgressPercentage(_masteredConceptIds);
  }

  String getThetaLevel() {
    return _irtService.thetaToLevel(_irtService.currentTheta);
  }

  double getThetaPercentage() {
    return _irtService.thetaToPercentage(_irtService.currentTheta);
  }
}
