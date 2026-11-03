import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'dart:async';
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
  int _secondsRemaining = 0;
  bool _isContracting = true; 
  int _repsCompleted = 0;
  final int _targetReps = 10;
  int _sessionStartTime = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    _startExercise();
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
    _animController.dispose();
    super.dispose();
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    
    // Actualizar base de datos con progreso y telemetría simulada
    widget.user.totalSessions++;
    widget.user.successfulSessions++;
    widget.user.streakDays++;
    widget.user.lastSessionDate = DateTime.now();
    widget.user.lastSessionHeartRatePeak = 85 + (_repsCompleted * 2); // Simulado
    widget.user.lastSessionMovementDetected = true; // Simulado
    widget.user.updatedAt = DateTime.now();
    
    await widget.isar.writeTxn(() => widget.isar.users.put(widget.user));
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Módulo 1 Completado! Músculo PC fortalecido.'),
        backgroundColor: Color(0xFF00E676),
        duration: Duration(seconds: 3),
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
