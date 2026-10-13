import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';

/// Rute bersama AdaptiLearn.
abstract final class AppRoutes {
  static const String home = '/';
}

/// Router aplikasi (GoRouter).
///
/// Tahap init: satu rute layar kosong. Rute fitur menyusul.
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
