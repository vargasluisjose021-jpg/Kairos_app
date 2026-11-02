import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'dart:async';
import 'user_model.dart';
import 'result_screen.dart';

class SessionScreen extends StatefulWidget {
  final Isar isar;
  final User user;
  const SessionScreen({super.key, required this.isar, required this.user});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with TickerProviderStateMixin {
  // Lógica Adaptativa
  Timer? _sessionTimer;
  int _totalSeconds = 0;
  int _phaseSeconds = 0;
  bool _isStimulationPhase = true;

  // Controladores de Animación para cada sistema fisiológico
  late AnimationController _breathController; // Respiración
  late AnimationController _paceController;   // Ritmo de Movimiento (Mano: subir/bajar)
  late AnimationController _muscleController; // Tensión Muscular

  late Animation<double> _breathScale;
  late Animation<double> _pacePosition; // Posición vertical del indicador (0 = abajo, 1 = arriba)
  late Animation<double> _muscleScale;

  @override
  void initState() {
    super.initState();
    
    // Inicializar animaciones con velocidades base
    _breathController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _paceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _muscleController = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _breathScale = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _breathController, curve: Curves.easeInOut));
    _pacePosition = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _paceController, curve: Curves.easeInOut));
    _muscleScale = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _muscleController, curve: Curves.easeInOut));

    _breathController.repeat(reverse: true);
    _paceController.repeat(reverse: true);
    _muscleController.repeat(reverse: true);

    _startAdaptiveSession();
  }

  void _startAdaptiveSession() {
    int stimTime = widget.user.baseTimeSeconds; 
    int pauseTime = widget.user.userLevel == 1 ? 60 : (widget.user.userLevel == 2 ? 60 : 30);
    
    _phaseSeconds = stimTime;
    _isStimulationPhase = true;

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _totalSeconds++;
      _phaseSeconds--;

      if (_phaseSeconds <= 0) {
        _switchPhase(stimTime, pauseTime);
      }
      setState(() {});
    });
  }

  void _switchPhase(int stimTime, int pauseTime) {
    _isStimulationPhase = !_isStimulationPhase;
    _phaseSeconds = _isStimulationPhase ? stimTime : pauseTime;
    
    // Ajustar velocidades según la fase y nivel
    if (_isStimulationPhase) {
      int paceDuration = widget.user.userLevel == 1 ? 2500 : (widget.user.userLevel == 2 ? 1500 : 900);
      _paceController.duration = Duration(milliseconds: paceDuration);
      _paceController.repeat(reverse: true);
      HapticFeedback.mediumImpact();
    } else {
      _paceController.stop();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _breathController.dispose();
    _paceController.dispose();
    _muscleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor = widget.user.userLevel == 1 ? const Color(0xFF4A90E2) : 
                      (widget.user.userLevel == 2 ? const Color(0xFFF5A623) : const Color(0xFFD0021B));
    Color phaseColor = _isStimulationPhase ? baseColor : const Color(0xFF8B0000);
        
    String phaseName = _isStimulationPhase ? "FASE ACTIVA" : "¡ALTO! PAUSA OBLIGATORIA";
    String mainInstruction = _isStimulationPhase 
        ? "Sincroniza los 3 ritmos. No pierdas el control." 
        : "Detén todo movimiento. Relaja el músculo. Respira profundo.";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: Text('Nivel ${widget.user.userLevel}', style: const TextStyle(color: Colors.white)),
        actions: [IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => _finishSession())],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            // Cabecera de Fase
            Text(phaseName, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: phaseColor)),
            const SizedBox(height: 5),
            Text('Tiempo: $_phaseSeconds s', style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: phaseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: phaseColor, width: 1)),
              child: Text(mainInstruction, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white)),
            ),
            const SizedBox(height: 15),

            // PANEL DE CONTROL FISIOLÓGICO (3 Guías Separadas)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 1. GUÍA DE RESPIRACIÓN (Pulmones)
                    _buildPhysiologicalGuide(
                      title: "1. RESPIRACIÓN",
                      subtitle: _isStimulationPhase ? "Inhala... Exhala" : "Solo exhala lento",
                      icon: Icons.air,
                      color: phaseColor,
                      child: AnimatedBuilder(
                        animation: _breathController,
                        builder: (context, child) {
                          return Transform.scale(scale: _breathScale.value, child: child);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLungShape(phaseColor, true),
                            const SizedBox(width: 10),
                            _buildLungShape(phaseColor, false),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 2. GUÍA DE RITMO DE MOVIMIENTO (Mano: SUBE / BAJA)
                    _buildPhysiologicalGuide(
                      title: "2. RITMO DE LA MANO",
                      subtitle: _isStimulationPhase ? "Sigue el indicador" : "MANO DETENIDA",
                      icon: Icons.pan_tool,
                      color: phaseColor,
                      child: _buildHandPaceGuide(phaseColor),
                    ),
                    const SizedBox(height: 15),

                    // 3. GUÍA DE TENSIÓN MUSCULAR (Suelo Pélvico)
                    _buildPhysiologicalGuide(
                      title: "3. TENSIÓN MUSCULAR",
                      subtitle: _isStimulationPhase ? "Contrae suavemente" : "RELAX TOTAL",
                      icon: Icons.bolt,
                      color: phaseColor,
                      child: AnimatedBuilder(
                        animation: _muscleController,
                        builder: (context, child) {
                          return Transform.scale(scale: _muscleScale.value, child: child);
                        },
                        child: Container(
                          width: 120,
                          height: 60,
                          decoration: BoxDecoration(
                            color: phaseColor.withOpacity(0.6),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(60), bottomRight: Radius.circular(60)),
                            boxShadow: [BoxShadow(color: phaseColor.withOpacity(0.8), blurRadius: 15, spreadRadius: 5)],
                          ),
                          child: const Center(child: Icon(Icons.blur_on, color: Colors.white, size: 30)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: _finishSession,
              icon: const Icon(Icons.stop),
              label: const Text('Finalizar Sesión'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Contenedor para cada Guía
  Widget _buildPhysiologicalGuide({required String title, required String subtitle, required IconData icon, required Color color, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)),
              const Spacer(),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(height: 140, child: Center(child: child)),
        ],
      ),
    );
  }

  // Forma del Pulmón
  Widget _buildLungShape(Color color, bool isLeft) {
    return Container(
      width: 50,
      height: 70,
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLeft ? 40 : 10),
          topRight: Radius.circular(isLeft ? 10 : 40),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
        ),
        boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)],
      ),
    );
  }

  // Guía de Ritmo de la Mano (Carril vertical con indicador SUBE/BAJA)
  Widget _buildHandPaceGuide(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Texto lateral: SUBE / BAJA
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SUBE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color.withOpacity(0.7))),
            Text('BAJA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color.withOpacity(0.7))),
          ],
        ),
        const SizedBox(width: 15),
        // Carril vertical
        Container(
          width: 6,
          height: 120,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              // Indicador que se mueve de arriba hacia abajo
              AnimatedBuilder(
                animation: _paceController,
                builder: (context, child) {
                  // _pacePosition va de 0 (abajo) a 1 (arriba)
                  // Invertimos para que 0 sea abajo y 1 sea arriba visualmente
                  double topPosition = 120 * (1 - _pacePosition.value) - 20;
                  return Positioned(
                    top: topPosition.clamp(0.0, 100.0),
                    left: -17,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [BoxShadow(color: color.withOpacity(0.8), blurRadius: 15, spreadRadius: 3)],
                      ),
                      child: Center(
                        child: Icon(
                          _pacePosition.value > 0.5 ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        // Texto de dirección
        AnimatedBuilder(
          animation: _paceController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _pacePosition.value > 0.5 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                  size: 30,
                ),
                const SizedBox(height: 5),
                Text(
                  _pacePosition.value > 0.5 ? '↑ SUBE' : '↓ BAJA',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _finishSession() {
    _sessionTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ResultScreen(isar: widget.isar, user: widget.user, sessionTimeSeconds: _totalSeconds)),
    );
  }
}
