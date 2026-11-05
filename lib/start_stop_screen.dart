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
  
  late AnimationController _barController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    // CLÍNICO: 800ms por ciclo completo (aprox. 75 movimientos/minuto, ritmo controlado)
    _barController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 800), 
    );
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
    });
    _runStartPhase();
  }

  void _runStartPhase() {
    _timeRemaining = widget.user.trainingRhythmStimulateSeconds;
    // CLÍNICO: La barra se repite infinitamente (sube y baja) durante la fase
    _barController.repeat(reverse: true); 
    
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _runStopPhase();
      }
    });
  }

  void _runStopPhase() {
    _barController.stop(); // La barra se detiene en la base
    _timeRemaining = widget.user.trainingRhythmRestSeconds;
    setState(() => _phase = 2);
    HapticFeedback.mediumImpact();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _finishCycle();
      }
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
    _timer?.cancel();
    _barController.stop();
    HapticFeedback.heavyImpact();
    _showEarlyEjaculationDialog();
  }

  void _showEarlyEjaculationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Sesión Detenida', style: TextStyle(color: Colors.white)),
        content: const Text('Si eyaculaste antes, no te preocupes. Es parte del entrenamiento. Ajustaremos tus tiempos para mañana.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _finishSession(successful: false); },
            child: const Text('Entendido', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }

  void _finishSession({required bool successful}) async {
    if (successful) {
      widget.user.registerSuccessfulSession(2);
    } else {
      widget.user.totalSessions++;
      widget.user.updatedAt = DateTime.now();
    }
    await widget.isar.writeTxn(() => widget.isar.users.put(widget.user));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Módulo 2: Start-Stop', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_phase == 0) ...[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _introStep == 0 ? Icons.school : (_introStep == 1 ? Icons.touch_app : (_introStep == 2 ? Icons.timer : Icons.biotech)),
                      size: 80, color: const Color(0xFF00B4D8),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _introStep == 0 ? '¿Qué es el Start-Stop?' :
                      _introStep == 1 ? '¿Cómo se hace?' :
                      _introStep == 2 ? 'Tus Tiempos de Hoy' : 'La Importancia del Test',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        _introStep == 0 
                            ? 'Es un método clínico creado por Masters y Johnson. Sirve para mapear tu sistema nervioso y enseñarle a tu cerebro a retrasar el reflejo eyaculatorio sin perder la erección.' 
                            : _introStep == 1 
                                ? 'Verás una guía visual. Cuando la barra suba y baje, estimula siguiendo ese ritmo. Cuando se detenga, suelta la mano, respira profundo y relaja el suelo pélvico. Repetiremos esto 3 veces.' 
                                : _introStep == 2 
                                    ? 'Hoy harás ${widget.user.trainingRhythmStimulateSeconds} segundos de estimulación y ${widget.user.trainingRhythmRestSeconds} segundos de descanso. Al completar los 3 ciclos, recibirás el permiso clínico para eyacular.' 
                                    : 'Estos tiempos son seguros. PERO, si haces el Test MELT (cronómetro) y el Test de Pulso en el Dashboard, la app calculará tus tiempos EXACTOS basados en tu fisiología real, mejorando tu control un 40% más rápido.',
                        style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _introStep ? const Color(0xFF00B4D8) : Colors.grey[800],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextIntroStep,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8), padding: const EdgeInsets.symmetric(vertical: 18)),
                  child: Text(_introStep == 3 ? 'COMENZAR ENTRENAMIENTO' : 'SIGUIENTE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_phase == 1 || _phase == 2) ...[
              Text('Ciclo ${_cyclesCompleted + 1} de $_targetCycles', style: const TextStyle(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 20),
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: mainColor.withOpacity(0.3), width: 2)),
                  child: CustomPaint(
                    painter: ClinicalSilhouettePainter(
                      isStimulating: isStimulating,
                      barProgress: _barAnimation.value,
                      mainColor: mainColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isStimulating ? 'ESTIMULACIÓN (Sigue el ritmo)' : 'PARADA (Suelta y respira)',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: mainColor),
              ),
              const SizedBox(height: 10),
              Text('$_timeRemaining s', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              if (isStimulating)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _emergencyStop,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: const Text('¡ALTO! (Si llegas al límite antes de tiempo)', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
            ],

            if (_phase == 3) ...[
              const Spacer(),
              const Icon(Icons.check_circle, size: 80, color: Color(0xFF00E676)),
              const SizedBox(height: 20),
              const Text('¡Ciclos Completados!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text('Has entrenado el reflejo correctamente.', style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _finishSession(successful: true),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), padding: const EdgeInsets.symmetric(vertical: 18)),
                  child: const Text('✅ CUMPLÍ EL TIEMPO (Puedo eyacular)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _finishSession(successful: false),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), padding: const EdgeInsets.symmetric(vertical: 18)),
                  child: const Text('❌ EYACULÉ ANTES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

// Ilustración Anatómica Clínica Mejorada
class ClinicalSilhouettePainter extends CustomPainter {
  final bool isStimulating;
  final double barProgress;
  final Color mainColor;

  ClinicalSilhouettePainter({required this.isStimulating, required this.barProgress, required this.mainColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    // Fondo clínico oscuro
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF1A1A2E));

    // Colores anatómicos clínicos
    final Color tissueBase = const Color(0xFF4A90E2);
    final Color tissueDark = const Color(0xFF0077B6);

    // 1. Cuerpo Cavernoso (Eje / Shaft)
    final Paint shaftPaint = Paint()..color = tissueBase.withOpacity(0.4)..style = PaintingStyle.fill;
    final Paint outlinePaint = Paint()..color = tissueBase..style = PaintingStyle.stroke..strokeWidth = 2;

    final Path shaft = Path()
      ..moveTo(cx - 25, h * 0.85)
      ..lineTo(cx - 22, h * 0.35)
      ..quadraticBezierTo(cx - 22, h * 0.25, cx - 15, h * 0.20)
      ..quadraticBezierTo(cx, h * 0.05, cx + 15, h * 0.20)
      ..quadraticBezierTo(cx + 22, h * 0.25, cx + 22, h * 0.35)
      ..lineTo(cx + 25, h * 0.85)
      ..close();
    canvas.drawPath(shaft, shaftPaint);
    canvas.drawPath(shaft, outlinePaint);

    // 2. Glande (Cabeza) - Detalle clínico
    final Paint glansPaint = Paint()..color = tissueDark.withOpacity(0.6)..style = PaintingStyle.fill;
    final Path glans = Path()
      ..moveTo(cx - 22, h * 0.35)
      ..quadraticBezierTo(cx - 22, h * 0.25, cx - 15, h * 0.20)
      ..quadraticBezierTo(cx, h * 0.05, cx + 15, h * 0.20)
      ..quadraticBezierTo(cx + 22, h * 0.25, cx + 22, h * 0.35)
      ..quadraticBezierTo(cx, h * 0.38, cx - 22, h * 0.35); // Corona
    canvas.drawPath(glans, glansPaint);
    canvas.drawPath(glans, outlinePaint);

    // 3. Base / Escroto (Simplificado clínico)
    final Paint basePaint = Paint()..color = tissueBase.withOpacity(0.3)..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, h * 0.90), width: 70, height: 30), basePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, h * 0.90), width: 70, height: 30), outlinePaint);

    // 4. Barra de Ritmo Animada (Guía de la mano)
    if (isStimulating) {
      // La barra se mueve a lo largo del eje
      double barY = h * 0.85 - (barProgress * (h * 0.55)); 
      final Paint barPaint = Paint()..color = mainColor..strokeWidth = 5..strokeCap = StrokeCap.round;
      
      // Línea de la mano
      canvas.drawLine(Offset(cx - 40, barY), Offset(cx + 40, barY), barPaint);
      
      // Indicadores de agarre
      canvas.drawCircle(Offset(cx - 40, barY), 8, Paint()..color = mainColor.withOpacity(0.8));
      canvas.drawCircle(Offset(cx + 40, barY), 8, Paint()..color = mainColor.withOpacity(0.8));
    } else {
      // Fase de parada: La barra se detiene en la base y palpita
      final Paint restPaint = Paint()..color = mainColor.withOpacity(0.5)..strokeWidth = 4;
      canvas.drawLine(Offset(cx - 35, h * 0.85), Offset(cx + 35, h * 0.85), restPaint);
      
      // Indicador de "Soltar"
      canvas.drawCircle(Offset(cx, h * 0.85), 10, Paint()..color = mainColor.withOpacity(0.3));
    }

    // Etiquetas clínicas
    _drawLabel(canvas, "Guía de Ritmo de Mano", cx, h * 0.02, mainColor);
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, Color color) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
