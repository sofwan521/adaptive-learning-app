import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../learning/providers/learning_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final learningProvider = context.watch<LearningProvider>();
    final user = authProvider.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      user.role == 'student' ? 'Siswa' : 'Guru',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.military_tech,
                              size: 32,
                              color: Colors.amber[700],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Level ${user.level}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${user.xp} XP',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 32,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${user.streak}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Hari Streak',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 32,
                              color: Colors.green[700],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${learningProvider.masteredConceptIds.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Konsep',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Learning Info
            if (user.role == 'student' && user.abilityTheta != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Pembelajaran',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          'Tingkat Kelas',
                          'Kelas ${user.gradeLevel ?? '-'}',
                        ),
                        _buildInfoRow(
                          context,
                          'Level Kemampuan',
                          learningProvider.getThetaLevel(),
                        ),
                        _buildInfoRow(
                          context,
                          'Theta Score',
                          user.abilityTheta!.toStringAsFixed(2),
                        ),
                        _buildInfoRow(
                          context,
                          'Progress',
                          '${learningProvider.getProgressPercentage().toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildMenuItem(
                    context,
                    Icons.person,
                    'Edit Profile',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur akan segera tersedia')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.settings,
                    'Pengaturan',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur akan segera tersedia')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.help,
                    'Bantuan',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur akan segera tersedia')),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.info,
                    'Tentang Aplikasi',
                    () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Tentang Aplikasi'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Adaptive Learning App'),
                              SizedBox(height: 8),
                              Text('Versi 1.0.0'),
                              SizedBox(height: 16),
                              Text(
                                'Aplikasi pembelajaran adaptif berbasis Knowledge Graph dan Item Response Theory (IRT).',
                              ),
                              SizedBox(height: 16),
                              Text('© 2026 UIN Malang'),
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
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    context,
                    Icons.logout,
                    'Logout',
                    () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Apakah kamu yakin ingin keluar?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await authProvider.logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
