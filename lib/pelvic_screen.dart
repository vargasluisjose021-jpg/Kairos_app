import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import 'user_model.dart';
import 'anatomy_painter.dart';

class PelvicScreen extends StatefulWidget {
  final Isar isar;
  final User user;
  const PelvicScreen({super.key, required this.isar, required this.user});

  @override
  State<PelvicScreen> createState() => _PelvicScreenState();
}

class _PelvicScreenState extends State<PelvicScreen> with TickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _timer;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  int _secondsRemaining = 0;
  bool _isContracting = true; 
  int _repsCompleted = 0;
  final int _targetReps = 10;
  
  // Telemetría: Acelerómetro REAL
  double _lastAccelValue = 0.0;
  List<double> _movementHistory = [];
  bool _movementDetected = false;
  int _movementCount = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _startRealAccelerometer();
    _startExercise();
  }

  void _startRealAccelerometer() {
    // Leer el acelerómetro REAL del celular
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      // Calcular la magnitud del vector de aceleración
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // Normalizar (la gravedad es ~9.8, restamos para ver solo el movimiento)
      double movement = (magnitude - 9.8).abs();
      
      setState(() {
        _lastAccelValue = movement;
        _movementHistory.add(movement);
        if (_movementHistory.length > 50) _movementHistory.removeAt(0);
        
        // Detectar si hay movimiento significativo (umbral: 0.5 m/s²)
        double avgMovement = _movementHistory.reduce((a, b) => a + b) / _movementHistory.length;
        _movementDetected = avgMovement > 0.5;
        if (_movementDetected) _movementCount++;
      });
    });
  }

  void _startExercise() {
    _isContracting = true;
    _secondsRemaining = 5; 
    _repsCompleted = 0;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _switchPhase();
        }
      });
    });
  }

  void _switchPhase() {
    if (_isContracting) {
      _isContracting = false;
      _secondsRemaining = 5;
      HapticFeedback.lightImpact();
    } else {
      _repsCompleted++;
      if (_repsCompleted >= _targetReps) {
        _finishSession();
        return;
      }
      _isContracting = true;
      _secondsRemaining = 5;
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelSubscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    _accelSubscription?.cancel();
    HapticFeedback.heavyImpact();
    
    // Validar si la sesión fue real (al menos 50 detecciones de movimiento)
    bool sessionValid = _movementCount > 50;
    
    // Actualizar base de datos
    widget.user.totalSessions++;
    if (sessionValid) {
      widget.user.successfulSessions++;
      widget.user.streakDays++;
    }
    widget.user.lastSessionDate = DateTime.now();
    widget.user.lastSessionHeartRatePeak = 85 + (_repsCompleted * 2); // Simulado por ahora
    widget.user.lastSessionMovementDetected = sessionValid;
    widget.user.updatedAt = DateTime.now();
    
    await widget.isar.writeTxn(() => widget.isar.users.put(widget.user));
    
    if (!mounted) return;
    
    String message = sessionValid 
        ? '¡Módulo 1 Completado! Sesión validada biométricamente.'
        : 'Sesión sospechosa: No se detectó suficiente movimiento. Inténtalo de nuevo.';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: sessionValid ? const Color(0xFF00E676) : const Color(0xFFFF9800),
        duration: const Duration(seconds: 3),
      ),
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor = _isContracting ? const Color(0xFF00E676) : const Color(0xFF4A90E2);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Módulo 1: Suelo Pélvico', style: TextStyle(color: Colors.white)),
        actions: [
          // Indicador de telemetría REAL
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _movementDetected ? const Color(0xFF00E676) : Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.sensors, color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Text(
                  _movementDetected ? 'ACTIVO' : 'QUIETO',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Repetición ${_repsCompleted + 1} de $_targetReps', style: const TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 20),

            // ILUSTRACIÓN ANATÓMICA CLÍNICA
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: mainColor.withOpacity(0.3), width: 2),
              ),
              child: CustomPaint(
                painter: SagittalPelvisPainter(isContracting: _isContracting),
              ),
            ),
            const SizedBox(height: 20),

            // ESPEJO DE DATOS: Onda de Movimiento REAL
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _movementDetected ? const Color(0xFF00E676) : Colors.grey[800]!, width: 1),
              ),
              child: CustomPaint(
                painter: MovementWavePainter(movementHistory: _movementHistory, color: _movementDetected ? const Color(0xFF00E676) : Colors.grey[600]!),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _movementDetected ? '✓ Movimiento detectado' : '⚠ No detecto movimiento físico',
              style: TextStyle(fontSize: 12, color: _movementDetected ? const Color(0xFF00E676) : Colors.orange),
            ),
            const SizedBox(height: 15),

            // INSTRUCCIÓN MÉDICA PRINCIPAL
            Text(
              _isContracting ? "¡CONTRAE EL MÚSCULO PC!" : "KEGEL INVERSO: RELAJA",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: mainColor),
            ),
            const SizedBox(height: 10),
            Text(
              '$_secondsRemaining s',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // GUÍA CLÍNICA DETALLADA
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[900], 
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: mainColor, width: 4))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isContracting 
                      ? "🎯 CÓMO HACERLO: Aprieta el músculo como si detuvieras el flujo de orina a mitad del camino. Siente la tensión entre el escroto y el ano." 
                      : "🎯 CÓMO HACERLO: Inhala profundo por la nariz. Empuja suavemente hacia afuera el suelo pélvico (como si fueras a orinar). Siente cómo se expande.",
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 5),
                  const Text("⚠️ ERRORES CLÍNICOS A EVITAR:", style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(
                    _isContracting 
                      ? "• NO contraigas glúteos, muslos o abdomen.\n• NO aguantes la respiración.\n• NO empujes hacia abajo." 
                      : "• NO hagas fuerza abdominal.\n• NO levantes la pelvis.\n• NO es un empuje fuerte, debe ser sutil.",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Painter para la onda de movimiento REAL
class MovementWavePainter extends CustomPainter {
  final List<double> movementHistory;
  final Color color;

  MovementWavePainter({required this.movementHistory, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    
    if (movementHistory.isEmpty) return;

    double xStep = size.width / (movementHistory.length - 1);
    
    for (int i = 0; i < movementHistory.length; i++) {
      double x = i * xStep;
      // Escalar el movimiento para que se vea bien en la pantalla
      double y = size.height - (movementHistory[i] * size.height * 2).clamp(0.0, size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
