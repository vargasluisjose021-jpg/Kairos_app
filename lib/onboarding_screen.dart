import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'user_model.dart';
import 'training_menu.dart';

class OnboardingScreen extends StatefulWidget {
  final Isar isar;
  const OnboardingScreen({super.key, required this.isar});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  int _selectedAge = 25;
  String _selectedFrequency = 'Ocasional';
  final List<String> _frequencies = ['Ocasional', '1-2 veces por semana', '3+ veces por semana'];

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final user = User()
      ..gender = 'male'
      ..age = _selectedAge
      ..frequency = _selectedFrequency;
    
    // Aplicar configuración clínica basada en la edad
    user.configureByAge(_selectedAge);

    await widget.isar.writeTxn(() => widget.isar.users.put(user));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TrainingMenu(isar: widget.isar, user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1929),
        title: const Text('Evaluación Clínica Inicial', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de progreso
            Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: index <= _currentStep ? const Color(0xFF00B4D8) : Colors.grey[800],
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),

            // PASO 1: Edad
            if (_currentStep == 0) ...[
              const Text(
                '¿Cuál es tu edad?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Esta información es crucial para ajustar los tiempos y la intensidad de los ejercicios a tu fisiología.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 30),
              
              // Selector de edad
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF00B4D8), width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Color(0xFF00B4D8), size: 32),
                          onPressed: () {
                            if (_selectedAge > 14) setState(() => _selectedAge--);
                          },
                        ),
                        Text(
                          '$_selectedAge años',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF00B4D8), size: 32),
                          onPressed: () {
                            if (_selectedAge < 100) setState(() => _selectedAge++);
                          },
                        ),
                      ],
                    ),
                    if (_selectedAge < 18) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Aviso clínico: Tu sistema nervioso aún se está desarrollando. Los ejercicios se ajustarán a un nivel suave y seguro. No se incluirán técnicas de alta intensidad.',
                                style: TextStyle(color: Colors.orange, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_selectedAge > 60) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Aviso clínico: Se recomienda priorizar la relajación pélvica. Si tienes antecedentes de prostatitis o cirugía, consulta a tu urólogo antes de iniciar.',
                                style: TextStyle(color: Colors.orange, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // PASO 2: Frecuencia actual
            if (_currentStep == 1) ...[
              const Text(
                '¿Con qué frecuencia tienes actividad sexual o masturbación?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Esto nos ayuda a establecer una línea base para tu entrenamiento.',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 30),
              
              Column(
                children: _frequencies.map((freq) {
                  final isSelected = _selectedFrequency == freq;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFrequency = freq),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00B4D8).withOpacity(0.2) : Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00B4D8) : Colors.grey[800]!,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? const Color(0xFF00B4D8) : Colors.grey[600],
                          ),
                          const SizedBox(width: 15),
                          Text(freq, style: const TextStyle(fontSize: 18, color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // PASO 3: Consentimiento y Inicio
            if (_currentStep == 2) ...[
              const Text(
                'Consentimiento y Seguridad',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[800]!, width: 1),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Al continuar, confirmas que:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '• Eres mayor de 14 años.\n• Entiendes que esta app es una herramienta de entrenamiento y no sustituye el diagnóstico o tratamiento de un urólogo o fisioterapeuta.\n• Si experimentas dolor pélvico, detén los ejercicios y consulta a un médico.',
                      style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Botón de acción
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _currentStep == 2 ? 'Comenzar Entrenamiento Clínico' : 'Continuar',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
