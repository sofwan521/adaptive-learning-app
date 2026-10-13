import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/validators.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/models/user_role.dart';
import '../application/auth_controller.dart';

/// Layar pendaftaran akun Siswa atau Guru.
///
/// Tanpa logika bisnis — memanggil [AuthController] lalu redirect
/// router yang mengarahkan sesuai peran.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          role: _role,
        );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    ref.read(authControllerProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        _showError(next.errorMessage!);
      }
    });
    final auth = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Buat akun AdaptiLearn',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  Text('Saya mendaftar sebagai:', style: textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.student,
                        label: Text('Siswa'),
                        icon: Icon(Icons.backpack_outlined),
                      ),
                      ButtonSegment(
                        value: UserRole.teacher,
                        label: Text('Guru'),
                        icon: Icon(Icons.person_outlined),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: (selected) =>
                        setState(() => _role = selected.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register-name'),
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                      hintText: 'Contoh: Budi Santoso',
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: validateName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register-email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Surel',
                      hintText: 'nama@contoh.id',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register-password'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      hintText: 'Minimal 8 karakter, huruf dan angka',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Lihat sandi'
                            : 'Sembunyikan sandi',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('register-confirm'),
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi kata sandi',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) => validateConfirmPassword(
                      _passwordController.text,
                      value,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    key: const Key('register-submit'),
                    label: 'Daftar',
                    isLoading: auth.isLoading,
                    onPressed: auth.isLoading ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Sudah punya akun?'),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Masuk'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
