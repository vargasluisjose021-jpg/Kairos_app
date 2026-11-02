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

  // Animaciones del Muñeco Clínico
  late AnimationController _breathController; // Pulmones
  late AnimationController _heartController;  // Diafragma/Corazón
  late AnimationController _pelvicController; // Suelo Pélvico

  late Animation<double> _breathScale;
  late Animation<double> _heartScale;
  late Animation<double> _pelvicScale;

  @override
  void initState() {
    super.initState();
    
    // Inicializar animaciones
    _breathController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pelvicController = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _breathScale = Tween<double>(begin: 0.9, end: 1.15).animate(CurvedAnimation(parent: _breathController, curve: Curves.easeInOut));
    _heartScale = Tween<double>(begin: 0.95, end: 1.1).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeInOut));
    _pelvicScale = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pelvicController, curve: Curves.easeInOut));

    _breathController.repeat(reverse: true);
    _heartController.repeat(reverse: true);
    _pelvicController.repeat(reverse: true);

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
    
    if (_isStimulationPhase) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _breathController.dispose();
    _heartController.dispose();
    _pelvicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colores según nivel y fase
    Color baseColor = widget.user.userLevel == 1 ? const Color(0xFF4A90E2) : 
                      (widget.user.userLevel == 2 ? const Color(0xFFF5A623) : const Color(0xFFD0021B));
    Color phaseColor = _isStimulationPhase ? baseColor : const Color(0xFF8B0000);
        
    String phaseName = _isStimulationPhase ? "FASE ACTIVA: Sigue el ritmo" : "¡ALTO! Pausa y respira";
    String instruction = _isStimulationPhase 
        ? "Sincroniza tu respiración y movimiento con el muñeco." 
        : "Detén todo. Relaja el suelo pélvico. Inhala profundo.";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: Text('Nivel ${widget.user.userLevel}', style: const TextStyle(color: Colors.white)),
        actions: [IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => _finishSession())],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(phaseName, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: phaseColor)),
            const SizedBox(height: 10),
            Text('Tiempo en fase: $_phaseSeconds s', style: const TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: phaseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: phaseColor, width: 2)),
              child: Text(instruction, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 30),

            // MUÑECO ANATÓMICO CLÍNICO (Estilo Radiografía)
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Silueta del Torso (Translúcida)
                  Container(
                    width: 200,
                    height: 320,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(80), topRight: Radius.circular(80),
                        bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40),
                      ),
                      border: Border.all(color: phaseColor.withOpacity(0.3), width: 2),
                    ),
                  ),
                  // 2. Órganos Internos
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // Pulmones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildOrgan(_breathController, _breathScale, phaseColor, 60, 90, true),
                          const SizedBox(width: 10),
                          _buildOrgan(_breathController, _breathScale, phaseColor, 60, 90, false),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Diafragma / Corazón
                      _buildOrgan(_heartController, _heartScale, phaseColor, 140, 25, true, isCircle: true),
                      const SizedBox(height: 40),
                      // Zona Pélvica
                      _buildOrgan(_pelvicController, _pelvicScale, phaseColor, 100, 60, true, isPelvic: true),
                    ],
                  ),
                ],
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

  // Widget reutilizable para los órganos
  Widget _buildOrgan(AnimationController controller, Animation<double> scale, Color color, double width, double height, bool isActive, {bool isCircle = false, bool isPelvic = false}) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: scale.value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color.withOpacity(isActive ? 0.7 : 0.3),
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isPelvic ? BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)) : (isCircle ? null : BorderRadius.circular(20)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 15, spreadRadius: isActive ? 5 : 0)],
            ),
            child: isCircle ? Center(child: Icon(Icons.favorite, color: Colors.white, size: 20)) : null,
          ),
        );
      },
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
