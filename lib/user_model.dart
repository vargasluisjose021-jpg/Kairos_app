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
  int totalSessions = 0; // No nullable para evitar errores de ++
  DateTime? updatedAt;

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
  int? startStopLevel; // NUEVO: Nivel de dificultad dinámica (1 al 10)

  // ==========================================
  // 5. DATOS MÓDULO 3 (EDGING)
  // ==========================================
  int? edgingLevel; // NUEVO: Nivel de dificultad dinámica (1 al 10)

  // ==========================================
  // 6. MÉTODOS CLÍNICOS
  // ==========================================
  
  void configureByAge(int selectedAge) {
    age = selectedAge;
    // Configuración clínica base según edad si es necesaria
  }

  // Algoritmo de Adaptación Dinámica (Exposición Graduada)
  // Si el usuario tiene éxito, sube de nivel (máximo 10)
  void registerSuccessfulSession(int module) {
    totalSessions++;
    updatedAt = DateTime.now();

    if (module == 2) {
      startStopLevel = ((startStopLevel ?? 1) + 1).clamp(1, 10);
    } else if (module == 3) {
      edgingLevel = ((edgingLevel ?? 1) + 1).clamp(1, 10);
    }
  }

  // Si el usuario falla, baja de nivel para evitar ansiedad de desempeño
  void registerFailedSession(int module) {
    totalSessions++;
    updatedAt = DateTime.now();

    if (module == 2) {
      startStopLevel = ((startStopLevel ?? 1) - 1).clamp(1, 10);
    } else if (module == 3) {
      edgingLevel = ((edgingLevel ?? 1) - 1).clamp(1, 10);
    }
  }
}
