import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'user_model.dart';

class OnboardingScreen extends StatefulWidget {
  final Isar isar;
  
  const OnboardingScreen({super.key, required this.isar});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  String _gender = '';
  int _age = 25;
  String _frequency = '';
  List<String> _devices = [];
  double _controlLevel = 5;
  List<String> _goals = [];

  Future<void> _saveProfile() async {
    final user = User()
      ..gender = _gender
      ..age = _age
      ..frequency = _frequency
      ..devices = _devices
      ..controlLevel = _controlLevel
      ..goals = _goals
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    
    await widget.isar.writeTxn(() => widget.isar.users.put(user));
  }

  void _nextStep() {
    if (_currentStep == 0 && _gender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona tu género')),
      );
      return;
    }
    if (_currentStep == 2 && _frequency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una frecuencia')),
      );
      return;
    }
    if (_currentStep == 5 && _goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor elige al menos un objetivo')),
      );
      return;
    }

    if (_currentStep < 5) {
      setState(() => _currentStep++);
    } else {
      _saveProfile().then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Perfil guardado exitosamente')),
        );
        Navigator.pop(context);
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Kairos: Perfil', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / 6,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE94560)),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: _buildStepContent(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _prevStep,
                    child: const Text('Atrás', style: TextStyle(color: Colors.white70)),
                  )
                else
                  const SizedBox(),
                ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(_currentStep == 5 ? 'Finalizar' : 'Siguiente'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildGenderStep();
      case 1: return _buildAgeStep();
      case 2: return _buildFrequencyStep();
      case 3: return _buildDevicesStep();
      case 4: return _buildControlStep();
      case 5: return _buildGoalStep();
      default: return const SizedBox();
    }
  }

  Widget _buildGenderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Cuál es tu género?', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildOptionButton('Hombre', _gender == 'Hombre', () => setState(() => _gender = 'Hombre')),
        const SizedBox(height: 12),
        _buildOptionButton('Mujer', _gender == 'Mujer', () => setState(() => _gender = 'Mujer')),
        const SizedBox(height: 12),
        _buildOptionButton('Otro', _gender == 'Otro', () => setState(() => _gender = 'Otro')),
      ],
    );
  }

  Widget _buildAgeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Cuál es tu edad?', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Slider(
          value: _age.toDouble(),
          min: 18,
          max: 80,
          divisions: 62,
          activeColor: const Color(0xFFE94560),
          inactiveColor: Colors.grey[800],
          label: '$_age años',
          onChanged: (val) => setState(() => _age = val.toInt()),
        ),
        Center(child: Text('$_age años', style: const TextStyle(fontSize: 48, color: Color(0xFFE94560), fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildFrequencyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Con qué frecuencia practicas edging?', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildOptionButton('Nunca', _frequency == 'Nunca', () => setState(() => _frequency = 'Nunca')),
        const SizedBox(height: 12),
        _buildOptionButton('1-2 veces por semana', _frequency == '1-2 veces', () => setState(() => _frequency = '1-2 veces')),
        const SizedBox(height: 12),
        _buildOptionButton('3+ veces por semana', _frequency == '3+ veces', () => setState(() => _frequency = '3+ veces')),
      ],
    );
  }

  Widget _buildDevicesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Qué dispositivos usas?', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildCheckboxOption('Apple Watch', 'Apple Watch'),
        _buildCheckboxOption('Garmin', 'Garmin'),
        _buildCheckboxOption('Oura Ring', 'Oura Ring'),
        _buildCheckboxOption('Ninguno', 'Ninguno'),
      ],
    );
  }

  Widget _buildControlStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Qué nivel de control sientes que tienes hoy? (1-10)', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Slider(
          value: _controlLevel,
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: const Color(0xFFE94560),
          inactiveColor: Colors.grey[800],
          label: '${_controlLevel.toInt()}',
          onChanged: (val) => setState(() => _controlLevel = val),
        ),
        Center(child: Text('${_controlLevel.toInt()} / 10', style: const TextStyle(fontSize: 48, color: Color(0xFFE94560), fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('¿Cuál es tu objetivo principal?', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Puedes elegir varias opciones', style: TextStyle(fontSize: 14, color: Colors.white54)),
        const SizedBox(height: 24),
        _buildCheckboxOption('Aumentar duración', 'Duración'),
        _buildCheckboxOption('Mejor control corporal', 'Control'),
        _buildCheckboxOption('Conocimiento y datos', 'Datos'),
      ],
    );
  }

  Widget _buildOptionButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE94560) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFE94560) : Colors.grey[800]!),
        ),
        child: Text(text, style: TextStyle(fontSize: 18, color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildCheckboxOption(String text, String value) {
    return CheckboxListTile(
      title: Text(text, style: const TextStyle(color: Colors.white)),
      value: _devices.contains(value) || _goals.contains(value),
      activeColor: const Color(0xFFE94560),
      checkColor: Colors.white,
      onChanged: (bool? selected) {
        setState(() {
          if (selected == true) {
            if (!_devices.contains(value)) _devices.add(value);
            if (!_goals.contains(value)) _goals.add(value);
          } else {
            _devices.remove(value);
            _goals.remove(value);
          }
        });
      },
    );
  }
}
