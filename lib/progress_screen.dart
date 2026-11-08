import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'user_model.dart';

class ProgressScreen extends StatefulWidget {
  final Isar isar;
  final User user;
  const ProgressScreen({super.key, required this.isar, required this.user});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final int streak = widget.user.streakDays ?? 0;
    final int totalSessions = widget.user.totalSessions;
    final int baselineMelt = widget.user.baselineMelt ?? 180;
    final int currentLevel = (widget.user.startStopLevel ?? 1).clamp(1, 10);
    final int edgingLevel = (widget.user.edgingLevel ?? 1).clamp(1, 10);
    
    final int currentStimulateTime = ((baselineMelt * 0.70) * (1 + (currentLevel - 1) * 0.10)).round();
    final int baseStimulateTime = (baselineMelt * 0.70).round();
    final int improvementPercent = (((currentStimulateTime - baseStimulateTime) / baseStimulateTime) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Mi Progreso Clínico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildStatCard(
              title: 'Adherencia al Tratamiento',
              icon: Icons.local_fire_department,
              iconColor: const Color(0xFFFF9F1C),
              children: [
                _buildStatRow('Racha Actual', '$streak días', streak > 0 ? const Color(0xFF00E676) : Colors.grey),
                const SizedBox(height: 15),
                _buildStatRow('Sesiones Totales', '$totalSessions', const Color(0xFF00B4D8)),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatCard(
              title: 'Evolución del Control',
              icon: Icons.show_chart,
              iconColor: const Color(0xFF00B4D8),
              children: [
                _buildStatRow('Tiempo Base (Día 1)', '$baseStimulateTime s', Colors.grey),
                const SizedBox(height: 15),
                _buildStatRow('Capacidad Actual', '$currentStimulateTime s', const Color(0xFF00E676)),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: Color(0xFF00E676), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          improvementPercent > 0 
                              ? 'Has aumentado tu tolerancia un $improvementPercent%' 
                              : 'Continúa con el protocolo para ver mejoras',
                          style: const TextStyle(color: Color(0xFF00E676), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatCard(
              title: 'Niveles de Carga Actuales',
              icon: Icons.fitness_center,
              iconColor: const Color(0xFFE94560),
              children: [
                _buildLevelRow('Módulo 2 (Start-Stop)', currentLevel, const Color(0xFFE94560)),
                const SizedBox(height: 15),
                _buildLevelRow('Módulo 3 (Edging)', edgingLevel, const Color(0xFF00E676)),
                const SizedBox(height: 15),
                _buildLevelRow('Módulo 4 (Control Total)', currentLevel, const Color(0xFFFF9F1C)),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nota clínica: La consistencia es más importante que la intensidad. Mantener una racha de 3-5 días genera cambios neuroplásticos reales en el reflejo eyaculatorio.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required IconData icon, required Color iconColor, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: iconColor)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.white70)),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildLevelRow(String label, int level, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15, color: Colors.white70)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            'Nivel $level / 10',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}
