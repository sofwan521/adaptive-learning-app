import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../learning/providers/learning_provider.dart';

class LearningMaterialScreen extends StatelessWidget {
  final String conceptId;

  const LearningMaterialScreen({super.key, required this.conceptId});

  @override
  Widget build(BuildContext context) {
    final learningProvider = context.watch<LearningProvider>();
    final concept = learningProvider.concepts.firstWhere((c) => c.id == conceptId);
    final isMastered = learningProvider.masteredConceptIds.contains(conceptId);

    return Scaffold(
      appBar: AppBar(
        title: Text(concept.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24.0),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '${concept.difficulty}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              concept.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Level ${concept.difficulty} • ${concept.subject}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      if (isMastered)
                        const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    concept.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),

            // Prerequisites
            if (concept.prerequisites.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prasyarat',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...concept.prerequisites.map((prereqId) {
                      final prereq = learningProvider.concepts
                          .firstWhere((c) => c.id == prereqId);
                      final prereqMastered = learningProvider.masteredConceptIds
                          .contains(prereqId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            prereqMastered ? Icons.check_circle : Icons.circle,
                            color: prereqMastered ? Colors.green : Colors.grey,
                          ),
                          title: Text(prereq.name),
                          subtitle: Text(prereq.description),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => context.push('/learning-material/$prereqId'),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Learning Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Materi Pembelajaran',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mock learning content
                  _buildContentCard(
                    context,
                    'Penjelasan Konsep',
                    'Pelajari dasar-dasar ${concept.name.toLowerCase()} dengan penjelasan lengkap dan contoh.',
                    Icons.book,
                    () {
                      // TODO: Show detailed content
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur akan segera tersedia')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildContentCard(
                    context,
                    'Video Tutorial',
                    'Tonton video pembelajaran interaktif tentang ${concept.name.toLowerCase()}.',
                    Icons.play_circle,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur akan segera tersedia')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  _buildContentCard(
                    context,
                    'Contoh Soal',
                    'Lihat berbagai contoh soal dan cara penyelesaiannya.',
                    Icons.description,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur akan segera tersedia')),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Quiz Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push('/quiz/$conceptId'),
                    icon: const Icon(Icons.quiz),
                    label: const Text('Mulai Kuis'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  if (!isMastered) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Selesaikan kuis dengan skor minimal 70% untuk menguasai konsep ini',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
