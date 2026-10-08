import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../learning/providers/learning_provider.dart';
import '../../../core/models/concept.dart';

class ConceptMapScreen extends StatelessWidget {
  const ConceptMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final learningProvider = context.watch<LearningProvider>();
    final concepts = learningProvider.concepts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Konsep'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Overview
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Progress Pembelajaran',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: learningProvider.getProgressPercentage() / 100,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${learningProvider.masteredConceptIds.length}/${concepts.length} Konsep Dikuasai',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Legend
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keterangan:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(
                          context,
                          Colors.green,
                          'Dikuasai',
                          Icons.check_circle,
                        ),
                        _buildLegendItem(
                          context,
                          Colors.blue,
                          'Tersedia',
                          Icons.circle,
                        ),
                        _buildLegendItem(
                          context,
                          Colors.grey,
                          'Terkunci',
                          Icons.lock,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Concepts by Difficulty
            Text(
              'Konsep Matematika',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(5, (level) {
              final levelConcepts = concepts
                  .where((c) => c.difficulty == level + 1)
                  .toList();

              if (levelConcepts.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Level ${level + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  ...levelConcepts.map((concept) {
                    final isMastered = learningProvider.masteredConceptIds
                        .contains(concept.id);
                    final isLocked = learningProvider.isConceptLocked(concept.id);

                    return _buildConceptCard(
                      context,
                      concept,
                      isMastered,
                      isLocked,
                      learningProvider,
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    Color color,
    String label,
    IconData icon,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildConceptCard(
    BuildContext context,
    Concept concept,
    bool isMastered,
    bool isLocked,
    LearningProvider learningProvider,
  ) {
    Color borderColor;
    Color backgroundColor;
    IconData icon;

    if (isMastered) {
      borderColor = Colors.green;
      backgroundColor = Colors.green[50]!;
      icon = Icons.check_circle;
    } else if (isLocked) {
      borderColor = Colors.grey;
      backgroundColor = Colors.grey[100]!;
      icon = Icons.lock;
    } else {
      borderColor = Colors.blue;
      backgroundColor = Colors.blue[50]!;
      icon = Icons.circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isLocked
            ? () {
                // Show prerequisites dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Konsep Terkunci'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kamu perlu menguasai konsep berikut dulu:'),
                        const SizedBox(height: 12),
                        ...concept.prerequisites.map((prereqId) {
                          final prereq = learningProvider.concepts
                              .firstWhere((c) => c.id == prereqId);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_right, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(prereq.name)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            : () {
                context.push('/learning-material/${concept.id}');
              },
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: borderColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concept.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      concept.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (concept.prerequisites.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: concept.prerequisites.map((prereqId) {
                          final prereq = learningProvider.concepts
                              .firstWhere((c) => c.id == prereqId);
                          return Chip(
                            label: Text(
                              prereq.name,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isLocked)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[600],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
