import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:isar/isar.dart';
import 'dart:async';
import 'dart:math';
import 'user_model.dart';

class PPGCalibrationScreen extends StatefulWidget {
  final Isar isar;
  final User user;
  const PPGCalibrationScreen({super.key, required this.isar, required this.user});

  @override
  State<PPGCalibrationScreen> createState() => _PPGCalibrationScreenState();
}

class _PPGCalibrationScreenState extends State<PPGCalibrationScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isMeasuring = false;
  bool _hasPermission = false;
  
  int _currentBPM = 0;
  List<double> _ppgSignal = [];
  List<int> _peakTimes = [];
  Timer? _analysisTimer;
  int _measurementSeconds = 0;
  final int _measurementDuration = 15; // 15 segundos de medición
  
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseScale = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
    
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status == PermissionStatus.granted;
    });
    
    if (_hasPermission) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final backCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back);
      
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.torch); // Encender flash
      
      setState(() {
        _isCameraInitialized = true;
      });
      
      // Iniciar lectura de frames
      _cameraController!.startImageStream((CameraImage image) {
        if (_isMeasuring) {
          _analyzeFrame(image);
        }
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _analyzeFrame(CameraImage image) {
    // Calcular el color rojo promedio en el centro de la imagen
    double redSum = 0;
    int pixelCount = 0;
    
    // Analizar solo el canal Y (luminancia) para simplicidad
    final plane = image.planes.first;
    final bytes = plane.bytes;
    final width = image.width;
    final height = image.height;
    
    // Analizar el centro de la imagen (donde está el dedo)
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;
    final radius = 50;
    
    for (int y = centerY - radius; y < centerY + radius; y++) {
      for (int x = centerX - radius; x < centerX + radius; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final index = y * width + x;
          if (index < bytes.length) {
            redSum += bytes[index];
            pixelCount++;
          }
        }
      }
    }
    
    if (pixelCount > 0) {
      final avgRed = redSum / pixelCount;
      
      setState(() {
        _ppgSignal.add(avgRed);
        if (_ppgSignal.length > 100) _ppgSignal.removeAt(0);
      });
    }
  }

  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _measurementSeconds = 0;
      _ppgSignal.clear();
      _peakTimes.clear();
      _currentBPM = 0;
    });
    
    // Timer para contar los segundos de medición
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_measurementSeconds >= _measurementDuration) {
        timer.cancel();
        _finishMeasurement();
        return;
      }
      
      setState(() {
        _measurementSeconds++;
      });
      
      // Calcular BPM cada 3 segundos
      if (_measurementSeconds % 3 == 0 && _ppgSignal.length > 20) {
        _calculateBPM();
      }
    });
  }

  void _calculateBPM() {
    if (_ppgSignal.length < 20) return;
    
    // Detectar picos en la señal PPG
    _peakTimes.clear();
    
    for (int i = 1; i < _ppgSignal.length - 1; i++) {
      if (_ppgSignal[i] > _ppgSignal[i - 1] && _ppgSignal[i] > _ppgSignal[i + 1]) {
        // Es un pico
        if (_peakTimes.isEmpty || i - _peakTimes.last > 10) { // Mínimo 10 frames entre picos
          _peakTimes.add(i);
        }
      }
    }
    
    // Calcular BPM basado en los picos
    if (_peakTimes.length >= 2) {
      final avgInterval = (_peakTimes.last - _peakTimes.first) / (_peakTimes.length - 1);
      // Asumiendo 10 frames por segundo (aproximado)
      final beatsPerSecond = 10 / avgInterval;
      final bpm = (beatsPerSecond * 60).round();
      
      // Filtrar valores fuera de rango (30-200 BPM)
      if (bpm >= 30 && bpm <= 200) {
        setState(() {
          _currentBPM = bpm;
        });
      }
    }
  }

  void _finishMeasurement() async {
    setState(() {
      _isMeasuring = false;
    });
    
    // Actualizar base de datos con el BPM real
    widget.user.lastSessionHeartRatePeak = _currentBPM;
    widget.user.updatedAt = DateTime.now();
    
    await widget.isar.writeTxn(() => widget.isar.users.put(widget.user));
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pulso registrado: $_currentBPM BPM'),
        backgroundColor: const Color(0xFF00E676),
        duration: const Duration(seconds: 2),
      ),
    );
    
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _analysisTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Calibración de Pulso', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (!_hasPermission)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
                      const SizedBox(height: 20),
                      const Text(
                        'Necesitamos permiso de cámara para medir tu pulso',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _requestCameraPermission,
                        child: const Text('Dar Permiso'),
                      ),
                    ],
                  ),
                ),
              )
            else if (!_isCameraInitialized)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Vista de la cámara
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF00E676), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _cameraController != null
                              ? CameraPreview(_cameraController!)
                              : const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Instrucciones
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF00E676), width: 1),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.fingerprint, color: Color(0xFF00E676), size: 40),
                            SizedBox(height: 10),
                            Text(
                              'COLOCA TU DEDO SOBRE LA CÁMARA',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Cubre completamente el lente con la yema de tu dedo índice. El flash se encenderá automáticamente.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Monitor de Pulso
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF00E676), width: 2),
                        ),
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isMeasuring ? _pulseScale.value : 1.0,
                                  child: child,
                                );
                              },
                              child: const Icon(Icons.favorite, color: Color(0xFF00E676), size: 60),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _currentBPM > 0 ? '$_currentBPM BPM' : '-- BPM',
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _isMeasuring ? 'Midiendo... $_measurementSeconds/$_measurementDuration s' : 'Listo para medir',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Gráfica de señal PPG
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomPaint(
                          painter: PPGWavePainter(signal: _ppgSignal),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Señal PPG en tiempo real',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                      const SizedBox(height: 20),

                      // Botón de medición
                      ElevatedButton.icon(
                        onPressed: _isMeasuring ? null : _startMeasurement,
                        icon: Icon(_isMeasuring ? Icons.hourglass_empty : Icons.monitor_heart),
                        label: Text(_isMeasuring ? 'Midiendo...' : 'Iniciar Medición'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Painter para la señal PPG
class PPGWavePainter extends CustomPainter {
  final List<double> signal;

  PPGWavePainter({required this.signal});

  @override
  void paint(Canvas canvas, Size size) {
    if (signal.isEmpty) return;

    final Paint paint = Paint()
      ..color = const Color(0xFF00E676)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    // Normalizar la señal
    final minVal = signal.reduce(min);
    final maxVal = signal.reduce(max);
    final range = maxVal - minVal;

    double xStep = size.width / (signal.length - 1);

    for (int i = 0; i < signal.length; i++) {
      double x = i * xStep;
      double normalized = range > 0 ? (signal[i] - minVal) / range : 0.5;
      double y = size.height - (normalized * size.height);

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
