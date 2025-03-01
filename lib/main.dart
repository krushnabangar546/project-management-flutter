import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/projects/projects_screen.dart';
import 'screens/projects/project_detail_screen.dart';
import 'screens/map/map_screen.dart';
import 'screens/charts/charts_screen.dart';
import 'models/project.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseStorage.instance.setMaxUploadRetryTime(const Duration(seconds: 30));
  FirebaseStorage.instance.setMaxDownloadRetryTime(const Duration(seconds: 30));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return snapshot.hasData ? const ProjectsScreen() : const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/projects': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Project) {
            return ProjectDetailScreen(project: args);
          }
          return const ProjectsScreen();
        },
        '/map': (context) => const MapScreen(),
        '/charts': (context) => const ChartsScreen(),
      },
    );
  }
}
