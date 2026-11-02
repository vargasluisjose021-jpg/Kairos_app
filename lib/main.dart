import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'user_model.dart';
import 'onboarding_screen.dart';
import 'session_screen.dart'; // <--- Importamos la nueva pantalla

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dir = await getApplicationDocumentsDirectory();
  await Isar.initializeIsarCore(download: true);
  
  final isar = await Isar.open(
    [UserSchema],
    directory: dir.path,
  );
  
  runApp(KairosApp(isar: isar));
}

class KairosApp extends StatelessWidget {
  final Isar isar;
  
  const KairosApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF1A1A2E),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94560),
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(isar: isar),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Isar isar;
  
  const HomeScreen({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 80, color: Color(0xFFE94560)),
            const SizedBox(height: 24),
            const Text(
              'KAIROS',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Biofeedback & Control',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () async {
                final existingUser = await isar.users.where().findFirst();
                
                if (existingUser == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OnboardingScreen(isar: isar)),
                  );
                } else {
                  // Si ya hay perfil, ir directo a la sesión
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SessionScreen()),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar Entrenamiento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
