import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'user_model.dart';

class ResultScreen extends StatelessWidget {
  final Isar isar;
  final User user;
  final int sessionTimeSeconds;

  const ResultScreen({super.key, required this.isar, required this.user, required this.sessionTimeSeconds});

  Future<void> _updateProgress(bool wasSuccessful) async {
    user.totalSessions++;
    if (wasSuccessful) {
      user.successfulSessions++;
      // Si tuvo éxito, aumentamos el tiempo base un 10% para hacerlo más difícil
      user.baseTimeSeconds = (user.baseTimeSeconds * 1.1).toInt();
      
      // Subir de nivel según el tiempo base
      if (user.baseTimeSeconds > 180 && user.userLevel < 2) user.userLevel = 2;
      if (user.baseTimeSeconds > 300 && user.userLevel < 3) user.userLevel = 3;
    } else {
      // Si falló, reducimos un poco el tiempo para que no se frustre
      user.baseTimeSeconds = (user.baseTimeSeconds * 0.9).toInt();
      if (user.baseTimeSeconds < 30) user.baseTimeSeconds = 30;
    }
    
    user.updatedAt = DateTime.now();
    await isar.writeTxn(() => isar.users.put(user));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(backgroundColor: const Color(0xFF0F0F1A), title: const Text('Resumen de Sesión', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, size: 80, color: Color(0xFFE94560)),
            const SizedBox(height: 24),
            Text('Tiempo total: ${sessionTimeSeconds ~/ 60} min ${sessionTimeSeconds % 60} s', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Nivel actual: ${user.userLevel == 1 ? 'Principiante' : user.userLevel == 2 ? 'Intermedio' : 'Avanzado'}', style: const TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 40),
            const Text('¿Lograste controlar el final sin eyacular?', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _updateProgress(false).then((_) => Navigator.popUntil(context, (route) => route.isFirst));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700], padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                  child: const Text('No, fallé', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateProgress(true).then((_) => Navigator.popUntil(context, (route) => route.isFirst));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                  child: const Text('Sí, lo logré', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
