import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'dart:async';
import 'user_model.dart';

class EdgingScreen extends StatefulWidget {
  final Isar isar;
  final User user;
  const EdgingScreen({super.key, required this.isar, required this.user});

  @override
  State<EdgingScreen> createState() => _EdgingScreenState();
}

class _EdgingScreenState extends State<EdgingScreen> with TickerProviderStateMixin {
  int _phase = 0; 
  int _introStep = 0;
  int _timeRemaining = 0;
  int _currentCycle = 1;
  final int _totalCycles = 3; 
  Timer? _timer;
  bool _isRunning = false;
  
  late AnimationController _barController;
  late Animation<double> _barAnimation;
  
  // Variables clínicas dinámicas
  late int _phase1Duration; 
  late int _barSpeed;
  late int _currentLevel;
  final int _phase2Duration = 45; 

  @override
  void initState() {
    super.initState();
    
    // 1. Obtener nivel actual (Si es la primera vez, empieza en Nivel 1)
    _currentLevel = widget.user.edgingLevel ?? 1;
    
    // 2. CÁLCULO CLÍNICO DINÁMICO:
    // Base: 126s. Cada nivel aumenta un 10% el tiempo de estimulación.
    _phase1Duration = (126 * (1 + (_currentLevel - 1) * 0.10)).round();
    
    // Ritmo de la barra: Nivel 1 = 400ms. Nivel 10 = 200ms (más rápido = más difícil).
    _barSpeed = (400 - (_currentLevel - 1) * 22).clamp(200, 400);

    _barController = AnimationController(vsync: this, duration: Duration(milliseconds: _barSpeed));
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _barController, curve: Curves.easeInOut));
  }

  void _nextIntroStep() {
    if (_introStep < 3) { setState(() => _introStep++); } 
    else { _startSession(); }
  }

  void _startSession() {
    setState(() { _phase = 1; _isRunning = true; _currentCycle = 1; });
    _runPhase1();
  }

  void _runPhase1() {
    _timeRemaining = _phase1Duration;
    _barController.duration = Duration(milliseconds: _barSpeed);
    _barController.repeat(reverse: true); 
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isRunning) { t.cancel(); return; }
      if (_timeRemaining > 0) { setState(() => _timeRemaining--); } 
      else { _runPhase2(); }
    });
  }

  void _runPhase2() {
    _timeRemaining = _phase2Duration;
    setState(() => _phase = 2);
    HapticFeedback.mediumImpact();
    
    // En la meseta, la barra siempre va a 800ms (ritmo de control y respiración)
    _barController.duration = const Duration(milliseconds: 800);
    _barController.repeat(reverse: true); 
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isRunning) { t.cancel(); return; }
      if (_timeRemaining > 0) { 
        setState(() => _timeRemaining--); 
      } else {
        if (_currentCycle < _totalCycles) {
          setState(() { _currentCycle++; _phase = 1; });
          HapticFeedback.mediumImpact();
          _runPhase1();
        } else {
          _finishPhase();
        }
      }
    });
  }

  void _finishPhase() {
    setState(() { _phase = 3; _isRunning = false; });
    _barController.stop();
    _timer?.cancel();
  }

  void _emergencyStop() {
    _isRunning = false;
    _timer?.cancel();
    _barController.stop();
    HapticFeedback.heavyImpact();
    _showCrossedLimitDialog();
  }

  void _showCrossedLimitDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('⚠️ Cruzaste el Límite', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Si eyaculaste o estuviste a punto, no te preocupes. La app reducirá la dificultad en la próxima sesión para reconstruir tu control.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _finishSession(successful: false); }, 
            child: const Text('Entendido', style: TextStyle(color: Color(0xFF00B4D8)))
          )
        ],
      ),
    );
  }

  void _finishSession({required bool successful}) async {
    // ALGORITMO CLÍNICO DE ADAPTACIÓN DINÁMICA
    if (successful) { 
      widget.user.registerSuccessfulSession(3); // Sube de nivel (máx 10)
    } else { 
      widget.user.registerFailedSession(3); // Baja de nivel (mín 1) para evitar ansiedad
    }
    
    await widget.isar.writeTxn(() => widget.isar.users.put(widget.user));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _isRunning = false;
    _timer?.cancel();
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhase1 = _phase == 1;
    final bool isPhase2 = _phase == 2;
    final Color mainColor = isPhase1 ? const Color(0xFFE94560) : (isPhase2 ? const Color(0xFF00E676) : const Color(0xFF00B4D8));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(backgroundColor: const Color(0xFF0F0F1A), title: const Text('Módulo 3: Edging', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_phase == 0) ...[
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_introStep == 0 ? Icons.psychology : (_introStep == 1 ? Icons.show_chart : (_introStep == 2 ? Icons.timer : Icons.biotech)), size: 80, color: const Color(0xFF00E676)),
                const SizedBox(height: 30),
                Text(_introStep == 0 ? '¿Qué es el Edging?' : _introStep == 1 ? 'La Zona de Control' : _introStep == 2 ? 'Tu Plan de Hoy' : 'Beneficios Clínicos', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Text(
                  _introStep == 0 ? 'Es la técnica de mantenerse en el borde del orgasmo (Nivel 7-8) sin cruzar al punto de no retorno.' 
                  : _introStep == 1 ? 'Primero subirás al Nivel 7 con ritmo normal. Luego, la barra se volverá LENTA: debes bajar la intensidad de tu mano.' 
                  : _introStep == 2 ? 'Nivel Actual: $_currentLevel.\nHaremos $_totalCycles ciclos de: ${_phase1Duration}s subida + ${_phase2Duration}s meseta.' 
                  : 'El Edging enseña a tu cerebro que la alta excitación no es una emergencia.',
                  style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5), textAlign: TextAlign.center,
                )),
              ])),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: index == _introStep ? const Color(0xFF00E676) : Colors.grey[800])))),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _nextIntroStep, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), padding: const EdgeInsets.symmetric(vertical: 18)), child: Text(_introStep == 3 ? 'COMENZAR ENTRENAMIENTO' : 'SIGUIENTE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 20),
            ],
            if (_phase == 1 || _phase == 2) ...[
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: mainColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: mainColor, width: 1)), child: Text(isPhase1 ? 'FASE 1: SUBIDA AL NIVEL 7' : 'FASE 2: MESETA (Ritmo Lento)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mainColor))),
              const SizedBox(height: 10),
              Text('Ciclo $_currentCycle de $_totalCycles | Nivel $_currentLevel', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 10),
              Expanded(flex: 2, child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: mainColor.withOpacity(0.3), width: 2)), child: ClipRRect(borderRadius: BorderRadius.circular(13), child: Stack(children: [
                Positioned.fill(child: Image.asset('assets/images/1793847033003.jpg', fit: BoxFit.cover, alignment: Alignment.center)),
                Positioned.fill(child: CustomPaint(painter: EdgingZonesPainter(isPhase2: isPhase2))),
                Positioned.fill(child: AnimatedBuilder(animation: _barAnimation, builder: (context, child) => CustomPaint(painter: BarOnlyPainter(isStimulating: true, barProgress: _barAnimation.value, mainColor: mainColor)))),
              ])))),
              const SizedBox(height: 20),
              Text(isPhase1 ? 'ESTIMULACIÓN NORMAL (Sigue el ritmo rápido)' : 'MESETA (Baja intensidad, respira)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainColor), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('$_timeRemaining s', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              if (isPhase1) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _emergencyStop, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('¡ALTO! (Si cruzas el Nivel 7 antes de tiempo)', style: TextStyle(fontSize: 16, color: Colors.white)))),
            ],
            if (_phase == 3) ...[
              const Spacer(),
              const Icon(Icons.check_circle, size: 80, color: Color(0xFF00E676)),
              const SizedBox(height: 20),
              const Text('¡Entrenamiento Completado!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              Text('Completaste $_totalCycles ciclos de Edging', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _finishSession(successful: true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), padding: const EdgeInsets.symmetric(vertical: 18)), child: const Text('✅ MANTUVE EL CONTROL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _finishSession(successful: false), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), padding: const EdgeInsets.symmetric(vertical: 18)), child: const Text('❌ CRUCÉ EL LÍMITE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

class EdgingZonesPainter extends CustomPainter {
  final bool isPhase2;
  EdgingZonesPainter({required this.isPhase2});
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.60, w, h * 0.40), Paint()..color = const Color(0xFF00B4D8).withOpacity(0.15));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.25, w, h * 0.35), Paint()..color = const Color(0xFF00E676).withOpacity(isPhase2 ? 0.35 : 0.15));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.25), Paint()..color = const Color(0xFFE94560).withOpacity(0.20));
    final Paint linePaint = Paint()..color = Colors.white.withOpacity(0.2)..strokeWidth = 1;
    canvas.drawLine(Offset(0, h * 0.60), Offset(w, h * 0.60), linePaint);
    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), linePaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarOnlyPainter extends CustomPainter {
  final bool isStimulating;
  final double barProgress;
  final Color mainColor;
  BarOnlyPainter({required this.isStimulating, required this.barProgress, required this.mainColor});
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double topLimit = h * 0.25;
    final double bottomLimit = h * 0.70;
    if (isStimulating) {
      double barY = bottomLimit - (barProgress * (bottomLimit - topLimit));
      canvas.drawLine(Offset(cx - 45, barY + 2), Offset(cx + 45, barY + 2), Paint()..color = Colors.black.withOpacity(0.6)..strokeWidth = 8..strokeCap = StrokeCap.round);
      final Paint barPaint = Paint()..color = mainColor..strokeWidth = 6..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - 45, barY), Offset(cx + 45, barY), barPaint);
      canvas.drawCircle(Offset(cx - 45, barY), 9, Paint()..color = mainColor);
      canvas.drawCircle(Offset(cx + 45, barY), 9, Paint()..color = mainColor);
      canvas.drawCircle(Offset(cx, barY), 4, Paint()..color = Colors.white);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
