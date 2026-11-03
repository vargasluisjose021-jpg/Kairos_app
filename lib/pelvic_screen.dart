import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import 'user_model.dart';

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
  
  List<double> _movementHistory = [];
  bool _movementDetected = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _startRealAccelerometer();
    _startExercise();
  }

  void _startRealAccelerometer() {
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      double movement = (magnitude - 9.8).abs();
      
      setState(() {
        _movementHistory.add(movement);
        if (_movementHistory.length > 50) _movementHistory.removeAt(0);
        
        double avgMovement = _movementHistory.isEmpty ? 0 : _movementHistory.reduce((a, b) => a + b) / _movementHistory.length;
        _movementDetected = avgMovement > 0.5;
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
        _showValidationDialog();
        return;
      }
      _isContracting = true;
      _secondsRemaining = 5;
      HapticFeedback.mediumImpact();
    }
  }

  void _showValidationDialog() {
    _timer?.cancel();
    _accelSubscription?.cancel();
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF00E676), size: 28),
              SizedBox(width: 10),
              Text('Sesión Completada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Completaste el ejercicio correctamente hoy?',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 15),
              Text(
                'Sé honesto contigo mismo. Esto ayuda a la app a ajustar tu entrenamiento de forma precisa.',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _finishSession(false);
              },
              child: const Text('No lo hice bien', style: TextStyle(color: Colors.orange)),
            ),
            ElevatedButton(
              onPressed: () {
                _finishSession(true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676)),
              child: const Text('Sí, lo hice bien', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _finishSession(bool wasSuccessful) async {
    Navigator.pop(context); // Cerrar el diálogo
    
    // Actualizar base de datos
    widget.user.totalSessions++;
    
    if (wasSuccessful) {
      widget.user.successfulSessions++;
      widget.user.streakDays++;
      // Aumentar dificultad un 10% para mañana
      widget.user.baseTimeSeconds = (widget.user.baseTimeSeconds * 1.1).toInt();
    } else {
      // Si no lo hizo bien, NO aumenta la racha ni la dificultad
      // Se mantiene en el mismo nivel para mañana
    }
    
    widget.user.last
