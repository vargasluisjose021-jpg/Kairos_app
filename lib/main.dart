import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'user_model.dart';
import 'onboarding_screen.dart';
import 'training_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  await Isar.initializeIsarCore(download: true);
  final isar = await Isar.open([UserSchema], directory: dir.path);
  runApp(KairosApp(isar: isar));
}

class KairosApp extends StatelessWidget {
  final Isar isar;
  const KairosApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kairos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1929),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B4D8),
          brightness: Brightness.dark,
        ),
      ),
      home: HomeScreen(isar: isar),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Isar isar;
  const HomeScreen({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1929),
              Color(0xFF0D2845),
              Color(0xFF1A3A5C),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ilustración Anatómica Clínica del Aparato Reproductor Masculino
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF00B4D8),
                      Color(0xFF0077B6),
                      Color(0xFF03045E),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00B4D8).withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: MaleReproductivePainter(),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'KAIROS',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Color(0xFF00B4D8),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Control Clínico Masculino',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF90E0EF),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: () async {
                  final existingUser = await isar.users.where().findFirst();
                  
                  if (existingUser == null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OnboardingScreen(isar: isar)),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TrainingMenu(isar: isar, user: existingUser)),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow, size: 24),
                label: const Text(
                  'Iniciar Entrenamiento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF00B4D8).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ilustración Anatómica Clínica del Aparato Reproductor Masculino
class MaleReproductivePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    // Colores clínicos (estilo radiografía médica)
    final Color tissueColor = const Color(0xFFCAF0F8).withOpacity(0.9);
    final Color accentColor = const Color(0xFF00B4D8);
    final Color darkAccent = const Color(0xFF0077B6);

    // 1. Vejiga (parte superior)
    final Paint bladderPaint = Paint()
      ..color = tissueColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 40), width: 70, height: 50),
      bladderPaint,
    );
    final Paint bladderOutline = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - 40), width: 70, height: 50),
      bladderOutline,
    );

    // 2. Próstata (debajo de la vejiga)
    final Paint prostatePaint = Paint()
      ..color = darkAccent.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 45, height: 30),
      prostatePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 5), width: 45, height: 30),
      bladderOutline,
    );

    // 3. Conductos deferentes (arcos laterales)
    final Paint ductPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Conducto izquierdo
    final Path leftDuct = Path()
      ..moveTo(cx - 15, cy - 20)
      ..quadraticBezierTo(cx - 50, cy + 10, cx - 35, cy + 50);
    canvas.drawPath(leftDuct, ductPaint);
    
    // Conducto derecho
    final Path rightDuct = Path()
      ..moveTo(cx + 15, cy - 20)
      ..quadraticBezierTo(cx + 50, cy + 10, cx + 35, cy + 50);
    canvas.drawPath(rightDuct, ductPaint);

    // 4. Vesículas seminales (pequeñas estructuras arriba)
    final Paint vesiclePaint = Paint()
      ..color = tissueColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 30, cy - 15), width: 18, height: 25),
      vesiclePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 30, cy - 15), width: 18, height: 25),
      vesiclePaint,
    );

    // 5. Testículos (abajo)
    final Paint testiclePaint = Paint()
      ..color = tissueColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 25, cy + 60), width: 35, height: 40),
      testiclePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 25, cy + 60), width: 35, height: 40),
      testiclePaint,
    );
    
    // Contorno de testículos
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 25, cy + 60), width: 35, height: 40),
      bladderOutline,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 25, cy + 60), width: 35, height: 40),
      bladderOutline,
    );

    // 6. Epidídimo (pequeña estructura sobre cada testículo)
    final Paint epididymisPaint = Paint()
      ..color = darkAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 25, cy + 45), width: 25, height: 15),
      3.14, 3.14, false,
      epididymisPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 25, cy + 45), width: 25, height: 15),
      3.14, 3.14, false,
      epididymisPaint,
    );

    // Etiquetas clínicas pequeñas
    _drawLabel(canvas, "Vejiga", cx, cy - 65, accentColor, 10);
    _drawLabel(canvas, "Próstata", cx, cy + 25, accentColor, 9);
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, Color color, double fontSize) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
