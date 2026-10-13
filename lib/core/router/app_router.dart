import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/user_role.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/placement_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/dev/presentation/gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/learning/presentation/quiz_screen.dart';
import '../../features/placement/presentation/placement_result_screen.dart';
import '../../features/placement/presentation/placement_screen.dart';
import '../../features/placement/presentation/placement_test_screen.dart';
import '../../features/student/presentation/student_home_screen.dart';
import '../../features/student/presentation/student_map_screen.dart';
import '../../features/student/presentation/student_profile_screen.dart';
import '../../features/student/presentation/student_progress_screen.dart';
import '../../features/student/presentation/student_shell.dart';
import '../../features/teacher/presentation/teacher_classes_screen.dart';

/// Rute bersama AdaptiLearn.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String placement = '/placement';
  static const String placementTest = '/placement/test';
  static const String placementResult = '/placement/result';
  static const String studentHome = '/student/home';
  static const String studentMap = '/student/map';
  static const String studentProgress = '/student/progress';
  static const String studentProfile = '/student/profile';
  static const String teacherClasses = '/teacher/classes';
  static const String gallery = '/dev/gallery';

  /// Rute kuis satu konsep.
  static String studentQuiz(String conceptId) => '/student/quiz/$conceptId';
}

/// Rute publik yang boleh dibuka tanpa sesi.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
};

/// Router dengan redirect berbasis peran.
///
/// - Belum masuk (atau sesi diperiksa) -> /splash lalu /login.
/// - Siswa belum placement test -> /placement.
/// - Siswa -> /student/home; guru/admin -> /teacher/classes.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  final placement = ref.watch(placementCompletedProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final authenticated =
          auth.status == AuthStatus.authenticated && auth.profile != null;

      if (!authenticated) {
        if (auth.status == AuthStatus.initial ||
            auth.status == AuthStatus.loading) {
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        }
        // Splash hanya tempat transit saat sesi diperiksa.
        if (location == AppRoutes.splash) return AppRoutes.login;
        if (_publicRoutes.contains(location)) return null;
        return AppRoutes.login;
      }

      final role = auth.profile!.role;
      if (role == UserRole.teacher || role == UserRole.admin) {
        if (location.startsWith('/teacher') ||
            location == AppRoutes.gallery) {
          return null;
        }
        return AppRoutes.teacherClasses;
      }

      // Peran siswa: placement dulu bila belum tuntas.
      if (placement.isLoading) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }
      final done = placement.value ?? false;
      // Halaman hasil boleh dibuka agar bisa dilihat tepat setelah tes.
      if (location == AppRoutes.placementResult) return null;
      if (location == AppRoutes.placement) {
        return done ? AppRoutes.studentHome : null;
      }
      // Layar tes hanya selama placement belum tuntas (tidak bisa diulang).
      if (location == AppRoutes.placementTest) {
        return done ? AppRoutes.studentHome : null;
      }
      if (location.startsWith('/student')) {
        return done ? null : AppRoutes.placement;
      }
      if (location.startsWith('/teacher')) {
        return done ? AppRoutes.studentHome : AppRoutes.placement;
      }
      if (location == AppRoutes.gallery) return null;
      return done ? AppRoutes.studentHome : AppRoutes.placement;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.placement,
        name: 'placement',
        builder: (context, state) => const PlacementScreen(),
      ),
      GoRoute(
        path: AppRoutes.placementTest,
        name: 'placement-test',
        builder: (context, state) => const PlacementTestScreen(),
      ),
      GoRoute(
        path: AppRoutes.placementResult,
        name: 'placement-result',
        builder: (context, state) => const PlacementResultScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StudentShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentHome,
                name: 'student-home',
                builder: (context, state) => const StudentHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentMap,
                name: 'student-map',
                builder: (context, state) => const StudentMapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentProgress,
                name: 'student-progress',
                builder: (context, state) =>
                    const StudentProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.studentProfile,
                name: 'student-profile',
                builder: (context, state) =>
                    const StudentProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/student/quiz/:conceptId',
        name: 'student-quiz',
        builder: (context, state) {
          final conceptId = state.pathParameters['conceptId']!;
          return QuizScreen(conceptId: conceptId);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherClasses,
        name: 'teacher-classes',
        builder: (context, state) => const TeacherClassesScreen(),
      ),
      GoRoute(
        path: AppRoutes.gallery,
        name: 'gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
    ],
  );
});
