import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  
  int? age;
  int? totalSessions;
  DateTime? updatedAt;
  
  // Niveles de dificultad clínica (Algoritmo de Adaptación Dinámica)
  int? edgingLevel;
  int? startStopLevel;

  // Método clínico: Registra el éxito y sube automáticamente el nivel de dificultad
  void registerSuccessfulSession(int module) {
    totalSessions = (totalSessions ?? 0) + 1;
    updatedAt = DateTime.now();
    
    // Si el usuario completa el módulo, su cerebro está listo para el siguiente nivel
    if (module == 2) {
      startStopLevel = (startStopLevel ?? 1) + 1;
    } else if (module == 3) {
      edgingLevel = (edgingLevel ?? 1) + 1;
    }
  }
}
