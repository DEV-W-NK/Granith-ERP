import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory DailyLogModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DailyLogModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
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

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'date': Timestamp.fromDate(date),
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
      activitiesDescription: activitiesDescription ?? this.activitiesDescription,
      impediments: impediments ?? this.impediments,
      photoUrls: photoUrls ?? this.photoUrls,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      status: status ?? this.status,
    );
  }
}