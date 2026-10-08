import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../learning/providers/learning_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../progress/providers/progress_provider.dart';
import '../../../core/models/question.dart';

class QuizScreen extends StatefulWidget {
  final String conceptId;

  const QuizScreen({super.key, required this.conceptId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  int _correctAnswers = 0;
  DateTime? _questionStartTime;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() {
    final learningProvider = context.read<LearningProvider>();
    setState(() {
      _questions = learningProvider.getMockQuestions(widget.conceptId);
      _questionStartTime = DateTime.now();
    });
  }

  void _submitAnswer() {
    if (_selectedAnswer == null) return;

    final isCorrect = _selectedAnswer == _questions[_currentQuestionIndex].correctAnswerIndex;

    if (isCorrect) {
      _correctAnswers++;
    }

    setState(() {
      _showResult = true;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _showResult = false;
        _questionStartTime = DateTime.now();
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final learningProvider = context.read<LearningProvider>();
    final authProvider = context.read<AuthProvider>();
    final progressProvider = context.read<ProgressProvider>();

    final accuracy = (_correctAnswers / _questions.length * 100);
    final passed = accuracy >= 70;

    // Update progress
    progressProvider.addProgress(
      questionsAnswered: _questions.length,
      correctAnswers: _correctAnswers,
    );

    // Add XP
    final xpEarned = _correctAnswers * 10;
    authProvider.addXP(xpEarned);

    // Mark concept as mastered if passed
    if (passed) {
      learningProvider.markConceptAsMastered(widget.conceptId);
    }

    // Show result dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(passed ? 'Selamat! 🎉' : 'Hampir! 💪'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.celebration : Icons.refresh,
              size: 64,
              color: passed ? Colors.amber[700] : Colors.orange[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Skor: ${accuracy.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('$_correctAnswers dari ${_questions.length} benar'),
            const SizedBox(height: 16),
            if (passed) ...[
              Text(
                'Kamu menguasai konsep ini! +$xpEarned XP',
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Text(
                'Coba lagi untuk menguasai konsep ini!',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          if (!passed)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentQuestionIndex = 0;
                  _selectedAnswer = null;
                  _showResult = false;
                  _correctAnswers = 0;
                  _questionStartTime = DateTime.now();
                });
              },
              child: const Text('Coba Lagi'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text(passed ? 'Lanjut' : 'Kembali'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = _showResult &&
        _selectedAnswer == currentQuestion.correctAnswerIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text('Kuis ${_currentQuestionIndex + 1}/${_questions.length}'),
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            minHeight: 4,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        currentQuestion.text,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Options
                  Text(
                    'Pilih jawaban:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...currentQuestion.options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = _selectedAnswer == index;
                    final isCorrectAnswer = index == currentQuestion.correctAnswerIndex;

                    Color? backgroundColor;
                    Color? borderColor;

                    if (_showResult) {
                      if (isCorrectAnswer) {
                        backgroundColor = Colors.green[50];
                        borderColor = Colors.green;
                      } else if (isSelected && !isCorrectAnswer) {
                        backgroundColor = Colors.red[50];
                        borderColor = Colors.red;
                      }
                    } else if (isSelected) {
                      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
                      borderColor = Theme.of(context).colorScheme.primary;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: _showResult ? null : () {
                          setState(() {
                            _selectedAnswer = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: backgroundColor ?? Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor ?? Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: borderColor ?? Colors.grey[300],
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    color: (borderColor != null)
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
                              if (_showResult && isCorrectAnswer)
                                const Icon(Icons.check_circle, color: Colors.green),
                              if (_showResult && isSelected && !isCorrectAnswer)
                                const Icon(Icons.cancel, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Explanation (shown after answer)
                  if (_showResult && currentQuestion.explanation != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Penjelasan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(currentQuestion.explanation!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action Button
          Container(
            padding: const EdgeInsets.all(24.0),
            child: FilledButton(
              onPressed: _showResult
                  ? _nextQuestion
                  : (_selectedAnswer != null ? _submitAnswer : null),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(_showResult ? 'Lanjut' : 'Jawab'),
            ),
          ),
        ],
      ),
    );
  }
}
