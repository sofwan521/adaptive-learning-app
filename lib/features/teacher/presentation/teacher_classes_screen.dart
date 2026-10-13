import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/teacher_repository_impl.dart';
import '../../../domain/models/class_info.dart';
import '../../auth/application/auth_controller.dart';

/// Daftar kelas guru: lihat, buat (nama + kode otomatis), dan buka detail.
class TeacherClassesScreen extends ConsumerStatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  ConsumerState<TeacherClassesScreen> createState() =>
      _TeacherClassesScreenState();
}

class _TeacherClassesScreenState
    extends ConsumerState<TeacherClassesScreen> {
  late Future<List<ClassInfo>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _classesFuture = _load();
  }

  Future<List<ClassInfo>> _load() async {
    return ref.read(teacherRepositoryProvider).classes();
  }

  void _reload() {
    setState(() {
      _classesFuture = _load();
    });
  }

  Future<void> _showCreateDialog() async {
    final created = await showDialog<ClassInfo>(
      context: context,
      builder: (dialogContext) => const _CreateClassDialog(),
    );
    if (created != null) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Kelas "${created.name}" dibuat. Kode: ${created.joinCode}',
              ),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelas Saya')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('class-create-fab'),
        icon: const Icon(Icons.add),
        label: const Text('Buat Kelas'),
        onPressed: _showCreateDialog,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FutureBuilder<List<ClassInfo>>(
                future: _classesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const LoadingView(
                      message: 'Memuat kelas…',
                    );
                  }
                  if (snapshot.hasError) {
                    return ErrorView(
                      message: _messageOf(snapshot.error),
                      onRetry: _reload,
                    );
                  }
                  final classes = snapshot.data ?? [];
                  if (classes.isEmpty) {
                    return const EmptyView(
                      message: 'Belum ada kelas. Buat kelas pertamamu '
                          'lalu bagikan kodenya ke siswa.',
                      icon: Icons.class_outlined,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.separated(
                      itemCount: classes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final classInfo = classes[index];
                        return AppCard(
                          onTap: () => context.push(
                            AppRoutes.teacherClassDetail(classInfo.id),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      classInfo.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${classInfo.memberCount} siswa • '
                                      'Kode: ${classInfo.joinCode}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Keluar',
              variant: AppButtonVariant.secondary,
              icon: Icons.logout,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }

  String _messageOf(Object? error) {
    if (error is AppException) return error.message;
    return 'Gagal memuat kelas. Silakan coba lagi.';
  }
}

/// Dialog buat kelas baru.
///
/// StatefulWidget mandiri agar [TextEditingController] hidup selama
/// animasi buka/tutup dialog dan dibuang tepat saat dialog lepas.
class _CreateClassDialog extends ConsumerStatefulWidget {
  const _CreateClassDialog();

  @override
  ConsumerState<_CreateClassDialog> createState() =>
      _CreateClassDialogState();
}

class _CreateClassDialogState extends ConsumerState<_CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    try {
      final created = await ref
          .read(teacherRepositoryProvider)
          .createClass(_controller.text);
      if (mounted) Navigator.of(context).pop(created);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buat Kelas Baru'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('class-name-field'),
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Nama kelas',
            hintText: 'cth. Matematika 7A',
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Nama kelas tidak boleh kosong.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('class-create-submit'),
          onPressed: _submit,
          child: const Text('Buat'),
        ),
      ],
    );
  }
}
