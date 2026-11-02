import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;
  
  String gender = '';
  int age = 25;
  String frequency = '';
  List<String> devices = [];
  double controlLevel = 5.0;
  List<String> goals = [];
  
  DateTime createdAt = DateTime.now();
  DateTime? updatedAt;

  // Campos para el Algoritmo Adaptativo
  int userLevel = 1; // 1: Principiante, 2: Intermedio, 3: Avanzado
  int baseTimeSeconds = 60; // Tiempo base de estimulación en segundos
  int totalSessions = 0;
  int successfulSessions = 0;
}
