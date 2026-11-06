import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'user_model.dart';
import 'pelvic_screen.dart';
import 'start_stop_screen.dart';
import 'edging_screen.dart';

class TrainingMenu extends StatelessWidget {
  final Isar isar;
  final User user;
  
  const TrainingMenu({super.key, required this.isar, required this.user});

  @override
  Widget build(BuildContext context) {
    final bool isUnderage = (user.age ?? 25) < 18;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Plan de Entrenamiento', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona tu módulo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text('Completa cada módulo en orden para mejores resultados', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: [
                  _buildModuleCard(context, moduleNumber: 1, title: 'Suelo Pélvico', subtitle: 'Fortalecimiento muscular básico', icon: Icons.fitness_center, color: const Color(0xFF00B4D8), isLocked: false, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PelvicScreen(isar: isar, user: user)))),
                  const SizedBox(height: 15),
                  _buildModuleCard(context, moduleNumber: 2, title: 'Start-Stop', subtitle: 'Control del reflejo eyaculatorio', icon: Icons.pause, color: const Color(0xFFE94560), isLocked: isUnderage, onTap: isUnderage ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => StartStopScreen(isar: isar, user: user)))),
                  const SizedBox(height: 15),
                  _buildModuleCard(context, moduleNumber: 3, title: 'Edging', subtitle: 'Resistencia en la meseta', icon: Icons.show_chart, color: const Color(0xFF00E676), isLocked: isUnderage, onTap: isUnderage ? null : () => Navigator.push(context, MaterialPageRoute(builder: (context) => EdgingScreen(isar: isar, user: user)))),
                  const SizedBox(height: 15),
                  _buildModuleCard(context, moduleNumber: 4, title: 'Control Total', subtitle: 'Técnica Squeeze & Breath', icon: Icons.lock, color: Colors.grey, isLocked: true, onTap: null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, {required int moduleNumber, required String title, required String subtitle, required IconData icon, required Color color, required bool isLocked, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isLocked ? Colors.grey[900] : color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: isLocked ? Colors.grey[700]! : color.withOpacity(0.3), width: 2)),
        child: Row(
          children: [
            Container(width: 60, height: 60, decoration: BoxDecoration(color: isLocked ? Colors.grey[800] : color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 32, color: isLocked ? Colors.grey[600] : color)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Módulo $moduleNumber', style: TextStyle(fontSize: 12, color: isLocked ? Colors.grey[600] : color, fontWeight: FontWeight.bold)),
                      if (isLocked && moduleNumber < 4) ...[const SizedBox(width: 8), Icon(Icons.lock, size: 12, color: Colors.grey[600])],
                      if (moduleNumber == 4) ...[const SizedBox(width: 8), Text('PRÓXIMAMENTE', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold))],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isLocked ? Colors.grey[500] : Colors.white)),
                  const SizedBox(height: 5),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isLocked ? Colors.grey[600] : Colors.white.withOpacity(0.7))),
                ],
              ),
            ),
            Icon(isLocked ? Icons.lock : Icons.arrow_forward_ios, color: isLocked ? Colors.grey[700] : color, size: 24),
          ],
        ),
      ),
    );
  }
}
