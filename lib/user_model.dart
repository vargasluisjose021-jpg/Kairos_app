import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  
  // Datos del Onboarding
  String gender = 'male';
  int age = 25; 
  String frequency = '';
  List<String> devices = [];
  double controlLevel = 5.0;
  List<String> goals = [];
  
  DateTime createdAt = DateTime.now();
  DateTime? updatedAt;

  // --- CLASIFICACIÓN CLÍNICA POR EDAD ---
  String ageGroup = 'adult';
  int kegelHoldTime = 5;
  int kegelReps = 10;
  bool allowEdging = true;
  String clinicalWarning = '';

  // --- TEST MELT (Línea Base) ---
  int baselineMeltSeconds = 0; // Tiempo real medido hasta la eyaculación
  int trainingRhythmSeconds = 45; // Tiempo de estimulación calculado (ej. 50-60% del MELT)
  bool hasCompletedBaseline = false;
  DateTime? lastBaselineDate;

  // --- PROGRESO POR MÓDULO ---
  int module1SessionsCompleted = 0;
  int module1CurrentLevel = 1;
  DateTime? module1LastSessionDate;
  
  int module2SessionsCompleted = 0;
  int module2CurrentLevel = 1;
  DateTime? module2LastSessionDate;
  
  int module3SessionsCompleted = 0;
  int module3CurrentLevel = 1;
  DateTime? module3LastSessionDate;
  
  int module4SessionsCompleted = 0;
  int module4CurrentLevel = 1;
  DateTime? module4LastSessionDate;

  // --- ESTADÍSTICAS GENERALES ---
  int totalSessions = 0;
  int successfulSessions = 0;
  int streakDays = 0;
  DateTime? lastSessionDate;
  
  // --- TELEMETRÍA ---
  int restingHeartRate = 65; // BPM en reposo (para comparar el pico)
  int lastSessionHeartRatePeak = 0;
  bool lastSessionMovementDetected = false;

  // --- MÉTODOS CLÍNICOS ---
  
  void configureByAge(int userAge) {
    age = userAge;
    if (userAge < 18) {
      ageGroup = 'young';
      kegelHoldTime = 3;
      kegelReps = 6;
      allowEdging = false;
      clinicalWarning = 'Sistema nervioso en desarrollo. Ejercicios suaves. No hacer Edging.';
    } else if (userAge <= 30) {
      ageGroup = 'young_adult';
      kegelHoldTime = 5;
      kegelReps = 10;
      allowEdging = true;
      clinicalWarning = '';
    } else if (userAge <= 50) {
      ageGroup = 'adult';
      kegelHoldTime = 8;
      kegelReps = 12;
      allowEdging = true;
      clinicalWarning = '';
    } else if (userAge <= 65) {
      ageGroup = 'mature';
      kegelHoldTime = 6;
      kegelReps = 10;
      allowEdging = true;
      clinicalWarning = 'Enfoque en relajación pélvica. Calentamiento obligatorio.';
    } else {
      ageGroup = 'senior';
      kegelHoldTime = 4;
      kegelReps = 8;
      allowEdging = false;
      clinicalWarning = '⚠️ Consulte a su urólogo antes de iniciar. Evite el Edging.';
    }
    updatedAt = DateTime.now();
  }

  // Calcula el ritmo de entrenamiento basado en el MELT real
  void calculateTrainingRhythm(int meltSeconds, int peakBpm) {
    baselineMeltSeconds = meltSeconds;
    restingHeartRate = peakBpm - 30; // Estimación simple del reposo si no se midió antes
    
    // Regla clínica: El tiempo de entrenamiento inicial debe ser el 50-60% del MELT real
    // para garantizar el éxito y evitar la frustración, con un mínimo de 30s y máximo de 120s.
    int calculatedRhythm = (meltSeconds * 0.6).round();
    trainingRhythmSeconds = calculatedRhythm.clamp(30, 120);
    
    hasCompletedBaseline = true;
    lastBaselineDate = DateTime.now();
    updatedAt = DateTime.now();
  }

  bool isModuleUnlocked(int moduleNumber) {
    return true; // Todos desbloqueados para rutina integral diaria
  }

  void registerSuccessfulSession(int moduleNumber) {
    totalSessions++;
    successfulSessions++;
    
    if (moduleNumber == 1) {
      module1SessionsCompleted++;
      module1LastSessionDate = DateTime.now();
      if (module1SessionsCompleted % 7 == 0) module1CurrentLevel++;
    } else if (moduleNumber == 2) {
      module2SessionsCompleted++;
      module2LastSessionDate = DateTime.now();
      if (module2SessionsCompleted % 7 == 0) module2CurrentLevel++;
    } else if (moduleNumber == 3) {
      module3SessionsCompleted++;
      module3LastSessionDate = DateTime.now();
      if (module3SessionsCompleted % 7 == 0) module3CurrentLevel++;
    } else if (moduleNumber == 4) {
      module4SessionsCompleted++;
      module4LastSessionDate = DateTime.now();
      if (module4SessionsCompleted % 7 == 0) module4CurrentLevel++;
    }
    
    lastSessionDate = DateTime.now();
    _updateStreak();
    updatedAt = DateTime.now();
  }

  void _updateStreak() {
    if (lastSessionDate == null) {
      streakDays = 1;
      return;
    }
    final now = DateTime.now();
    final difference = now.difference(lastSessionDate!).inDays;
    
    if (difference == 0) {
      // Mismo día
    } else if (difference == 1) {
      streakDays++;
    } else {
      streakDays = 1;
    }
  }
}
