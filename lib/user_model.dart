import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  
  // Datos del Onboarding
  String gender = '';
  int age = 25;
  String frequency = '';
  List<String> devices = [];
  double controlLevel = 5.0;
  List<String> goals = [];
  
  DateTime createdAt = DateTime.now();
  DateTime? updatedAt;

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
  int lastSessionHeartRatePeak = 0;
  bool lastSessionMovementDetected = false;

  // --- MÉTODOS ---
  
  bool isModuleUnlocked(int moduleNumber) {
    if (moduleNumber == 1) return true;
    if (moduleNumber == 2) return module1SessionsCompleted >= 7;
    if (moduleNumber == 3) return module2SessionsCompleted >= 7;
    if (moduleNumber == 4) return module3SessionsCompleted >= 7;
    return false;
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
      // Mismo día, no cambia
    } else if (difference == 1) {
      streakDays++;
    } else {
      streakDays = 1;
    }
  }
}
