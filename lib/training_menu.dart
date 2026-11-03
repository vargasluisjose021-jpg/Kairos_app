import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'user_model.dart';
import 'pelvic_screen.dart';
import 'ppg_calibration_screen.dart';

class TrainingMenu extends StatelessWidget {
  final Isar isar;
  final User user;
  const TrainingMenu({super.key, required this.isar, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Dashboard Clínico', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Estado del Usuario
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE94560), Color(0xFF8B0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: const Color(0xFFE94560).withOpacity(0.4), blurRadius: 15, spreadRadius: 2)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TU PROGRESO', style: TextStyle(fontSize: 12, color: Colors.white70, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat('Nivel M1', 'Nivel ${user.module1CurrentLevel}'),
                      _buildStat('Racha', '${user.streakDays} días'),
                      _buildStat('Sesiones', '${user.successfulSessions}/${user.totalSessions}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta de Telemetría
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monitor_heart, color: Color(0xFF00E676), size: 30),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Última Sesión Validada', style: TextStyle(fontSize: 14, color: Colors.white70)),
                        const SizedBox(height: 5),
                        Text(
                          'FC Pico: ${user.lastSessionHeartRatePeak} BPM | Movimiento: ${user.lastSessionMovementDetected ? "Sí ✓" : "No ✗"}',
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BOTÓN DE CALIBRACIÓN DE PULSO
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: const Color(0xFF00E676).withOpacity(0.4), blurRadius: 10, spreadRadius: 2)],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PPGCalibrationScreen(isar: isar, user: user)));
                },
                icon: const Icon(Icons.fingerprint, size: 30),
                label: const Text(
                  'CALIBRAR PULSO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Text('Tu Ruta al Control Total', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 5),
            const Text('Completa 7 sesiones por módulo para avanzar', style: TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 20),

            // MÓDULO 1: Suelo Pélvico
            _buildModuleCard(
              context,
              number: '01',
              title: 'Fundación: Suelo Pélvico',
              desc: 'Kegel y Kegel Inverso. Aísla el músculo PC.',
              color: const Color(0xFF4A90E2),
              isLocked: !user.isModuleUnlocked(1),
              sessionsCompleted: user.module1SessionsCompleted,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PelvicScreen(isar: isar, user: user)));
              },
            ),
            const SizedBox(height: 15),

            // MÓDULO 2: Start-Stop
            _buildModuleCard(
              context,
              number: '02',
              title: 'Conciencia: Start-Stop',
              desc: 'Detecta tu Punto de No Retorno (nivel 7).',
              color: Colors.grey[700]!,
              isLocked: !user.isModuleUnlocked(2),
              sessionsCompleted: user.module2SessionsCompleted,
              onTap: () {},
            ),
            const SizedBox(height: 15),

            // MÓDULO 3: Edging
            _buildModuleCard(
              context,
              number: '03',
              title: 'Resistencia: Edging',
              desc: 'Domina la meseta de alta excitación.',
              color: Colors.grey[700]!,
              isLocked: !user.isModuleUnlocked(3),
              sessionsCompleted: user.module3SessionsCompleted,
              onTap: () {},
            ),
            const SizedBox(height: 15),

            // MÓDULO 4: Control Total
            _buildModuleCard(
              context,
              number: '04',
              title: 'Control Total: Squeeze & Breath',
              desc: 'Hackea el reflejo eyaculatorio.',
              color: Colors.grey[700]!,
              isLocked: !user.isModuleUnlocked(4),
              sessionsCompleted: user.module4SessionsCompleted,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModuleCard(BuildContext context, {
    required String number,
    required String title,
    required String desc,
    required Color color,
    required bool isLocked,
    required int sessionsCompleted,
    required VoidCallback onTap,
  }) {
    final int target = 7;
    final double progress = sessionsCompleted / target;
    
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey[900] : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isLocked ? Colors.grey[800]! : color, width: 2),
        ),
        child: Row(
          children: [
            Text(number, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isLocked ? Colors.grey[700] : color)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isLocked ? Colors.grey[600] : Colors.white)),
                  const SizedBox(height: 5),
                  Text(desc, style: TextStyle(fontSize: 13, color: isLocked ? Colors.grey[700] : Colors.white70)),
                  if (!isLocked) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[800],
                      color: color,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text('Progreso: $sessionsCompleted/$target sesiones', style: TextStyle(fontSize: 11, color: color)),
                  ]
                ],
              ),
            ),
            Icon(isLocked ? Icons.lock : Icons.arrow_forward_ios, color: isLocked ? Colors.grey[800] : color),
          ],
        ),
      ),
    );
  }
}
