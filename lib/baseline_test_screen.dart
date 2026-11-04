import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:isar/isar.dart';
import 'dart:async';
import 'dart:math';
import 'user_model.dart';
import 'training_menu.dart';

class BaselineTestScreen extends StatefulWidget {
  final Isar isar;
  final User user;
  const BaselineTestScreen({super.key, required this.isar, required this.user});

  @override
  State<BaselineTestScreen> createState() => _BaselineTestScreenState();
}

class _BaselineTestScreenState extends State<BaselineTestScreen> {
  int _phase = 0; // 0: Intro, 1: Medir Reposo, 2: Cronómetro, 3: Medir Post, 4: Resultados
  int _restingHR = 0;
  int _peakHR = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isValidTest = true;
  String _validationMessage = '';

  // Variables PPG
  CameraController? _cameraController;
  bool _isMeasuringHR = false;
  List<double> _ppgSignal = [];
  List<int> _peakTimes = [];
  int _currentTempHR = 0;
  Timer? _hrTimer;
  int _hrSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _hrTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (_cameraController != null) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final backCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
      _cameraController = CameraController(backCamera, ResolutionPreset.low, enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.torch);
      _cameraController!.startImageStream((image) {
        if (_isMeasuringHR) _analyzeFrame(image);
      });
    } catch (e) { print(e); }
  }

  void _analyzeFrame(CameraImage image) {
    double redSum = 0; int pixelCount = 0;
    final plane = image.planes.first; final bytes = plane.bytes;
    final width = image.width; final height = image.height;
    final centerX = width ~/ 2; final centerY = height ~/ 2; final radius = 40;
    
    for (int y = centerY - radius; y < centerY + radius; y++) {
      for (int x = centerX - radius; x < centerX + radius; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final index = y * width + x;
          if (index < bytes.length) { redSum += bytes[index]; pixelCount++; }
        }
      }
    }
    if (pixelCount > 0) {
      setState(() {
        _ppgSignal.add(redSum / pixelCount);
        if (_ppgSignal.length > 100) _ppgSignal.removeAt(0);
      });
    }
  }

  void _startHRMeasurement(bool isResting) {
    setState(() {
      _isMeasuringHR = true;
      _currentTempHR = 0;
      _ppgSignal.clear();
      _peakTimes.clear();
      _hrSeconds = 0;
    });
    _hrTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_hrSeconds >= 10) { // 10 segundos de medición
        t.cancel();
        _finishHRMeasurement(isResting);
      } else {
        setState(() => _hrSeconds++);
        if (_hrSeconds % 3 == 0 && _ppgSignal.length > 20) _calculateTempHR();
      }
    });
  }

  void _calculateTempHR() {
    _peakTimes.clear();
    for (int i = 1; i < _ppgSignal.length - 1; i++) {
      if (_ppgSignal[i] > _ppgSignal[i - 1] && _ppgSignal[i] > _ppgSignal[i + 1]) {
        if (_peakTimes.isEmpty || i - _peakTimes.last > 8) _peakTimes.add(i);
      }
    }
    if (_peakTimes.length >= 2) {
      final avgInterval = (_peakTimes.last - _peakTimes.first) / (_peakTimes.length - 1);
      final bpm = (10 / avgInterval * 60).round();
      if (bpm >= 40 && bpm <= 200) setState(() => _currentTempHR = bpm);
    }
  }

  void _finishHRMeasurement(bool isResting) {
    setState(() => _isMeasuringHR = false);
    if (isResting) {
      _restingHR = _currentTempHR > 0 ? _currentTempHR : 70; // Fallback
      setState(() => _phase = 2);
    } else {
      _peakHR = _currentTempHR > 0 ? _currentTempHR : _restingHR + 20;
      _validateAndFinish();
    }
  }

  void _startTest() {
    setState(() {
      _phase = 2;
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _finishTest() {
    _timer?.cancel();
    setState(() => _phase = 3);
  }

  void _validateAndFinish() async {
    _isValidTest = _peakHR > _restingHR + 10;
    _validationMessage = _isValidTest 
        ? 'Prueba válida. Se detectó elevación fisiológica.' 
        : '⚠️ Alerta: No se detectó elevación cardíaca significativa. La prueba podría no ser precisa.';

    if (_isValidTest) {
      widget.user.calculateTrainingRhythm(_elapsedSeconds, _peakHR);
    } else {
      widget.user.baselineMeltSeconds = _elapsedSeconds;
      widget.user.baselineHeartRatePeak = _peakHR;
      widget.user.calculateTrainingRhythm(_elapsedSeconds, _peakHR); // Calcula igual, pero con advertencia
    }
    await widget.isar.writeTxn(() => widget.isar.users.put(widget.user));
    setState(() => _phase = 4);
  }

  Widget _buildPPGView(String title) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 20),
        Container(
          height: 200, width: 200,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black, border: Border.all(color: const Color(0xFF00B4D8), width: 3)),
          child: _cameraController != null ? ClipOval(child: CameraPreview(_cameraController!)) : const CircularProgressIndicator(),
        ),
        const SizedBox(height: 20),
        const Text('Coloca tu dedo índice sobre la cámara', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 10),
        Text('Pulso actual: $_currentTempHR BPM', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _currentTempHR > 0 ? const Color(0xFF00E676) : Colors.white)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isMeasuringHR ? null : () => _startHRMeasurement(_phase == 1),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
          child: Text(_isMeasuringHR ? 'Midiendo... $_hrSeconds/10s' : 'Iniciar Medición (10s)'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(backgroundColor: const Color(0xFF0A1929), title: const Text('Prueba de Línea Base (MELT)', style: TextStyle(color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_phase == 0) ...[
                  const Icon(Icons.timer, size: 80, color: Color(0xFF00B4D8)),
                  const SizedBox(height: 20),
                  const Text('Prueba de Tiempo de Latencia', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  const Text('Vamos a medir tu tiempo real de excitación para crear tu plan de entrenamiento personalizado.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 30),
                  ElevatedButton(onPressed: () async { await _initCamera(); setState(() => _phase = 1); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)), child: const Text('Comenzar Prueba', style: TextStyle(fontSize: 18))),
                ],
                if (_phase == 1) _buildPPGView('Fase 1: Mide tu pulso en REPOSO'),
                if (_phase == 2) ...[
                  const Text('Fase 2: La Prueba', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 30),
                  Text('${_elapsedSeconds ~/ 60}:${(_elapsedSeconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Color(0xFF00B4D8))),
                  const SizedBox(height: 40),
                  ElevatedButton(onPressed: _finishTest, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)), child: const Text('TERMINÉ (EYACULÉ)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                ],
                if (_phase == 3) _buildPPGView('Fase 3: Mide tu pulso POST-EJERCICIO'),
                if (_phase == 4) ...[
                  Icon(_isValidTest ? Icons.check_circle : Icons.warning_amber, size: 80, color: _isValidTest ? const Color(0xFF00E676) : Colors.orange),
                  const SizedBox(height: 20),
                  Text(_isValidTest ? '¡Prueba Completada!' : 'Prueba con observaciones', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(_validationMessage, textAlign: TextAlign.center, style: TextStyle(color: _isValidTest ? Colors.white70 : Colors.orange)),
                  const SizedBox(height: 20),
                  Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(10)), child: Column(children: [
                    Text('Tiempo registrado: ${_elapsedSeconds}s', style: const TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text('Tu nuevo ritmo de entrenamiento:', style: const TextStyle(color: Color(0xFF00B4D8), fontWeight: FontWeight.bold)),
                    Text('${widget.user.trainingRhythmStimulateSeconds}s estimulación / ${widget.user.trainingRhythmRestSeconds}s descanso', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ])),
                  const SizedBox(height: 30),
                  ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => TrainingMenu(isar: widget.isar, user: widget.user))), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)), child: const Text('Ir al Dashboard', style: TextStyle(fontSize: 18))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
