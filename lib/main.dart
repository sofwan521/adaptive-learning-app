import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/routes/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/irt_service.dart';
import 'core/services/knowledge_graph_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/learning/providers/learning_provider.dart';
import 'features/progress/providers/progress_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ChangeNotifierProvider(create: (_) => LearningProvider(
          IRTService(),
          KnowledgeGraphService(),
        )),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: MaterialApp.router(
        title: 'Adaptive Learning App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
