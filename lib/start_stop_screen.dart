import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'user_model.dart';

class StartStopScreen extends StatefulWidget {
  final Isar isar;
  final User user;
  const StartStopScreen({super.key, required this.isar, required this.user});

  @override
  State<StartStopScreen> createState() => _StartStopScreenState();
}

class _StartStopScreenState extends State<StartStopScreen> {
  int _currentLevel = 1; 
  int _cyclesCompleted = 0;
  final int _targetCycles = 3;
  bool _isStimulating = true; 

  void _changeLevel(int delta) {
    setState(() {
      _currentLevel = (_currentLevel + delta).clamp(1, 10);
    });
  }

  void _togglePhase() {
    if (_isStimulating) {
      if (_currentLevel >= 8) {
        _showWarningDialog();
      } else {
        setState(() => _isStimulating = false);
        HapticFeedback.mediumImpact();
      }
    } else {
      setState(() {
        _isStimulating = true;
        _currentLevel = 1;
        _cyclesCompleted++;
      });
      HapticFeedback.lightImpact();
      
      if (_cyclesCompleted >= _targetCycles) {
        _showValidationDialog();
      }
    }
  }

  void _showWarningDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('⚠️ Pasaste el Punto de No Retorno', style: TextStyle(color: Colors.redAccent)),
        content: const Text('Clínicamente, el Nivel 8 es el punto de no retorno. El objetivo es parar en el Nivel 7. Baja la excitación respirando.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); setState(() => _currentLevel = 7); },
            child: const Text('Entendido, bajar a 7', style: TextStyle(color: Color(0xFF00B4D8))),
          ),
        ],
      ),
    );
  }

  void _showValidationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('¿Lograste controlar el reflejo?', style: TextStyle(color: Colors.white)),
        content: const Text('Sé honesto. ¿Pudiste detenerte en el Nivel 7 sin cruzar al 8?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _finishSession(successful: false); },
            child: const Text('No, me pasé', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); _finishSession(successful: true); },
            child: const Text('Sí, tuve control', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _finishSession({required bool successful}) async {
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

  String _getAgeInstruction() {
    if (widget.user.ageGroup == 'young_adult') return "Sube rápido, pero detente en seco al llegar a 7. Tu sistema nervioso responde rápido.";
    if (widget.user.ageGroup == 'adult') return "Sincroniza la subida con tu respiración. Al llegar a 7, exhala largo y relaja el suelo pélvico.";
    if (widget.user.ageGroup == 'mature') return "Sube muy suave. Prioriza la relajación. Si sientes tensión, baja al nivel 4 inmediatamente.";
    return "Sigue las instrucciones generales.";
  }

  @override
  Widget build(BuildContext context) {
    Color levelColor = _currentLevel <= 6 ? const Color(0xFF00B4D8) : (_currentLevel == 7 ? const Color(0xFFFF9800) : const Color(0xFFE94560));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Módulo 2: Start-Stop', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Ciclo $_cyclesCompleted de $_targetCycles', style: const TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 20),
            Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: levelColor.withOpacity(0.3), width: 2)),
              child: CustomPaint(painter: NervousSystemPainter(excitationLevel: _currentLevel)),
            ),
            const SizedBox(height: 20),
            Text('Nivel de Excitación Actual', style: TextStyle(fontSize: 16, color: levelColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline, size: 40, color: Color(0xFF00B4D8)), onPressed: () => _changeLevel(-1)),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: levelColor.withOpacity(0.2), border: Border.all(color: levelColor, width: 3)),
                  child: Center(child: Text('$_currentLevel', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: levelColor))),
                ),
                IconButton(icon: const Icon(Icons.add_circle_outline, size: 40, color: Color(0xFFE94560)), onPressed: () => _changeLevel(1)),
              ],
            ),
            const SizedBox(height: 10),
            Text(_currentLevel <= 6 ? 'Zona Segura' : (_currentLevel == 7 ? '⚠️ PUNTO CLAVE (PARA AQUÍ)' : '🚨 ZONA DE NO RETORNO'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: levelColor)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _togglePhase,
                style: ElevatedButton.styleFrom(backgroundColor: _isStimulating ? const Color(0xFFE94560) : const Color(0xFF00B4D8), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(_isStimulating ? 'PARAR Y RELAJAR' : 'SIGUIENTE CICLO', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(10), border: Border(left: BorderSide(color: const Color(0xFF00B4D8), width: 4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🧠 INSTRUCCIÓN CLÍNICA:", style: TextStyle(fontSize: 12, color: Color(0xFF00B4D8), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(_getAgeInstruction(), style: const TextStyle(fontSize: 14, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NervousSystemPainter extends CustomPainter {
  final int excitationLevel;
  NervousSystemPainter({required this.excitationLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    final Paint bgPaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    Color nerveColor = const Color(0xFF00B4D8);
    if (excitationLevel >= 7) nerveColor = const Color(0xFFFF9800);
    if (excitationLevel >= 8) nerveColor = const Color(0xFFE94560);

    final Paint nervePaint = Paint()..color = nerveColor..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, h * 0.15), 20, Paint()..color = nerveColor.withOpacity(0.5));
    canvas.drawCircle(Offset(cx, h * 0.15), 20, nervePaint..strokeWidth = 2);
    canvas.drawLine(Offset(cx, h * 0.15), Offset(cx, h * 0.85), nervePaint);

    final Path pelvisNerves = Path()
      ..moveTo(cx, h * 0.5)
      ..quadraticBezierTo(cx - 40, h * 0.7, cx - 30, h * 0.85)
      ..moveTo(cx, h * 0.5)
      ..quadraticBezierTo(cx + 40, h * 0.7, cx + 30, h * 0.85);
    canvas.drawPath(pelvisNerves, nervePaint);

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, h * 0.85), width: 60, height: 40), Paint()..color = nerveColor.withOpacity(0.3));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, h * 0.85), width: 60, height: 40), nervePaint..strokeWidth = 2);

    _drawLabel(canvas, "Cerebro", cx, h * 0.05, nerveColor);
    _drawLabel(canvas, "Simpático", cx + 45, h * 0.5, nerveColor);
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, Color color) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
