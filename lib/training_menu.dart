import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'user_model.dart';
import 'pelvic_screen.dart';
import 'ppg_calibration_screen.dart';

class TrainingMenu extends StatelessWidget {
  final Isar isar;
  final User user;
  const TrainingMenu({super.key, required this.isar, required this.user});

  bool _isCompletedToday(DateTime? lastSessionDate) {
    if (lastSessionDate == null) return false;
    final now = DateTime.now();
    return lastSessionDate.year == now.year &&
           lastSessionDate.month == now.month &&
           lastSessionDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final module1CompletedToday = _isCompletedToday(user.module1LastSessionDate);
    final module2CompletedToday = _isCompletedToday(user.module2LastSessionDate);
    final module3CompletedToday = _isCompletedToday(user.module3LastSessionDate);
    final module4CompletedToday = _isCompletedToday(user.module4LastSessionDate);

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
                  colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: const Color(0xFF00B4D8).withOpacity(0.4), blurRadius: 15, spreadRadius: 2)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TU PROGRESO', style: TextStyle(fontSize: 12, color: Colors.white70, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat('Edad', '${user.age} años'),
                      _buildStat('Racha', '${user.streakDays} días'),
                      _buildStat('Sesiones', '${user.successfulSessions}/${user.totalSessions}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Advertencia Clínica (si aplica)
            if (user.clinicalWarning.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user.clinicalWarning,
                        style: const TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],

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

            const Text('Tu Rutina Diaria', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 5),
            const Text('Completa 1 sesión de cada módulo hoy', style: TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 20),

            // MÓDULO 1: Suelo Pélvico
            _buildModuleCard(
              context,
              number: '01',
              title: 'Fundación: Suelo Pélvico',
              desc: 'Kegel y Kegel Inverso. Aísla el músculo PC.',
              prescription: '${user.kegelHoldTime}s contracción | ${user.kegelReps} reps',
              color: const Color(0xFF4A90E2),
              isCompletedToday: module1CompletedToday,
              sessionsCompleted: user.module1SessionsCompleted,
              onTap: () {
                if (module1CompletedToday) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ya completaste este módulo hoy. ¡Vuelve mañana!'),
                      backgroundColor: Color(0xFFFF9800),
                    ),
                  );
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PelvicScreen(isar: isar, user: user)));
                }
              },
            ),
            const SizedBox(height: 15),

            // MÓDULO 2: Start-Stop
            _buildModuleCard(
              context,
              number: '02',
              title: 'Conciencia: Start-Stop',
              desc: 'Detecta tu Punto de No Retorno (nivel 7).',
              prescription: user.allowEdging ? 'Habilitado' : '⚠️ Bloqueado por edad',
              color: const Color(0xFF9C27B0),
              isCompletedToday: module2CompletedToday,
              sessionsCompleted: user.module2SessionsCompleted,
              onTap: () {
                if (module2CompletedToday) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ya completaste este módulo hoy. ¡Vuelve mañana!'),
                      backgroundColor: Color(0xFFFF9800),
                    ),
                  );
                } else if (!user.allowEdging) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Este módulo está bloqueado por razones clínicas. Consulta tu plan de entrenamiento.'),
                      backgroundColor: Color(0xFFFF9800),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Módulo 2 en construcción. Próximamente.'),
                      backgroundColor: Color(0xFF00B4D8),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 15),

            // MÓDULO 3: Edging
            _buildModuleCard(
              context,
              number: '03',
              title: 'Resistencia: Edging',
              desc: 'Domina la meseta de alta excitación.',
              prescription: user.allowEdging ? 'Habilitado' : '⚠️ Bloqueado por edad',
              color: const Color(0xFFFF5722),
              isCompletedToday: module3CompletedToday,
              sessionsCompleted: user.module3SessionsCompleted,
              onTap: () {
                if (module3CompletedToday) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ya completaste este módulo hoy. ¡Vuelve mañana!'),
                      backgroundColor: Color(0xFFFF9800),
                    ),
                  );
                } else if (!user.allowEdging) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Este módulo está bloqueado por razones clínicas. Consulta tu plan de entrenamiento.'),
                      backgroundColor: Color(0xFFFF9800),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Módulo 3 en construcción. Próximamente.'),
                      backgroundColor: Color(0xFF00B4D8),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 15),

            // MÓDULO 4: Control Total
            _buildModuleCard(
              context,
              number: '04',
              title: 'Control Total: Squeeze & Breath',
              desc: 'Hackea el reflejo eyaculatorio.',
              prescription: user.allowEdging ? 'Habilitado' : '⚠️ Bloqueado por edad',
              color: const Color(0xFFE91E63),
              isCompletedToday: module4CompletedToday,
              sessionsCompleted: user.module4SessionsCompleted,
              onTap: () {
                if (module4CompletedToday) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ya completaste este módulo hoy. ¡Vuelve mañana!'),
                      backgroundColor: Color(0xFFFF9800),
                    ),
                  );
                } else if (!user.allowEdging) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Este módulo está bloqueado por razones clínicas. Consulta tu plan de entrenamiento.'),
                      backgroundColor: Color(0xFFFF9800),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Módulo 4 en construcción. Próximamente.'),
                      backgroundColor: Color(0xFF00B4D8),
                    ),
                  );
                }
              },
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
    required String prescription,
    required Color color,
    required bool isCompletedToday,
    required int sessionsCompleted,
    required VoidCallback onTap,
  }) {
    final int target = 7;
    final double progress = sessionsCompleted / target;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCompletedToday ? Colors.green.withOpacity(0.1) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isCompletedToday ? Colors.green : color, width: 2),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Text(number, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
                if (isCompletedToday)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text(desc, style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      prescription,
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[800],
                    color: color,
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompletedToday ? '✓ Completado hoy' : 'Progreso: $sessionsCompleted/$target sesiones',
                    style: TextStyle(fontSize: 11, color: isCompletedToday ? Colors.green : color),
                  ),
                ],
              ),
            ),
            Icon(isCompletedToday ? Icons.check_circle : Icons.arrow_forward_ios, 
                 color: isCompletedToday ? Colors.green : color),
          ],
        ),
      ),
    );
  }
}
