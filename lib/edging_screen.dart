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
  int _phase = 0; // 0: Intro, 1: Subida, 2: Meseta, 3: Final
  int _introStep = 0;
  int _timeRemaining = 0;
  Timer? _timer;
  bool _isRunning = false;
  
  // Controladores de animación (2 velocidades)
  late AnimationController _fastBarController;
  late AnimationController _slowBarController;
  late Animation<double> _barAnimation;
  
  // Tiempos calculados
  late int _phase1Duration; // 70% del MELT
  final int _phase2Duration = 45; // Meseta fija

  @override
  void initState() {
    super.initState();
    
    // Calcular MELT según edad si no hay test
    int melt = widget.user.meltSeconds > 0 
        ? widget.user.meltSeconds 
        : _getDefaultMeltByAge(widget.user.age);
    
    _phase1Duration = (melt * 0.7).round();
    
    // Animación rápida (Fase 1): 400ms por ciclo (~75 mov/min)
    _fastBarController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    // Animación lenta (Fase 2): 800ms por ciclo (~37 mov/min)
    _slowBarController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fastBarController, curve: Curves.easeInOut),
    );
  }

  // Tiempos estándar mundiales por edad (si no hizo el test)
  int _getDefaultMeltByAge(int age) {
    if (age >= 14 && age <= 17) return 120;   // 2 min
    if (age >= 18 && age <= 30) return 180;   // 3 min
    if (age >= 31 && age <= 50) return 300;   // 5 min
    return 360;                                // 6 min (51+)
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
      _isRunning = true;
    });
    _runPhase1();
  }

  void _runPhase1() {
    _timeRemaining = _phase1Duration;
    // Cambiar a animación rápida
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fastBarController, curve: Curves.easeInOut),
    );
    _fastBarController.repeat(reverse: true);
    _slowBarController.stop();
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isRunning) { t.cancel(); return; }
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _runPhase2();
      }
    });
  }

  void _runPhase2() {
    _timeRemaining = _phase2Duration;
    setState(() => _phase = 2);
    HapticFeedback.mediumImpact();
    
    // Cambiar a animación lenta (simula bajar intensidad de la mano)
    _fastBarController.stop();
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slowBarController, curve: Curves.easeInOut),
    );
    _slowBarController.repeat(reverse: true);
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isRunning) { t.cancel(); return; }
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        _finishPhase();
      }
    });
  }

  void _finishPhase() {
    setState(() {
      _phase = 3;
      _isRunning = false;
    });
    _fastBarController.stop();
    _slowBarController.stop();
    _timer?.cancel();
  }

  void _emergencyStop() {
    _isRunning = false;
    _timer?.cancel();
    _fastBarController.stop();
    _slowBarController.stop();
    HapticFeedback.heavyImpact();
    _showCrossedLimitDialog();
  }

  void _showCrossedLimitDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('⚠️ Cruzaste el Límite', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Si eyaculaste o estuviste a punto, no te preocupes. Es parte del entrenamiento. Ajustaremos tus tiempos para mañana.', style: TextStyle(color: Colors.white70)),
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
    if (successful) { 
      widget.user.registerSuccessfulSession(3); 
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
    _isRunning = false;
    _timer?.cancel();
    _fastBarController.dispose();
    _slowBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhase1 = _phase == 1;
    final bool isPhase2 = _phase == 2;
    final Color mainColor = isPhase1 ? const Color(0xFFE94560) : (isPhase2 ? const Color(0xFF00E676) : const Color(0xFF00B4D8));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A), 
        title: const Text('Módulo 3: Edging', style: TextStyle(color: Colors.white))
      ),
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
                  _introStep == 0 ? 'Es la técnica de mantenerse en el borde del orgasmo (Nivel 7-8) sin cruzar al punto de no retorno. A diferencia del Start-Stop, aquí no paras por completo, sino que regulas la intensidad.' 
                  : _introStep == 1 ? 'Primero subirás al Nivel 7 con ritmo normal. Luego, la barra se volverá LENTA: debes bajar la intensidad de tu mano y mantenerte en la meseta respirando profundo.' 
                  : _introStep == 2 ? 'Fase 1: ${_phase1Duration}s de estimulación normal (subir al Nivel 7). Fase 2: ${_phase2Duration}s en meseta (ritmo lento, mantener el control).' 
                  : 'El Edging es la técnica más poderosa para curar la eyaculación precoz. Enseña a tu cerebro que la alta excitación no es una emergencia.',
                  style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5), textAlign: TextAlign.center,
                )),
              ])),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (index) => Container(margin: const EdgeInsets.symmetric(horizontal: 4), width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: index == _introStep ? const Color(0xFF00E676) : Colors.grey[800])))),
              const SizedBox(height: 40),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _nextIntroStep, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), padding: const EdgeInsets.symmetric(vertical: 18)), child: Text(_introStep == 3 ? 'COMENZAR ENTRENAMIENTO' : 'SIGUIENTE', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
              const SizedBox(height: 20),
            ],

            if (_phase == 1 || _phase == 2) ...[
              // Indicador de fase
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: mainColor, width: 1),
                ),
                child: Text(
                  isPhase1 ? 'FASE 1: SUBIDA AL NIVEL 7' : 'FASE 2: MESETA (Ritmo Lento)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mainColor),
                ),
              ),
              const SizedBox(height: 10),
              Text('Tiempo restante', style: const TextStyle(fontSize: 14, color: Colors.white54)),
              const SizedBox(height: 5),
              
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black, 
                    borderRadius: BorderRadius.circular(15), 
                    border: Border.all(color: mainColor.withOpacity(0.3), width: 2)
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Stack(
                      children: [
                        // Imagen de fondo
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/1793847033003.jpg',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                        // Zonas de color superpuestas
                        Positioned.fill(
                          child: CustomPaint(painter: EdgingZonesPainter(isPhase2: isPhase2)),
                        ),
                        // Barra animada
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _barAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: BarOnlyPainter(
                                  isStimulating: true,
                                  barProgress: _barAnimation.value,
                                  mainColor: mainColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              Text(
                isPhase1 ? 'ESTIMULACIÓN NORMAL (Sigue el ritmo rápido)' : 'MESETA (Baja intensidad, respira)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: mainColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text('$_timeRemaining s', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              if (isPhase1) 
                SizedBox(
                  width: double.infinity, 
                  child: ElevatedButton(
                    onPressed: _emergencyStop, 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.symmetric(vertical: 15)), 
                    child: const Text('¡ALTO! (Si cruzas el Nivel 7 antes de tiempo)', style: TextStyle(fontSize: 16, color: Colors.white))
                  )
                ),
            ],
            
            if (_phase == 3) ...[
              const Spacer(),
              const Icon(Icons.check_circle, size: 80, color: Color(0xFF00E676)),
              const SizedBox(height: 20),
              const Text('¡Meseta Completada!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              const Text('Has entrenado el control en la zona de alta excitación.', style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: () => _finishSession(successful: true), 
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), padding: const EdgeInsets.symmetric(vertical: 18)), 
                  child: const Text('✅ MANTUVE EL CONTROL EN LA MESETA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                )
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: () => _finishSession(successful: false), 
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), padding: const EdgeInsets.symmetric(vertical: 18)), 
                  child: const Text('❌ CRUCÉ EL LÍMITE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                )
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}

// Pintor de las zonas de color (Azul, Verde, Roja) sobre la imagen
class EdgingZonesPainter extends CustomPainter {
  final bool isPhase2;

  EdgingZonesPainter({required this.isPhase2});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Zona inferior (segura/azul) - 0% a 60%
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.60, w, h * 0.40),
      Paint()..color = const Color(0xFF00B4D8).withOpacity(0.15),
    );

    // Zona media (meseta/verde) - 60% a 85%
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.25, w, h * 0.35),
      Paint()..color = const Color(0xFF00E676).withOpacity(isPhase2 ? 0.35 : 0.15),
    );

    // Zona superior (peligro/roja) - 85% a 100%
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.25),
      Paint()..color = const Color(0xFFE94560).withOpacity(0.20),
    );

    // Líneas separadoras
    final Paint linePaint = Paint()..color = Colors.white.withOpacity(0.2)..strokeWidth = 1;
    canvas.drawLine(Offset(0, h * 0.60), Offset(w, h * 0.60), linePaint);
    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), linePaint);

    // Etiquetas
    final TextPainter tp1 = TextPainter(
      text: TextSpan(text: 'ZONA VERDE (MESETA)', style: TextStyle(color: const Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, Offset(w / 2 - tp1.width / 2, h * 0.27));

    final TextPainter tp2 = TextPainter(
      text: TextSpan(text: 'PELIGRO', style: TextStyle(color: const Color(0xFFE94560), fontSize: 10, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(w / 2 - tp2.width / 2, h * 0.02));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Pintor de la barra animada (igual que Módulo 2)
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

      canvas.drawLine(
        Offset(cx - 45, barY + 2), 
        Offset(cx + 45, barY + 2), 
        Paint()..color = Colors.black.withOpacity(0.6)..strokeWidth = 8..strokeCap = StrokeCap.round
      );

      final Paint barPaint = Paint()..color = mainColor..strokeWidth = 6..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - 45, barY), Offset(cx + 45, barY), barPaint);

      final Paint handlePaint = Paint()..color = mainColor;
      canvas.drawCircle(Offset(cx - 45, barY), 9, handlePaint);
      canvas.drawCircle(Offset(cx + 45, barY), 9, handlePaint);
      canvas.drawCircle(Offset(cx, barY), 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
