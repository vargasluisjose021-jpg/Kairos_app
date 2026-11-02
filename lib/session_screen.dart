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
  Timer? _sessionTimer;
  int _totalSeconds = 0;
  int _phaseSeconds = 0;
  bool _isStimulationPhase = true; // true = estimulando, false = pausando

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseScale = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
    
    _startAdaptiveSession();
  }

  void _startAdaptiveSession() {
    // Lógica Adaptativa: Tiempos según el nivel del usuario
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
    
    // Vibración para avisar el cambio
    if (_isStimulationPhase) {
      HapticFeedback.mediumImpact(); // Vuelve a empezar
    } else {
      HapticFeedback.heavyImpact(); // ¡ALTO! Pausa
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color phaseColor = _isStimulationPhase 
        ? (widget.user.userLevel == 1 ? const Color(0xFF4A90E2) : (widget.user.userLevel == 2 ? const Color(0xFFF5A623) : const Color(0xFFD0021B))) 
        : const Color(0xFF8B0000);
        
    String phaseName = _isStimulationPhase ? "FASE ACTIVA: Sigue el ritmo" : "¡ALTO! Pausa y respira";
    String instruction = _isStimulationPhase 
        ? "Sincroniza tu respiración con el muñeco." 
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
            // CORREGIDO: textAlign está fuera del TextStyle
            Text(phaseName, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: phaseColor)),
            const SizedBox(height: 10),
            Text('Tiempo en fase: $_phaseSeconds s', style: const TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: phaseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: phaseColor, width: 2)),
              child: Text(instruction, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isStimulationPhase ? _pulseScale.value : 1.0,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: phaseColor.withOpacity(0.6), boxShadow: [BoxShadow(color: phaseColor, blurRadius: 30, spreadRadius: 10)]),
                      child: Center(child: Icon(_isStimulationPhase ? Icons.favorite : Icons.pause, color: Colors.white, size: 80)),
                    ),
                  );
                },
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

  void _finishSession() {
    _sessionTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ResultScreen(isar: widget.isar, user: widget.user, sessionTimeSeconds: _totalSeconds)),
    );
  }
}
