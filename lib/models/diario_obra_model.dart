import 'package:cloud_firestore/cloud_firestore.dart';

enum WeatherCondition { sol, nublado, chuvoso, tempestade }
enum LogStatus { draft, finalized, synced }

class DailyLogModel {
  final String id;
  final String projectId;
  final String projectName;
  final DateTime date;
  
  // Condições Climáticas
  final WeatherCondition weatherMorning;
  final WeatherCondition weatherAfternoon;
  
  // Mão de Obra e Atividades
  final Map<String, int> manpower;
  final String activitiesDescription;
  final String impediments;
  
  // Fotos (URLs do Firebase Storage)
  final List<String> photoUrls;
  
  final String createdByUserId;
  final LogStatus status;

  DailyLogModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.date,
    this.weatherMorning = WeatherCondition.sol,
    this.weatherAfternoon = WeatherCondition.sol,
    this.manpower = const {},
    required this.activitiesDescription,
    this.impediments = '',
    this.photoUrls = const [],
    required this.createdByUserId,
    this.status = LogStatus.draft,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'date': Timestamp.fromDate(date),
      'weatherMorning': weatherMorning.name,
      'weatherAfternoon': weatherAfternoon.name,
      'manpower': manpower,
      'activitiesDescription': activitiesDescription,
      'impediments': impediments,
      'photoUrls': photoUrls,
      'createdByUserId': createdByUserId,
      'status': status.name,
    };
  }

  factory DailyLogModel.fromMap(Map<String, dynamic> map, String docId) {
    return DailyLogModel(
      id: docId,
      projectId: map['projectId'] ?? '',
      projectName: map['projectName'] ?? 'Projeto Desconhecido',
      date: (map['date'] as Timestamp).toDate(),
      weatherMorning: WeatherCondition.values.firstWhere(
          (e) => e.name == map['weatherMorning'], orElse: () => WeatherCondition.sol),
      weatherAfternoon: WeatherCondition.values.firstWhere(
          (e) => e.name == map['weatherAfternoon'], orElse: () => WeatherCondition.sol),
      manpower: Map<String, int>.from(map['manpower'] ?? {}),
      activitiesDescription: map['activitiesDescription'] ?? '',
      impediments: map['impediments'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      createdByUserId: map['createdByUserId'] ?? '',
      status: LogStatus.values.firstWhere(
          (e) => e.name == map['status'], orElse: () => LogStatus.draft),
    );
  }
}