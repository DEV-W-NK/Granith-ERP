import 'package:project_granith/core/data/db_value.dart';

class DailyLogModel {
  final String id;
  final String projectId;
  final String projectName;
  final DateTime date;
  final String weatherMorning;
  final String weatherAfternoon;
  final int manpower;
  final String activitiesDescription;
  final String impediments;
  final List<String> photoUrls;
  final String createdByUserId;
  final String status;

  DailyLogModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.date,
    required this.weatherMorning,
    required this.weatherAfternoon,
    required this.manpower,
    required this.activitiesDescription,
    required this.impediments,
    this.photoUrls = const [],
    required this.createdByUserId,
    this.status = 'pendente',
  });

  factory DailyLogModel.fromMap(Map<String, dynamic> data, String id) {
    return DailyLogModel(
      id: id,
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? '',
      date: DbValue.toDateTime(data['date']) ?? DateTime.now(),
      weatherMorning: data['weatherMorning'] ?? '',
      weatherAfternoon: data['weatherAfternoon'] ?? '',
      manpower: data['manpower'] ?? 0,
      activitiesDescription: data['activitiesDescription'] ?? '',
      impediments: data['impediments'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      createdByUserId: data['createdByUserId'] ?? '',
      status: data['status'] ?? 'pendente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'date': DbValue.toPrimitive(date),
      'weatherMorning': weatherMorning,
      'weatherAfternoon': weatherAfternoon,
      'manpower': manpower,
      'activitiesDescription': activitiesDescription,
      'impediments': impediments,
      'photoUrls': photoUrls,
      'createdByUserId': createdByUserId,
      'status': status,
    };
  }

  DailyLogModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    DateTime? date,
    String? weatherMorning,
    String? weatherAfternoon,
    int? manpower,
    String? activitiesDescription,
    String? impediments,
    List<String>? photoUrls,
    String? createdByUserId,
    String? status,
  }) {
    return DailyLogModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      date: date ?? this.date,
      weatherMorning: weatherMorning ?? this.weatherMorning,
      weatherAfternoon: weatherAfternoon ?? this.weatherAfternoon,
      manpower: manpower ?? this.manpower,
      activitiesDescription:
          activitiesDescription ?? this.activitiesDescription,
      impediments: impediments ?? this.impediments,
      photoUrls: photoUrls ?? this.photoUrls,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      status: status ?? this.status,
    );
  }
}
