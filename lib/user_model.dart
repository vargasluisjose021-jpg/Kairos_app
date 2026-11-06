import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;

  // ==========================================
  // 1. DATOS DEL ONBOARDING
  // ==========================================
  int? age;
  String? gender;
  String? frequency;

  // ==========================================
  // 2. DATOS DE PROGRESO GENERAL
  // ==========================================
  int totalSessions = 0;
  DateTime? updatedAt;
  
  // NUEVO: Datos para la pantalla de estadísticas
  int? baselineMelt;       // Tiempo MELT inicial (para comparar evolución)
  int? streakDays;         // Racha de días consecutivos entrenando
  DateTime? lastSessionDate; // Fecha de la última sesión (para calcular la racha)

  // ==========================================
  // 3. DATOS MÓDULO 1 (SUELO PÉLVICO)
  // ==========================================
  int kegelHoldTime = 5; 
  int kegelReps = 10;    
  int module1SessionsCompleted = 0;

  // ==========================================
  // 4. DATOS MÓDULO 2 (START-STOP)
  // ==========================================
  int trainingRhythmStimulateSeconds = 60; 
  int trainingRhythmRestSeconds = 30;      
  int? startStopLevel; 

  // ==========================================
  // 5. DATOS MÓDULO 3 (EDGING)
  // ==========================================
  int? edgingLevel; 

  // ==========================================
  // 6. MÉTODOS CLÍNICOS
  // ==========================================
  
  void configureByAge(int selectedAge) {
    age = selectedAge;
    // Asignar MELT base según edad si no se hizo el test
    if (baselineMelt == null) {
      if (age >= 14 && age <= 17) baselineMelt = 120;
      else if (age >= 18 && age <= 30) baselineMelt = 180;
      else if (age >= 31 && age <= 50) baselineMelt = 300;
      else baselineMelt = 360;
    }
  }

  void registerSuccessfulSession(int module) {
    totalSessions++;
    updatedAt = DateTime.now();
    
    // Lógica de racha clínica
    final today = DateTime.now();
    if (lastSessionDate != null) {
      final difference = today.difference(lastSessionDate!).inDays;
      if (difference == 1) {
        streakDays = (streakDays ?? 0) + 1; // Suma un día si es consecutivo
      } else if (difference > 1) {
        streakDays = 1; // Reinicia la racha si pasó más de un día
      }
    } else {
      streakDays = 1; // Primera sesión
    }
    lastSessionDate = today;

    if (module == 2) {
      startStopLevel = ((startStopLevel ?? 1) + 1).clamp(1, 10);
    } else if (module == 3) {
      edgingLevel = ((edgingLevel ?? 1) + 1).clamp(1, 10);
    }
  }

  void registerFailedSession(int module) {
    totalSessions++;
    updatedAt = DateTime.now();
    
    // La racha se mantiene si entrena aunque falle, pero no sube de nivel
    final today = DateTime.now();
    if (lastSessionDate != null) {
      final difference = today.difference(lastSessionDate!).inDays;
      if (difference == 1) {
        streakDays = (streakDays ?? 0) + 1; 
      } else if (difference > 1) {
        streakDays = 1; 
      }
    } else {
      streakDays = 1;
    }
    lastSessionDate = today;

    if (module == 2) {
      startStopLevel = ((startStopLevel ?? 1) - 1).clamp(1, 10);
    } else if (module == 3) {
      edgingLevel = ((edgingLevel ?? 1) - 1).clamp(1, 10);
    }
  }
}
