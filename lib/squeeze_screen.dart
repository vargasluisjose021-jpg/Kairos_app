import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'dart:async';
import 'user_model.dart';

class SqueezeScreen extends StatefulWidget {
  final Isar isar;
  final User user;
  const SqueezeScreen({super.key, required this.isar, required this.user});

  @override
  State<SqueezeScreen> createState() => _SqueezeScreenState();
}

class _SqueezeScreenState extends State<SqueezeScreen> with TickerProviderStateMixin {
  int _phase = 0; // 0: Intro, 1: Subida, 2: Squeeze, 3: Breath, 4: Final
  int _introStep = 0;
  int _timeRemaining = 0;
  int _breathPhaseTime = 0;
  int _currentCycle = 1;
  final int _totalCycles = 3;
  Timer? _timer;
  bool _isRunning = false;
  
  late int _currentLevel;
  late int _stimulateSeconds; // 70% del MELT
  final int _squeezeDuration = 10;
  final int _breathDuration = 19;
  
  // Controladores de animación
  late AnimationController _barController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    
    // 1. Nivel dinámico
    _currentLevel = widget.user.startStopLevel ?? 1;
    
    // 2. Calcular MELT según edad (clínicamente real, igual que Módulo 3)
    int melt = _getDefaultMeltByAge(widget.user.age ?? 25);
    
    // 3. Fase 1 = 70% del MELT, ajustado por nivel (+10% por nivel)
    _stimulateSeconds = ((melt * 0.70) * (1 + (_currentLevel - 1) * 0.10)).round();
    
    // Barra animada (ritmo según nivel)
    int barSpeed = (400 - (_currentLevel - 1) * 22).clamp(200, 400);
    _barController = AnimationController(vsync: this, duration: Duration(milliseconds: barSpeed));
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOut),
    );
  }

  // Tiempos estándar mundiales por edad (Fallback clínico)
  int _getDefaultMeltByAge(int age) {
    if (age >= 14 && age <= 17) return 120;
    if (age >= 18 && age <= 30) return 180;
    if (age >= 31 && age <= 50) return 300;
    return 360;
  }

  void _nextIntroStep() {
    if (_introStep < 3) { setState(() => _introStep++); } 
    else { _startSession(); }
  }

  void _startSession() {
    setState(() { _phase = 1; _isRunning = true; _currentCycle = 1; });
    _runPhase1();
  }

  // FASE 1: SUBIDA CON BARRA ANIMADA
  void _runPhase1() {
    _timeRemaining = _stimulateSeconds;
    _barController.repeat(reverse: true);
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isRunning) { t.cancel(); return; }
      if (_timeRemaining > 0) { setState(() => _timeRemaining--); } 
      else { _runPhase2(); }
    });
  }

  // FASE 2: SQUEEZE (Pasivo, sin botones)
  void _runPhase2() {
    _timeRemaining = _squeezeDuration;
    setState(() => _phase = 2);
    HapticFeedback.heavyImpact();
    _barController.stop();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isRunning) { t.cancel(); return; }
      if (_timeRemaining > 0) { 
        setState(() => _timeRemaining--); 
      } else {
        _runPhase3();
      }
    });
  }

  // FASE 3: RESPIRACIÓN 4-7-8
  void _runPhase3() {
    setState(() { 
      _phase = 3; 
      _timeRemaining = _breathDuration;
      _breathPhaseTime = 0;
    });
    HapticFeedback.lightImpact();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isRunning) { t.cancel(); return; }
      if (_timeRemaining > 0) { 
        setState(() { 
          _timeRemaining--; 
          _breathPhaseTime++;
        }); 
      } else {
        // Si no es el último ciclo, vuelve a Fase 1
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
    setState(() { _phase = 4; _isRunning = false; });
    _barController.stop();
    _timer?.cancel();
  }

  void _finishSession({required bool successful}) async {
    if (successful) { 
      widget.user.registerSuccessfulSession(2); // Sube nivel
    } else { 
      widget.user.registerFailedSession(2); // Baja nivel
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

  String _getBreathInstruction() {
    if (_breathPhaseTime < 4) return "INHALA";
    if (_breathPhaseTime < 11) return "RETÉN";
    return "EXHALA";
  }

  Color _getBreathColor() {
    if (_breathPhaseTime < 4) return const Color(0xFF00B4D8);
    if (_breathPhaseTime < 11) return const Color(0xFF00E676);
    return const Color(0xFFE94560);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(backgroundColor: const Color(0xFF0F0F1A), title: const Text('Módulo 4: Control Total', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_phase == 0) ...[
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_introStep == 0 ? Icons.pan_tool : (_introStep == 1 ? Icons.air : (_introStep == 2 ? Icons.timer : Icons.biotech)), size: 80, color: const Color(0xFFFF9F1C)),
                const SizedBox(height: 30),
                Text(_introStep == 0 ? 'Técnica Squeeze' : _introStep == 1 ? 'Respiración 4-7-8' : _introStep == 2 ? 'Tu Plan de Hoy' : 'El Hack Final', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Text(
                  _introStep == 0 ? 'Cuando estés al borde (Nivel 9), debes aplicar presión firme con tus dedos en el frenillo (base del glande). Esto frena mecánicamente el reflejo.' 
                  : _introStep == 1 ? 'Inmediatamente después del Squeeze, usa la respiración 4-7-8: Inhala en 4s, Retén 7s, Exhala en 8s. Esto activa tu sistema nervioso parasimpático.' 
                  : _introStep == 2 ? 'Nivel Actual: $_currentLevel.\nHaremos $_totalCycles ciclos de:\n- ${_stimulateSeconds}s de subida al borde\n- 10s de Squeeze\n- 19s de Respiración' 
                  : 'Dominar esto te da control total. Podrás detener la eyaculación incluso en el último segundo.',
                  style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5), textAlign: TextAlign.center,
                )),
              ])),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: index == _introStep ? const Color(0xFFFF9F1C) : Colors.grey[800])))),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _nextIntroStep, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9F1C), padding: const EdgeInsets.symmetric(vertical: 18)), child: Text(_introStep == 3 ? 'COMENZAR ENTRENAMIENTO' : 'SIGUIENTE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 20),
            ],
            
            if (_phase == 1) ...[
              const Text('FASE 1: SUBIDA AL BORDE (Nivel 9)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE94560))),
              const SizedBox(height: 10),
              Text('Ciclo $_currentCycle de $_totalCycles | Nivel $_currentLevel', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 10),
              Expanded(flex: 2, child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE94560).withOpacity(0.3), width: 2)), child: ClipRRect(borderRadius: BorderRadius.circular(13), child: Stack(children: [
                Positioned.fill(child: Image.asset('assets/images/1793847033003.jpg', fit: BoxFit.cover, alignment: Alignment.center)),
                Positioned.fill(child: AnimatedBuilder(animation: _barAnimation, builder: (context, child) => CustomPaint(painter: BarOnlyPainter(isStimulating: true, barProgress: _barAnimation.value, mainColor: const Color(0xFFE94560))))),
              ])))),
              const SizedBox(height: 20),
              const Text('Estimula siguiendo el ritmo rápido', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE94560))),
              const SizedBox(height: 10),
              Text('$_timeRemaining s', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
            ],

            if (_phase == 2) ...[
              const Text('FASE 2: APLICA PRESIÓN (SQUEEZE)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF9F1C))),
              const SizedBox(height: 10),
              Text('Ciclo $_currentCycle de $_totalCycles', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 10),
              Expanded(flex: 2, child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFFF9F1C).withOpacity(0.3), width: 2)), child: ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.asset('assets/images/1793847033003.jpg', fit: BoxFit.cover, alignment: Alignment.center)))),
              const SizedBox(height: 20),
              const Text('SUELTA EL CELULAR\nAPLICA PRESIÓN EN EL FRENILLO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF9F1C)), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Text('Mantén la presión: $_timeRemaining s', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ],

            if (_phase == 3) ...[
              const Text('FASE 3: RESPIRACIÓN 4-7-8', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00B4D8))),
              const SizedBox(height: 10),
              Text('Ciclo $_currentCycle de $_totalCycles', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 10),
              Expanded(flex: 2, child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: _getBreathColor().withOpacity(0.3), width: 2)), child: ClipRRect(borderRadius: BorderRadius.circular(13), child: Stack(children: [
                Positioned.fill(child: Image.asset('assets/images/1793938034308.jpg', fit: BoxFit.cover, alignment: Alignment.center)),
                Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3))),
                Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_getBreathInstruction(), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _getBreathColor())),
                  const SizedBox(height: 10),
                  Text('$_timeRemaining s', style: const TextStyle(fontSize: 28, color: Colors.white)),
                ])),
              ])))),
            ],

            if (_phase == 4) ...[
              const Spacer(),
              const Icon(Icons.check_circle, size: 80, color: Color(0xFF00E676)),
              const SizedBox(height: 20),
              const Text('¡Control Total Logrado!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              Text('Completaste $_totalCycles ciclos', style: const TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _finishSession(successful: true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), padding: const EdgeInsets.symmetric(vertical: 18)), child: const Text('✅ DOMINÉ LA TÉCNICA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _finishSession(successful: false), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), padding: const EdgeInsets.symmetric(vertical: 18)), child: const Text('❌ PERDÍ EL CONTROL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

// Pintor de la barra animada (igual que Módulos 2 y 3)
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
