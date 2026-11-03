import 'package:flutter/material.dart';

// Ilustración: Corte Sagital de la Pelvis Masculina (Vista lateral interna)
class SagittalPelvisPainter extends CustomPainter {
  final bool isContracting; // Para animar el músculo PC

  SagittalPelvisPainter({required this.isContracting});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Fondo (Tejido base)
    final Paint bgPaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Vejiga (Arriba)
    final Paint bladderPaint = Paint()..color = const Color(0xFF4A90E2).withOpacity(0.6);
    final Path bladderPath = Path()
      ..moveTo(w * 0.3, h * 0.1)
      ..quadraticBezierTo(w * 0.1, h * 0.3, w * 0.3, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.5, w * 0.5, h * 0.3)
      ..quadraticBezierTo(w * 0.5, h * 0.1, w * 0.3, h * 0.1);
    canvas.drawPath(bladderPath, bladderPaint);
    
    // Etiqueta Vejiga
    _drawLabel(canvas, "Vejiga", w * 0.35, h * 0.25, const Color(0xFF4A90E2));

    // 3. Recto (Atrás/Abajo)
    final Paint rectumPaint = Paint()..color = const Color(0xFF8B4513).withOpacity(0.6);
    final Path rectumPath = Path()
      ..moveTo(w * 0.7, h * 0.4)
      ..quadraticBezierTo(w * 0.9, h * 0.6, w * 0.8, h * 0.9)
      ..lineTo(w * 0.6, h * 0.9)
      ..quadraticBezierTo(w * 0.7, h * 0.6, w * 0.5, h * 0.4);
    canvas.drawPath(rectumPath, rectumPaint);

    // Etiqueta Recto
    _drawLabel(canvas, "Recto", w * 0.75, h * 0.7, const Color(0xFF8B4513));

    // 4. Músculo Pubococcígeo (PC) - EL PROTAGONISTA
    final Paint pcPaint = Paint()
      ..color = isContracting ? const Color(0xFF00E676) : const Color(0xFFD0021B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isContracting ? 8 : 4;
    
    final Path pcPath = Path()
      ..moveTo(w * 0.3, h * 0.5) // Cerca de la vejiga
      ..quadraticBezierTo(w * 0.5, h * 0.65, w * 0.7, h * 0.4); // Arco hacia el recto
    
    canvas.drawPath(pcPath, pcPaint);
    
    // Etiqueta Músculo PC
    _drawLabel(canvas, "Músculo PC", w * 0.5, h * 0.55, isContracting ? const Color(0xFF00E676) : const Color(0xFFD0021B));

    // 5. Próstata (Debajo de la vejiga)
    final Paint prostatePaint = Paint()..color = const Color(0xFFFF9800).withOpacity(0.7);
    canvas.drawCircle(Offset(w * 0.45, h * 0.55), w * 0.08, prostatePaint);
    _drawLabel(canvas, "Próstata", w * 0.45, h * 0.65, const Color(0xFFFF9800));
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
