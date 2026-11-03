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

  // --- NUEVO: Programa Clínico y Progresión ---
  int currentModule = 1; // 1: Suelo Pélvico, 2: Start-Stop, 3: Edging, 4: Control Total
  int userLevel = 1;     // 1: Principiante, 2: Intermedio, 3: Avanzado
  int baseTimeSeconds = 60; 
  int totalSessions = 0;
  int successfulSessions = 0;
  int streakDays = 0;
  DateTime? lastSessionDate;

  // --- NUEVO: Telemetría y Anti-Trampas ---
  int lastSessionHeartRatePeak = 0; // Pico de ritmo cardíaco
  bool lastSessionMovementDetected = false; // Si el acelerómetro detectó movimiento
}
