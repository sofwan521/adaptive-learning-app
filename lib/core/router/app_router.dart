import 'package:go_router/go_router.dart';

import '../../features/dev/presentation/gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';

/// Rute bersama AdaptiLearn.
abstract final class AppRoutes {
  static const String home = '/';
  static const String gallery = '/dev/gallery';
}

/// Router aplikasi (GoRouter).
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.gallery,
      name: 'gallery',
      builder: (context, state) => const GalleryScreen(),
    ),
  ],
);
