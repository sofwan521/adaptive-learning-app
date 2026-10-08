import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../learning/providers/learning_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/models/question.dart';

class PlacementTestScreen extends StatefulWidget {
  const PlacementTestScreen({super.key});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  List<Question> _allQuestions = [];
  final List<Question> _answeredQuestions = [];
  Question? _currentQuestion;
  int? _selectedAnswer;
  bool _hasStarted = false;
  DateTime? _questionStartTime;

  @override
  void initState() {
    super.initState();
    // Tunda sampai frame pertama selesai, supaya notifyListeners()
    // tidak dipanggil saat widget sedang dibangun.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final learningProvider = context.read<LearningProvider>();
      learningProvider.startPlacementTest();
      setState(() {
        _allQuestions = learningProvider.getMockQuestions('placement');
      });
    });
  }

  void _startTest() {
    setState(() {
      _hasStarted = true;
    });
    _loadNextQuestion();
  }

  void _loadNextQuestion() {
    final learningProvider = context.read<LearningProvider>();
    final nextQuestion = learningProvider.selectNextQuestion(_allQuestions);

    // Soal habis -> selesaikan tes, jangan stuck di loading
    if (nextQuestion == null) {
      _finishTest();
      return;
    }

    setState(() {
      _currentQuestion = nextQuestion;
      _selectedAnswer = null;
      _questionStartTime = DateTime.now();
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null || _currentQuestion == null) return;

    final learningProvider = context.read<LearningProvider>();
    final isCorrect = _selectedAnswer == _currentQuestion!.correctAnswerIndex;
    final timeSpent = DateTime.now().difference(_questionStartTime!).inSeconds;

    learningProvider.submitAnswer(
      questionId: _currentQuestion!.id,
      selectedAnswer: _selectedAnswer!,
      isCorrect: isCorrect,
      timeSpent: timeSpent,
    );

    _answeredQuestions.add(_currentQuestion!);
    learningProvider.updateThetaEstimation(_answeredQuestions);

    if (learningProvider.isPlacementTestComplete(_answeredQuestions)) {
      _finishTest();
    } else {
      _loadNextQuestion();
    }
  }

  void _finishTest() {
    final learningProvider = context.read<LearningProvider>();
    final authProvider = context.read<AuthProvider>();

    final theta = learningProvider.currentTheta;
    final level = learningProvider.getThetaLevel();

    authProvider.updateUserAbility(theta);

    if (!mounted) return;
    context.pushReplacement('/placement-result', extra: {
      'theta': theta,
      'level': level.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Placement Test'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.quiz,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Placement Test',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Test ini akan mengukur kemampuan matematika dasar kamu menggunakan metode adaptif.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.timer, 'Durasi', '5-10 menit'),
                      const Divider(),
                      _buildInfoRow(Icons.psychology, 'Adaptif',
                          'Soal menyesuaikan kemampuan'),
                      const Divider(),
                      _buildInfoRow(Icons.check_circle, 'Tujuan',
                          'Tentukan level belajar'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _allQuestions.isEmpty ? null : _startTest,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Mulai Test'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentQuestion == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Test'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Soal ${_answeredQuestions.length + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_answeredQuestions.length / 5).clamp(0.0, 1.0),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _currentQuestion!.text,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Pilih jawaban:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._currentQuestion!.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _selectedAnswer == index;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAnswer = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300],
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            child: FilledButton(
              onPressed: _selectedAnswer != null ? _submitAnswer : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Lanjut'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}