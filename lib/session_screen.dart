import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _sessionTimer;
  int _secondsRemaining = 30;
  int _currentPhaseIndex = 0;
  
  // Definición de las fases de entrenamiento (El "Guion" del Instructor)
  final List<Map<String, dynamic>> _phases = [
    {
      'name': 'Calentamiento',
      'instruction': 'Sincroniza tu respiración. Ritmo lento y constante.',
      'duration': Duration(seconds: 3), // Velocidad del pulso
      'time': 30, // Segundos en esta fase
      'color': Color(0xFF4A90E2), // Azul
    },
    {
      'name': 'Acumulación',
      'instruction': 'Aumenta la intensidad gradualmente. Sigue el ritmo.',
      'duration': Duration(milliseconds: 1500),
      'time': 45,
      'color': Color(0xFFF5A623), // Naranja
    },
    {
      'name': 'Zona de Borde',
      'instruction': 'Ritmo rápido. Mantén el control del suelo pélvico.',
      'duration': Duration(milliseconds: 800),
      'time': 20,
      'color': Color(0xFFD0021B), // Rojo
    },
    {
      'name': '¡ALTO! Recuperación',
      'instruction': 'Detén toda estimulación. Respira profundo y relaja.',
      'duration': Duration(seconds: 4), // Pulso muy lento de calma
      'time': 25,
      'color': Color(0xFF8B0000), // Rojo oscuro / Alerta
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: _phases[0]['duration'] as Duration,
    )..repeat(reverse: true);
    
    _startSession();
  }

  void _startSession() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _nextPhase();
      }
    });
    _updatePhaseUI();
  }

  void _nextPhase() {
    setState(() {
      _currentPhaseIndex = (_currentPhaseIndex + 1) % _phases.length;
      _secondsRemaining = _phases[_currentPhaseIndex]['time'] as int;
      
      // Actualizar la velocidad del pulso
      _pulseController.duration = _phases[_currentPhaseIndex]['duration'] as Duration;
      _pulseController.repeat(reverse: true);
      
      // Vibración para avisar el cambio de fase
      if (_currentPhaseIndex == 3) {
        HapticFeedback.heavyImpact(); // Alerta fuerte en la fase de ALTO
      } else {
        HapticFeedback.mediumImpact();
      }
      
      _updatePhaseUI();
    });
  }

  void _updatePhaseUI() {
    // Forzar un rebuild para actualizar colores y textos
    setState(() {});
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPhase = _phases[_currentPhaseIndex];
    final phaseColor = currentPhase['color'] as Color;
    final phaseName = currentPhase['name'] as String;
    final instruction = currentPhase['instruction'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Entrenamiento Guiado', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Temporizador y Fase Actual
            Text(
              phaseName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: phaseColor),
            ),
            const SizedBox(height: 10),
            Text(
              'Tiempo restante: $_secondsRemaining s',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 20),

            // Instrucción Principal del Instructor
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: phaseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: phaseColor, width: 2),
              ),
              child: Text(
                instruction,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),

            // Visualizador Anatómico (Sigue el ritmo de la app)
            Expanded(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  // El pulso es más intenso en las fases altas
                  double scale = 1.0 + (_pulseController.value * (_currentPhaseIndex == 3 ? 0.05 : 0.15));
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnatomicalZone('Diafragma', 'Respiración', phaseColor, _currentPhaseIndex >= 0),
                    const SizedBox(height: 15),
                    _buildAnatomicalZone('Core', 'Tensión Abdominal', phaseColor, _currentPhaseIndex >= 1),
                    const SizedBox(height: 15),
                    _buildAnatomicalZone('Suelo Pélvico', 'Contracción', phaseColor, _currentPhaseIndex >= 2),
                  ],
                ),
              ),
            ),

            // Botón de Pánico / Salir de la sesión
            ElevatedButton.icon(
              onPressed: () {
                _sessionTimer?.cancel();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.stop),
              label: const Text('Finalizar Sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnatomicalZone(String name, String function, Color zoneColor, bool isActive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isActive ? zoneColor.withOpacity(0.2) : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isActive ? zoneColor : Colors.grey[800]!,
          width: isActive ? 3 : 1,
        ),
        boxShadow: isActive 
          ? [BoxShadow(color: zoneColor.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)] 
          : [],
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isActive ? zoneColor : Colors.white54)),
          const SizedBox(height: 5),
          Text(function, style: const TextStyle(fontSize: 14, color: Colors.white54)),
        ],
      ),
    );
  }
}
