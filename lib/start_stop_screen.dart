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
    _barController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 400), 
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
    setState(() { _phase = 1; _cyclesCompleted = 0; });
    _runStartPhase();
  }

  void _runStartPhase() {
    _timeRemaining = widget.user.trainingRhythmStimulateSeconds;
    _barController.repeat(reverse: true); 
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemaining > 0) { setState(() => _timeRemaining--); } 
      else { _runStopPhase(); }
    });
  }

  void _runStopPhase() {
    _barController.stop(); 
    _timeRemaining = widget.user.trainingRhythmRestSeconds;
    setState(() => _phase = 2);
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemaining > 0) { setState(() => _timeRemaining--); } 
      else { _finishCycle(); }
    });
  }

  void _finishCycle() {
    _cyclesCompleted++;
    if (_cyclesCompleted >= _targetCycles) { setState(() => _phase = 3); } 
    else { setState(() => _phase = 1); _runStartPhase(); }
  }

  void _emergencyStop() {
    _timer?.cancel(); _barController.stop(); HapticFeedback.heavyImpact();
    _showEarlyEjaculationDialog();
  }

  void _showEarlyEjaculationDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Sesión Detenida', style: TextStyle(color: Colors.white)),
        content: const Text('Si eyaculaste antes, no te preocupes. Es parte del entrenamiento. Ajustaremos tus tiempos para mañana.', style: TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () { Navigator.pop(context); _finishSession(successful: false); }, child: const Text('Entendido', style: TextStyle(color: Color(0xFF00B4D8))))],
      ),
    );
  }

  void _finishSession({required bool successful}) async {
    if (successful) { widget.user.registerSuccessfulSession(2); } 
    else { widget.user.totalSessions++; widget.user.updatedAt = DateTime.now(); }
    await widget.isar.writeTxn(() => widget.isar.users.put(widget.user));
    if (!mounted) return; Navigator.pop(context);
  }

  @override
  void dispose() { _timer?.cancel(); _barController.dispose(); super.dispose(); }

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
                Text(_introStep == 0 ? '¿Qué es el Start-Stop?' : _introStep == 1 ? '¿Cómo se hace?' : _introStep == 2 ? 'Tus Tiempos de Hoy' : 'La Importancia del Test', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Text(
                  _introStep == 0 ? 'Es un método clínico creado por Masters y Johnson. Sirve para mapear tu sistema nervioso y enseñarle a tu cerebro a retrasar el reflejo eyaculatorio sin perder la erección.' 
                  : _introStep == 1 ? 'Verás una guía visual. Cuando la barra suba y baje, estimula siguiendo ese ritmo. Cuando se detenga, suelta la mano, respira profundo y relaja el suelo pélvico. Repetiremos esto 3 veces.' 
                  : _introStep == 2 ? 'Hoy harás ${widget.user.trainingRhythmStimulateSeconds} segundos de estimulación y ${widget.user.trainingRhythmRestSeconds} segundos de descanso. Al completar los 3 ciclos, recibirás el permiso clínico para eyacular.' 
                  : 'Estos tiempos son seguros. PERO, si haces el Test MELT (cronómetro) y el Test de Pulso en el Dashboard, la app calculará tus tiempos EXACTOS basados en tu fisiología real, mejorando tu control un 40% más rápido.',
                  style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5), textAlign: TextAlign.center,
                )),
              ])),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: index == _introStep ? const Color(0xFF00B4D8) : Colors.grey[800])))),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _nextIntroStep, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8), padding: const EdgeInsets.symmetric(vertical: 18)), child: Text(_introStep == 3 ? 'COMENZAR ENTRENAMIENTO' : 'SIGUIENTE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 20),
            ],
            if (_phase == 1 || _phase == 2) ...[
              Text('Ciclo ${_cyclesCompleted + 1} de $_targetCycles', style: const TextStyle(fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 20),
              Expanded(flex: 2, child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: mainColor.withOpacity(0.3), width: 2)),
                child: AnimatedBuilder(animation: _barAnimation, builder: (context, child) => CustomPaint(painter: AnatomicalCrossSectionPainter(isStimulating: isStimulating, barProgress: _barAnimation.value, mainColor: mainColor))),
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
// ILUSTRACIÓN ANATÓMICA MEJORADA (Estilo Netter 3D)
// ============================================
class AnatomicalCrossSectionPainter extends CustomPainter {
  final bool isStimulating;
  final double barProgress;
  final Color mainColor;

  AnatomicalCrossSectionPainter({
    required this.isStimulating,
    required this.barProgress,
    required this.mainColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    // 1. Fondo clínico oscuro con viñeta sutil
    final Rect canvasRect = Rect.fromLTWH(0, 0, w, h);
    final Paint bgPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [const Color(0xFF10192D), const Color(0xFF050811)],
      ).createShader(canvasRect);
    canvas.drawRect(canvasRect, bgPaint);

    // ============================================
    // 2. ESCROTO (Con volumen y profundidad)
    // ============================================
    final Path scrotumPath = Path()
      ..moveTo(cx - 65, h * 0.80)
      ..cubicTo(cx - 75, h * 0.92, cx - 50, h * 0.99, cx, h * 0.99)
      ..cubicTo(cx + 50, h * 0.99, cx + 75, h * 0.92, cx + 65, h * 0.80)
      ..quadraticBezierTo(cx + 45, h * 0.77, cx, h * 0.78)
      ..quadraticBezierTo(cx - 45, h * 0.77, cx - 65, h * 0.80)
      ..close();

    final Paint scrotumPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.3),
        radius: 0.8,
        colors: [
          const Color(0xFF234C7A),
          const Color(0xFF132A45),
          const Color(0xFF0A1522),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(scrotumPath.getBounds());
    
    canvas.drawPath(scrotumPath, scrotumPaint);
    canvas.drawPath(
      scrotumPath,
      Paint()
        ..color = const Color(0xFF5C9CE6).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // ============================================
    // 3. TESTÍCULOS INTERNOS (Efecto 3D esférico)
    // ============================================
    _drawAdvancedTesticle(canvas, cx - 26, h * 0.87, 23, 30);
    _drawAdvancedTesticle(canvas, cx + 26, h * 0.87, 23, 30);

    // ============================================
    // 4. CUERPO DEL PENE (Estructura principal)
    // ============================================
    final double shaftTop = h * 0.24;
    final double shaftBottom = h * 0.78;
    final double shaftWidth = 52;

    final Path shaftPath = Path()
      ..moveTo(cx - shaftWidth / 2, shaftBottom)
      ..cubicTo(cx - shaftWidth / 2 - 8, h * 0.55, cx - shaftWidth / 2 - 4, shaftTop + 10, cx - shaftWidth / 2 + 6, shaftTop)
      ..lineTo(cx + shaftWidth / 2 - 6, shaftTop)
      ..cubicTo(cx + shaftWidth / 2 + 4, shaftTop + 10, cx + shaftWidth / 2 + 8, h * 0.55, cx + shaftWidth / 2, shaftBottom)
      ..close();

    final Paint shaftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF0D233A),
          const Color(0xFF1B4973),
          const Color(0xFF2A6F97),
          const Color(0xFF1B4973),
          const Color(0xFF0D233A),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(shaftPath.getBounds());

    canvas.drawPath(shaftPath, shaftPaint);
    canvas.drawPath(
      shaftPath,
      Paint()
        ..color = const Color(0xFF64B5F6).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // ============================================
    // 5. CUERPOS CAVERNOSOS (Simetría interna)
    // ============================================
    final Path leftCavernous = Path()
      ..moveTo(cx - 7, shaftTop + 12)
      ..cubicTo(cx - 22, h * 0.45, cx - 20, h * 0.65, cx - 9, shaftBottom - 12)
      ..lineTo(cx - 3, shaftBottom - 12)
      ..cubicTo(cx - 8, h * 0.65, cx - 8, h * 0.45, cx - 3, shaftTop + 12)
      ..close();

    final Path rightCavernous = Path()
      ..moveTo(cx + 7, shaftTop + 12)
      ..cubicTo(cx + 22, h * 0.45, cx + 20, h * 0.65, cx + 9, shaftBottom - 12)
      ..lineTo(cx + 3, shaftBottom - 12)
      ..cubicTo(cx + 8, h * 0.65, cx + 8, h * 0.45, cx + 3, shaftTop + 12)
      ..close();

    final Paint cavernousFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF0077B6), const Color(0xFF03045E)],
      ).createShader(shaftPath.getBounds());

    canvas.drawPath(leftCavernous, cavernousFill);
    canvas.drawPath(rightCavernous, cavernousFill);

    // ============================================
    // 6. URETRA Y CUERPO ESPONJOSO (Eje central)
    // ============================================
    final Path urethraPath = Path()
      ..moveTo(cx - 3.5, shaftTop + 15)
      ..lineTo(cx + 3.5, shaftTop + 15)
      ..lineTo(cx + 3.5, shaftBottom - 10)
      ..lineTo(cx - 3.5, shaftBottom - 10)
      ..close();

    final Paint urethraPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [const Color(0xFFFF4D6D), const Color(0xFFC9184A), const Color(0xFFFF4D6D)],
      ).createShader(urethraPath.getBounds());

    canvas.drawPath(urethraPath, urethraPaint);

    // ============================================
    // 7. GLANDE (Detalle superior anatómico)
    // ============================================
    final Path glansPath = Path()
      ..moveTo(cx - 26, shaftTop)
      ..cubicTo(cx - 34, shaftTop - 12, cx - 30, shaftTop - 28, cx - 20, shaftTop - 40)
      ..cubicTo(cx - 10, shaftTop - 48, cx + 10, shaftTop - 48, cx + 20, shaftTop - 40)
      ..cubicTo(cx + 30, shaftTop - 28, cx + 34, shaftTop - 12, cx + 26, shaftTop)
      ..quadraticBezierTo(cx, shaftTop + 6, cx - 26, shaftTop)
      ..close();

    final Paint glansPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 0.7,
        colors: [const Color(0xFF00B4D8), const Color(0xFF0077B6), const Color(0xFF03045E)],
      ).createShader(glansPath.getBounds());

    canvas.drawPath(glansPath, glansPaint);
    canvas.drawPath(
      glansPath,
      Paint()
        ..color = const Color(0xFF90E0EF).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // Meato uretral en el glande
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, shaftTop - 38), width: 5, height: 12),
      Paint()..color = const Color(0xFF590D22),
    );

    // ============================================
    // 8. VASOS SANGUÍNEOS DETALLADOS (Efecto orgánico)
    // ============================================
    final Paint vesselPaint = Paint()
      ..color = const Color(0xFFFF758F).withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final Path vLeft = Path()
      ..moveTo(cx - 16, shaftTop + 22)
      ..cubicTo(cx - 22, h * 0.38, cx - 12, h * 0.52, cx - 18, h * 0.68);
    
    final Path vRight = Path()
      ..moveTo(cx + 16, shaftTop + 22)
      ..cubicTo(cx + 22, h * 0.38, cx + 12, h * 0.52, cx + 18, h * 0.68);

    canvas.drawPath(vLeft, vesselPaint);
    canvas.drawPath(vRight, vesselPaint);

    // ============================================
    // 9. BARRA DE RITMO (Guía de Mano Interactiva)
    // ============================================
    if (isStimulating) {
      double barY = shaftBottom - (barProgress * (shaftBottom - shaftTop + 25));

      // Sombra de la barra
      canvas.drawLine(
        Offset(cx - 48, barY + 3),
        Offset(cx + 48, barY + 3),
        Paint()..color = Colors.black.withOpacity(0.5)..strokeWidth = 8..strokeCap = StrokeCap.round,
      );

      // Línea principal de la barra
      final Paint barLinePaint = Paint()
        ..color = mainColor
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(Offset(cx - 48, barY), Offset(cx + 48, barY), barLinePaint);

      // Extremos circulares de la barra (manijas rojas/azules)
      final Paint handlePaint = Paint()..color = mainColor;
      canvas.drawCircle(Offset(cx - 48, barY), 11, handlePaint);
      canvas.drawCircle(Offset(cx + 48, barY), 11, handlePaint);

      // Brillo interior de los círculos
      canvas.drawCircle(Offset(cx - 48, barY), 4, Paint()..color = Colors.white.withOpacity(0.7));
      canvas.drawCircle(Offset(cx + 48, barY), 4, Paint()..color = Colors.white.withOpacity(0.7));
      
      // Indicador central brillante
      canvas.drawCircle(Offset(cx, barY), 5, Paint()..color = Colors.white);
    } else {
      // Estado de descanso (Quiet)
      final Paint restPaint = Paint()
        ..color = mainColor.withOpacity(0.6)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - 38, shaftBottom), Offset(cx + 38, shaftBottom), restPaint);
      canvas.drawCircle(Offset(cx, shaftBottom), 13, Paint()..color = mainColor.withOpacity(0.3));
    }
  }

  void _drawAdvancedTesticle(Canvas canvas, double x, double y, double w, double h) {
    final Rect rect = Rect.fromCenter(center: Offset(x, y), width: w * 2, height: h * 2);
    
    final Paint testicleShader = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
        colors: [
          const Color(0xFF1D4ED8).withOpacity(0.9),
          const Color(0xFF1E3A8A).withOpacity(0.95),
          const Color(0xFF0F172A),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawOval(rect, testicleShader);
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFF60A5FA).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
