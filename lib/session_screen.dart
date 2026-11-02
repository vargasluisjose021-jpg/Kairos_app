import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with TickerProviderStateMixin {
  Timer? _sessionTimer;
  int _secondsRemaining = 20;
  int _currentPhaseIndex = 0;
  bool _isAlertBlinking = false;

  // Controladores de animación para cada órgano
  late AnimationController _lungsController;
  late AnimationController _heartController;
  late AnimationController _diaphragmController;
  late AnimationController _pelvicController;
  late AnimationController _bodyGlowController;

  late Animation<double> _lungsScale;
  late Animation<double> _heartScale;
  late Animation<double> _diaphragmScale;
  late Animation<double> _pelvicScale;
  late Animation<double> _bodyGlow;

  final List<Map<String, dynamic>> _phases = [
    {
      'name': 'Fase 1: Calma',
      'instruction': 'Respira profundo. Los pulmones se expanden lentamente.',
      'lungsDuration': Duration(seconds: 4),
      'heartDuration': Duration(milliseconds: 1000),
      'diaphragmDuration': Duration(seconds: 3),
      'pelvicDuration': Duration(seconds: 5),
      'time': 20,
      'color': Color(0xFF4A90E2),
      'activeOrgan': 'lungs',
    },
    {
      'name': 'Fase 2: Activación',
      'instruction': 'El corazón acelera. Siente la tensión en el diafragma.',
      'lungsDuration': Duration(milliseconds: 2000),
      'heartDuration': Duration(milliseconds: 700),
      'diaphragmDuration': Duration(milliseconds: 1500),
      'pelvicDuration': Duration(seconds: 3),
      'time': 20,
      'color': Color(0xFFF5A623),
      'activeOrgan': 'heart',
    },
    {
      'name': 'Fase 3: Borde',
      'instruction': '¡Alta intensidad! Contrae el suelo pélvico.',
      'lungsDuration': Duration(milliseconds: 1000),
      'heartDuration': Duration(milliseconds: 400),
      'diaphragmDuration': Duration(milliseconds: 800),
      'pelvicDuration': Duration(milliseconds: 600),
      'time': 15,
      'color': Color(0xFFD0021B),
      'activeOrgan': 'pelvic',
    },
    {
      'name': 'Fase 4: ¡ALTO!',
      'instruction': 'DETÉN TODO. Relaja todos los músculos. Respira.',
      'lungsDuration': Duration(seconds: 5),
      'heartDuration': Duration(milliseconds: 1200),
      'diaphragmDuration': Duration(seconds: 4),
      'pelvicDuration': Duration(seconds: 6),
      'time': 20,
      'color': Color(0xFF8B0000),
      'activeOrgan': 'alert',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _startSession();
  }

  void _initControllers() {
    _lungsController = AnimationController(vsync: this, duration: _phases[0]['lungsDuration'] as Duration);
    _heartController = AnimationController(vsync: this, duration: _phases[0]['heartDuration'] as Duration);
    _diaphragmController = AnimationController(vsync: this, duration: _phases[0]['diaphragmDuration'] as Duration);
    _pelvicController = AnimationController(vsync: this, duration: _phases[0]['pelvicDuration'] as Duration);
    _bodyGlowController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));

    _lungsScale = Tween<double>(begin: 0.9, end: 1.15).animate(CurvedAnimation(parent: _lungsController, curve: Curves.easeInOut));
    _heartScale = Tween<double>(begin: 0.95, end: 1.1).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeInOut));
    _diaphragmScale = Tween<double>(begin: 0.95, end: 1.08).animate(CurvedAnimation(parent: _diaphragmController, curve: Curves.easeInOut));
    _pelvicScale = Tween<double>(begin: 0.9, end: 1.12).animate(CurvedAnimation(parent: _pelvicController, curve: Curves.easeInOut));
    _bodyGlow = Tween<double>(begin: 0.3, end: 0.8).animate(CurvedAnimation(parent: _bodyGlowController, curve: Curves.easeInOut));

    _lungsController.repeat(reverse: true);
    _heartController.repeat(reverse: true);
    _diaphragmController.repeat(reverse: true);
    _pelvicController.repeat(reverse: true);
    _bodyGlowController.repeat(reverse: true);
  }

  void _startSession() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    setState(() {
      _currentPhaseIndex = (_currentPhaseIndex + 1) % _phases.length;
      _secondsRemaining = _phases[_currentPhaseIndex]['time'] as int;
      _isAlertBlinking = _currentPhaseIndex == 3;

      // Actualizar velocidades de cada órgano
      _lungsController.duration = _phases[_currentPhaseIndex]['lungsDuration'] as Duration;
      _heartController.duration = _phases[_currentPhaseIndex]['heartDuration'] as Duration;
      _diaphragmController.duration = _phases[_currentPhaseIndex]['diaphragmDuration'] as Duration;
      _pelvicController.duration = _phases[_currentPhaseIndex]['pelvicDuration'] as Duration;

      _lungsController.repeat(reverse: true);
      _heartController.repeat(reverse: true);
      _diaphragmController.repeat(reverse: true);
      _pelvicController.repeat(reverse: true);

      // Vibración háptica
      if (_currentPhaseIndex == 3) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _lungsController.dispose();
    _heartController.dispose();
    _diaphragmController.dispose();
    _pelvicController.dispose();
    _bodyGlowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPhase = _phases[_currentPhaseIndex];
    final phaseColor = currentPhase['color'] as Color;
    final phaseName = currentPhase['name'] as String;
    final instruction = currentPhase['instruction'] as String;
    final activeOrgan = currentPhase['activeOrgan'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Anatomía en Tiempo Real', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            Text(phaseName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: phaseColor, textAlign: TextAlign.center)),
            const SizedBox(height: 8),
            Text('Tiempo: $_secondsRemaining s', style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: phaseColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: phaseColor, width: 2)),
              child: Text(instruction, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
            const SizedBox(height: 20),

            // MUÑECO ANATÓMICO TRANSLÚCIDO
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Silueta del cuerpo (translúcida)
                  _buildBodySilhouette(phaseColor),
                  // Órganos internos
                  _buildOrgans(phaseColor, activeOrgan),
                  // Indicador de ALERTA (fase 4)
                  if (_isAlertBlinking) _buildAlertOverlay(phaseColor),
                ],
              ),
            ),

            // Leyenda de órganos activos
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOrganLegend('Pulmones', activeOrgan == 'lungs', phaseColor),
                  _buildOrganLegend('Corazón', activeOrgan == 'heart', phaseColor),
                  _buildOrganLegend('Pélvico', activeOrgan == 'pelvic', phaseColor),
                ],
              ),
            ),
            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: () { _sessionTimer?.cancel(); Navigator.pop(context); },
              icon: const Icon(Icons.stop),
              label: const Text('Finalizar Sesión'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // Silueta del cuerpo humano (translúcida)
  Widget _buildBodySilhouette(Color phaseColor) {
    return AnimatedBuilder(
      animation: _bodyGlowController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.15 + (_bodyGlow.value * 0.1),
          child: Container(
            width: 220,
            height: 380,
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(0.3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(80),
                topRight: Radius.circular(80),
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              border: Border.all(color: phaseColor.withOpacity(0.6), width: 2),
            ),
            child: Column(
              children: [
                // Cabeza
                Container(
                  width: 80,
                  height: 80,
                  margin: EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: phaseColor.withOpacity(0.4),
                    border: Border.all(color: phaseColor.withOpacity(0.7), width: 2),
                  ),
                ),
                Spacer(),
                // Piernas (indicador visual)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(width: 60, height: 100, decoration: BoxDecoration(color: phaseColor.withOpacity(0.3), borderRadius: BorderRadius.circular(30))),
                    Container(width: 60, height: 100, decoration: BoxDecoration(color: phaseColor.withOpacity(0.3), borderRadius: BorderRadius.circular(30))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Órganos internos
  Widget _buildOrgans(Color phaseColor, String activeOrgan) {
    return Container(
      width: 220,
      height: 380,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulmones (parte superior del torso)
          Positioned(
            top: 110,
            child: Row(
              children: [
                _buildOrgan('leftLung', phaseColor, activeOrgan == 'lungs'),
                SizedBox(width: 10),
                _buildOrgan('rightLung', phaseColor, activeOrgan == 'lungs'),
              ],
            ),
          ),
          // Corazón (centro)
          Positioned(
            top: 140,
            child: _buildHeart(phaseColor, activeOrgan == 'heart'),
          ),
          // Diafragma (línea bajo pulmones)
          Positioned(
            top: 190,
            child: _buildDiaphragm(phaseColor, activeOrgan == 'lungs'),
          ),
          // Zona Pélvica (parte inferior)
          Positioned(
            bottom: 100,
            child: _buildPelvicZone(phaseColor, activeOrgan == 'pelvic'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgan(String side, Color phaseColor, bool isActive) {
    return AnimatedBuilder(
      animation: _lungsController,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _lungsScale.value : 1.0,
          child: Container(
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(isActive ? 0.7 : 0.4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(side == 'leftLung' ? 40 : 20),
                topRight: Radius.circular(side == 'leftLung' ? 20 : 40),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: isActive ? [BoxShadow(color: phaseColor.withOpacity(0.8), blurRadius: 15, spreadRadius: 3)] : [],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeart(Color phaseColor, bool isActive) {
    return AnimatedBuilder(
      animation: _heartController,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _heartScale.value : 1.0,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(isActive ? 0.9 : 0.5),
              shape: BoxShape.circle,
              boxShadow: isActive ? [BoxShadow(color: phaseColor.withOpacity(0.9), blurRadius: 20, spreadRadius: 5)] : [],
            ),
            child: Center(child: Icon(Icons.favorite, color: Colors.white, size: 25)),
          ),
        );
      },
    );
  }

  Widget _buildDiaphragm(Color phaseColor, bool isActive) {
    return AnimatedBuilder(
      animation: _diaphragmController,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _diaphragmScale.value : 1.0,
          child: Container(
            width: 140,
            height: 20,
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(isActive ? 0.6 : 0.3),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive ? [BoxShadow(color: phaseColor.withOpacity(0.7), blurRadius: 10, spreadRadius: 2)] : [],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPelvicZone(Color phaseColor, bool isActive) {
    return AnimatedBuilder(
      animation: _pelvicController,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _pelvicScale.value : 1.0,
          child: Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(isActive ? 0.8 : 0.4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: isActive ? [BoxShadow(color: phaseColor.withOpacity(0.9), blurRadius: 20, spreadRadius: 4)] : [],
            ),
            child: Center(child: Icon(Icons.blur_on, color: Colors.white, size: 25)),
          ),
        );
      },
    );
  }

  // Overlay de ALERTA cuando es fase de ALTO
  Widget _buildAlertOverlay(Color phaseColor) {
    return AnimatedBuilder(
      animation: _bodyGlowController,
      builder: (context, child) {
        return Opacity(
          opacity: _bodyGlow.value,
          child: Container(
            width: 220,
            height: 380,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(80),
                topRight: Radius.circular(80),
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              border: Border.all(color: Colors.red, width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, color: Colors.white, size: 60),
                  SizedBox(height: 10),
                  Text('¡PARA!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrganLegend(String name, bool isActive, Color phaseColor) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? phaseColor : Colors.grey[700],
            boxShadow: isActive ? [BoxShadow(color: phaseColor, blurRadius: 5)] : [],
          ),
        ),
        SizedBox(height: 5),
        Text(name, style: TextStyle(fontSize: 10, color: isActive ? Colors.white : Colors.grey[500])),
      ],
    );
  }
}
