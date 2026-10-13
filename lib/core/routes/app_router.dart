import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/placement_test/screens/placement_test_screen.dart';
import '../../features/placement_test/screens/placement_result_screen.dart';
import '../../features/learning/screens/concept_map_screen.dart';
import '../../features/learning/screens/quiz_screen.dart';
import '../../features/learning/screens/learning_material_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/placement-test',
        name: 'placement-test',
        builder: (context, state) => const PlacementTestScreen(),
      ),
      GoRoute(
        path: '/placement-result',
        name: 'placement-result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PlacementResultScreen(
            theta: extra?['theta'] ?? 0.0,
            level: extra?['level'] ?? 'Menengah',
          );
        },
      ),
      GoRoute(
        path: '/concept-map',
        name: 'concept-map',
        builder: (context, state) => const ConceptMapScreen(),
      ),
      GoRoute(
        path: '/quiz/:conceptId',
        name: 'quiz',
        builder: (context, state) {
          final conceptId = state.pathParameters['conceptId']!;
          return QuizScreen(conceptId: conceptId);
        },
      ),
      GoRoute(
        path: '/learning-material/:conceptId',
        name: 'learning-material',
        builder: (context, state) {
          final conceptId = state.pathParameters['conceptId']!;
          return LearningMaterialScreen(conceptId: conceptId);
        },
      ),
      GoRoute(
        path: '/progress',
        name: 'progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
