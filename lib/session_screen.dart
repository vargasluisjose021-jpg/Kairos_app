import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with SingleTickerProviderStateMixin {
  double _arousalLevel = 1;
  late AnimationController _pulseController;
  String _instruction = "Comienza con un ritmo lento y relajado.";
  Color _zoneColor = const Color(0xFF4A90E2); // Azul calmante

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updateSessionState(double level) {
    setState(() {
      _arousalLevel = level;
      
      // Lógica de colores e instrucciones según el nivel anatómico
      if (level < 4) {
        _zoneColor = const Color(0xFF4A90E2); // Azul
        _instruction = "Nivel Bajo: Relaja el diafragma. Respira profundo.";
        _pulseController.duration = const Duration(seconds: 3); // Pulso lento
      } else if (level < 7) {
        _zoneColor = const Color(0xFFF5A623); // Naranja
        _instruction = "Nivel Medio: Activa el Core. Mantén el ritmo.";
        _pulseController.duration = const Duration(milliseconds: 1500); // CORREGIDO: 1.5 segundos
      } else if (level < 9) {
        _zoneColor = const Color(0xFFD0021B); // Rojo
        _instruction = "AL BORDE: Prepara el Suelo Pélvico. ¡Frena la mano!";
        _pulseController.duration = const Duration(milliseconds: 800); // Pulso rápido
        HapticFeedback.mediumImpact();
      } else {
        _zoneColor = const Color(0xFF8B0000); // Rojo oscuro
        _instruction = "¡PUNTO DE NO RETORNO! DETÉN LA MANO. Contrae fuerte.";
        _pulseController.stop();
        HapticFeedback.heavyImpact(); // Vibración fuerte de alerta
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Sesión de Control', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Indicador de Nivel y Texto de Instrucción
            Text(
              'Nivel: ${_arousalLevel.toInt()}/10',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _zoneColor),
            ),
            const SizedBox(height: 10),
            Text(
              _instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 30),

            // Visualizador Anatómico Clínico (Torso y Pelvis)
            Expanded(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  double scale = 1.0 + (_pulseController.value * 0.1);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAnatomicalZone('Diafragma', 'Respiración', 0.6),
                    const SizedBox(height: 15),
                    _buildAnatomicalZone('Core', 'Tensión Abdominal', 0.8),
                    const SizedBox(height: 15),
                    _buildAnatomicalZone('Suelo Pélvico', 'Contracción', 1.0),
                  ],
                ),
              ),
            ),

            // Slider de Control
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _zoneColor,
                inactiveTrackColor: Colors.grey[800],
                thumbColor: Colors.white,
                overlayColor: _zoneColor.withOpacity(0.2),
              ),
              child: Slider(
                value: _arousalLevel,
                min: 1,
                max: 10,
                divisions: 9,
                label: '${_arousalLevel.toInt()}',
                onChanged: _updateSessionState,
              ),
            ),

            // Botón de Pánico / Reset
            ElevatedButton.icon(
              onPressed: () {
                _updateSessionState(1);
                HapticFeedback.lightImpact();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reiniciar Ciclo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para dibujar las zonas anatómicas
  Widget _buildAnatomicalZone(String name, String function, double intensity) {
    bool isActive = _arousalLevel >= (intensity * 10) - 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isActive ? _zoneColor.withOpacity(0.3) : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isActive ? _zoneColor : Colors.grey[800]!,
          width: isActive ? 3 : 1,
        ),
        boxShadow: isActive 
          ? [BoxShadow(color: _zoneColor.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)] 
          : [],
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isActive ? _zoneColor : Colors.white70)),
          const SizedBox(height: 5),
          Text(function, style: const TextStyle(fontSize: 14, color: Colors.white54)),
        ],
      ),
    );
  }
}
