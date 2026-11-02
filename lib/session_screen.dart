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

  // Controladores de Animación
  late AnimationController _breathController;
  late AnimationController _paceController;
  late AnimationController _muscleController;

  late Animation<double> _breathScale;
  late Animation<double> _pacePosition;
  late Animation<double> _muscleScale;

  @override
  void initState() {
    super.initState();
    
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
        
    String phaseName = _isStimulationPhase ? "FASE ACTIVA" : "¡ALTO! PAUSA";
    String instruction = _isStimulationPhase 
        ? "Sincroniza respiración, mano y músculo" 
        : "Detén todo. Relaja. Respira.";

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
            Text(phaseName, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: phaseColor)),
            const SizedBox(height: 5),
            Text('Tiempo: $_phaseSeconds s', style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: phaseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: phaseColor, width: 1)),
              child: Text(instruction, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white)),
            ),
            const SizedBox(height: 15),

            // MUÑECO ANATÓMICO TRANSLÚCIDO CON ÓRGANOS
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Silueta del cuerpo (translúcida)
                  _buildBodySilhouette(phaseColor),
                  // Órganos internos animados
                  _buildInternalOrgans(phaseColor),
                  // Guía de ritmo de la mano (SUBE/BAJA) al lado derecho
                  Positioned(
                    right: 10,
                    top: 100,
                    child: _buildHandPaceGuide(phaseColor),
                  ),
                  // Etiquetas de las zonas
                  Positioned(
                    left: 10,
                    top: 80,
                    child: _buildZoneLabel('Respiración', phaseColor),
                  ),
                  Positioned(
                    left: 10,
                    top: 200,
                    child: _buildZoneLabel('Corazón', phaseColor),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 100,
                    child: _buildZoneLabel('Suelo Pélvico', phaseColor),
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

  // Silueta del cuerpo humano translúcido
  Widget _buildBodySilhouette(Color color) {
    return Container(
      width: 200,
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(80),
          topRight: Radius.circular(80),
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // Cabeza
          Container(
            width: 70,
            height: 70,
            margin: EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.4), width: 2),
            ),
          ),
          Spacer(),
          // Piernas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(width: 50, height: 90, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(25))),
              Container(width: 50, height: 90, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(25))),
            ],
          ),
        ],
      ),
    );
  }

  // Órganos internos animados
  Widget _buildInternalOrgans(Color color) {
    return Container(
      width: 200,
      height: 380,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulmones (parte superior)
          Positioned(
            top: 100,
            child: AnimatedBuilder(
              animation: _breathController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathScale.value,
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 70,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.6),
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(35), bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                          boxShadow: [BoxShadow(color: color.withOpacity(0.7), blurRadius: 10)],
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        width: 45,
                        height: 70,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.6),
                          borderRadius: BorderRadius.only(topRight: Radius.circular(35), bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                          boxShadow: [BoxShadow(color: color.withOpacity(0.7), blurRadius: 10)],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Corazón/Diafragma (centro)
          Positioned(
            top: 170,
            child: AnimatedBuilder(
              animation: _muscleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _muscleScale.value,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.8),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.9), blurRadius: 15)],
                    ),
                    child: Center(child: Icon(Icons.favorite, color: Colors.white, size: 20)),
                  ),
                );
              },
            ),
          ),
          // Zona Pélvica (parte inferior)
          Positioned(
            bottom: 80,
            child: AnimatedBuilder(
              animation: _muscleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _muscleScale.value,
                  child: Container(
                    width: 90,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.7),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(45), bottomRight: Radius.circular(45)),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.8), blurRadius: 15)],
                    ),
                    child: Center(child: Icon(Icons.blur_on, color: Colors.white, size: 25)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Guía de ritmo de la mano (SUBE/BAJA)
  Widget _buildHandPaceGuide(Color color) {
    return Column(
      children: [
        Text('SUBE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        SizedBox(height: 5),
        Container(
          width: 4,
          height: 100,
          decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _paceController,
                builder: (context, child) {
                  double topPos = 100 * (1 - _pacePosition.value) - 15;
                  return Positioned(
                    top: topPos.clamp(0.0, 85.0),
                    left: -13,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [BoxShadow(color: color.withOpacity(0.8), blurRadius: 10)],
                      ),
                      child: Center(
                        child: Icon(
                          _pacePosition.value > 0.5 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 5),
        Text('BAJA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // Etiquetas de zonas
  Widget _buildZoneLabel(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
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
