import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'dart:async';
import 'user_model.dart';

class StartStopScreen extends StatefulWidget {
  final Isar isar;
  final User user;
  const StartStopScreen({super.key, required this.isar, required this.user});

  @override
  State<StartStopScreen> createState() => _StartStopScreenState();
}

class _StartStopScreenState extends State<StartStopScreen> with TickerProviderStateMixin {
  int _phase = 0; 
  int _introStep = 0; 
  int _cyclesCompleted = 0;
  final int _targetCycles = 3;
  int _timeRemaining = 0;
  Timer? _timer;
  bool _isRunning = false;
  
  late AnimationController _barController;
  late Animation<double> _barAnimation;

  // Variables clínicas dinámicas
  late int _currentLevel;
  late int _stimulateSeconds;
  late int _restSeconds;
  late int _barSpeed;

  @override
  void initState() {
    super.initState();
    
    // 1. Obtener nivel actual (Si es la primera vez, empieza en Nivel 1)
    _currentLevel = widget.user.startStopLevel ?? 1;
    
    // 2. CÁLCULO CLÍNICO DINÁMICO:
    // Base: 60s estimulación, 30s descanso.
    // Cada nivel sube un 10% la estimulación y baja un 5% el descanso.
    _stimulateSeconds = (60 * (1 + (_currentLevel - 1) * 0.10)).round();
    _restSeconds = (30 * (1 - (_currentLevel - 1) * 0.05)).round();
    if (_restSeconds < 10) _restSeconds = 10; // Mínimo clínico de descanso
    
    // Ritmo de la barra: Nivel 1 = 400ms. Nivel 10 = 200ms (más rápido = más difícil).
    _barSpeed = (400 - (_currentLevel - 1) * 22).clamp(200, 400);

    _barController = AnimationController(vsync: this, duration: Duration(milliseconds: _barSpeed));
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _barController, curve: Curves.easeInOut)
    );
  }

  void _nextIntroStep() {
    if (_introStep < 3) {
      setState(() => _introStep++);
    } else {
      _startSession();
    }
  }

  void _startSession() {
    setState(() { 
      _phase = 1; 
      _cyclesCompleted = 0; 
      _isRunning = true;
    });
    _runStartPhase();
  }

  void _runStartPhase() {
    _timeRemaining = _stimulateSeconds;
    _barController.duration = Duration(milliseconds: _barSpeed);
    _barController.repeat(reverse: true); 
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isRunning) { t.cancel(); return; }
      if (_timeRemaining > 0) { setState(() => _timeRemaining--); } 
      else { _runStopPhase(); }
    });
  }

  void _runStopPhase() {
    _timeRemaining = _restSeconds;
    setState(() => _phase = 2);
    HapticFeedback.mediumImpact();
    
    // En el descanso la barra se detiene o va muy lento
    _barController.stop(); 
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isRunning) { t.cancel(); return; }
      if (_timeRemaining > 0) { setState(() => _timeRemaining--); } 
      else { _finishCycle(); }
    });
  }

  void _finishCycle() {
    _cyclesCompleted++;
    if (_cyclesCompleted >= _targetCycles) { 
      setState(() => _phase = 3); 
    } else { 
      setState(() => _phase = 1); 
      _runStartPhase(); 
    }
  }

  void _emergencyStop() {
    _isRunning = false;
    _timer?.cancel(); 
    _barController.stop(); 
    HapticFeedback.heavyImpact();
    _showEarlyEjaculationDialog();
  }

  void _showEarlyEjaculationDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Sesión Detenida', style: TextStyle(color: Colors.white)),
        content: const Text('Si eyaculaste antes, no te preocupes. La app reducirá la dificultad en la próxima sesión para reconstruir tu control.', style: TextStyle(color: Colors.white70)),
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
      widget.user.registerSuccessfulSession(2); // Sube de nivel (máx 10)
    } else { 
      widget.user.registerFailedSession(2); // Baja de nivel (mín 1)
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
    final bool isStimulating = _phase == 1;
    final Color mainColor = isStimulating ? const Color(0xFFE94560) : const Color(0xFF00B4D8);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(backgroundColor: const Color(0xFF0F0F1A), title: const Text('Módulo 2: Start-Stop', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_phase == 0) ...[
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_introStep == 0 ? Icons.school : (_introStep == 1 ? Icons.touch_app : (_introStep == 2 ? Icons.timer : Icons.biotech)), size: 80, color: const Color(0xFF00B4D8)),
                const SizedBox(height: 30),
                Text(_introStep == 0 ? '¿Qué es el Start-Stop?' : _introStep == 1 ? '¿Cómo se hace?' : _introStep == 2 ? 'Tu Plan de Hoy' : 'La Importancia del Test', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Text(
                  _introStep == 0 ? 'Es un método clínico creado por Masters y Johnson. Sirve para mapear tu sistema nervioso y enseñarle a tu cerebro a retrasar el reflejo eyaculatorio sin perder la erección.' 
                  : _introStep == 1 ? 'Verás una guía visual. Cuando la barra suba y baje, estimula siguiendo ese ritmo. Cuando se detenga, suelta la mano, respira profundo y relaja el suelo pélvico. Repetiremos esto 3 veces.' 
                  : _introStep == 2 ? 'Nivel Actual: $_currentLevel.\nHoy harás 3 ciclos de: ${_stimulateSeconds}s de estimulación y ${_restSeconds}s de descanso.' 
                  : 'Estos tiempos se ajustan automáticamente. Si tienes éxito, la próxima sesión será más difícil. Si fallas, será más fácil para evitar ansiedad.',
                  style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5), textAlign: TextAlign.center,
                )),
              ])),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: index == _introStep ? const Color(0xFF00B4D8) : Colors.grey[800])))),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _nextIntroStep, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8), padding: const EdgeInsets.symmetric(vertical: 18)), child: Text(_introStep == 3 ? 'COMENZAR ENTRENAMIENTO' : 'SIGUIENTE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 20),
            ],
            if (_phase == 1 || _phase == 2) ...[
              Text('Ciclo ${_cyclesCompleted + 1} de $_targetCycles | Nivel $_currentLevel', style: const TextStyle(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 20),
              Expanded(flex: 2, child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: mainColor.withOpacity(0.3), width: 2)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    children: [
                      Positioned.fill(child: Image.asset('assets/images/1793847033003.jpg', fit: BoxFit.cover, alignment: Alignment.center)),
                      Positioned.fill(
                        child: AnimatedBuilder(animation: _barAnimation, builder: (context, child) => CustomPaint(painter: BarOnlyPainter(isStimulating: isStimulating, barProgress: _barAnimation.value, mainColor: mainColor))),
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 20),
              Text(isStimulating ? 'ESTIMULACIÓN (Sigue el ritmo)' : 'PARADA (Suelta y respira)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: mainColor)),
              const SizedBox(height: 10),
              Text('$_timeRemaining s', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              if (isStimulating) SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _emergencyStop, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('¡ALTO! (Si llegas al límite antes de tiempo)', style: TextStyle(fontSize: 16, color: Colors.white)))),
            ],
            if (_phase == 3) ...[
              const Spacer(),
              const Icon(Icons.check_circle, size: 80, color: Color(0xFF00E676)),
              const SizedBox(height: 20),
              const Text('¡Ciclos Completados!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text('Has entrenado el reflejo correctamente.', style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _finishSession(successful: true), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), padding: const EdgeInsets.symmetric(vertical: 18)), child: const Text('✅ CUMPLÍ EL TIEMPO (Puedo eyacular)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _finishSession(successful: false), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), padding: const EdgeInsets.symmetric(vertical: 18)), child: const Text('❌ EYACULÉ ANTES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================
// PINTOR OPTIMIZADO (SOLO DIBUJA LA BARRA)
// ============================================
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

      final Paint handlePaint = Paint()..color = mainColor;
      canvas.drawCircle(Offset(cx - 45, barY), 9, handlePaint);
      canvas.drawCircle(Offset(cx + 45, barY), 9, handlePaint);
      canvas.drawCircle(Offset(cx, barY), 4, Paint()..color = Colors.white);
    } else {
      final Paint restPaint = Paint()..color = mainColor.withOpacity(0.6)..strokeWidth = 4..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - 35, bottomLimit), Offset(cx + 35, bottomLimit), restPaint);
      canvas.drawCircle(Offset(cx, bottomLimit), 10, Paint()..color = mainColor.withOpacity(0.3));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
