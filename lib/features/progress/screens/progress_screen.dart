import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/progress_provider.dart';
import '../../learning/providers/learning_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progressProvider = context.watch<ProgressProvider>();
    final learningProvider = context.watch<LearningProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Belajar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stats Overview
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Soal',
                    '${progressProvider.totalQuestionsAnswered}',
                    Icons.quiz,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Benar',
                    '${progressProvider.totalCorrectAnswers}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Akurasi',
                    '${progressProvider.overallAccuracy.toStringAsFixed(0)}%',
                    Icons.percent,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Streak',
                    '${progressProvider.currentStreak} hari',
                    Icons.local_fire_department,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Level Progress
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level ${user.level}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${user.xp} XP',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (user.xp % 100) / 100,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${100 - (user.xp % 100)} XP lagi ke Level ${user.level + 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ability Level
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kemampuan Matematika',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              learningProvider.getThetaLevel(),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Theta: ${learningProvider.currentTheta.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        CircularProgressIndicator(
                          value: learningProvider.getThetaPercentage() / 100,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey[200],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Concept Mastery
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penguasaan Konsep',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: learningProvider.getProgressPercentage() / 100,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${learningProvider.masteredConceptIds.length} dari ${learningProvider.concepts.length} konsep dikuasai',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: learningProvider.concepts.map((concept) {
                        final isMastered = learningProvider.masteredConceptIds
                            .contains(concept.id);
                        return Chip(
                          avatar: Icon(
                            isMastered ? Icons.check_circle : Icons.circle,
                            size: 16,
                            color: isMastered ? Colors.green : Colors.grey,
                          ),
                          label: Text(concept.name),
                          backgroundColor: isMastered
                              ? Colors.green[50]
                              : Colors.grey[100],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Activity Chart
            if (progressProvider.progressHistory.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivitas 7 Hari Terakhir',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _buildActivityChart(
                          progressProvider.getLastNDays(7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart(List<dynamic> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Belum ada data'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.questionsAnswered.toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
