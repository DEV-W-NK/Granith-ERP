import 'package:project_granith/core/data/db_value.dart';

enum WeatherCondition { sol, nublado, chuvoso, tempestade }

enum LogStatus { draft, finalized, pendingSignature, signed, synced }

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

  // Fotos (URLs do Supabase Storage)
  final List<String> photoUrls;

  final String createdByUserId;
  final LogStatus status;
  final String? coordinatorId;
  final String? coordinatorName;
  final DateTime? signatureRequestedAt;
  final DateTime? signedAt;
  final String? signedByCoordinatorId;
  final String? signedByCoordinatorName;

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
    this.coordinatorId,
    this.coordinatorName,
    this.signatureRequestedAt,
    this.signedAt,
    this.signedByCoordinatorId,
    this.signedByCoordinatorName,
  });

  bool get hasCoordinator =>
      coordinatorId != null && coordinatorId!.trim().isNotEmpty;

  bool get isPendingSignature =>
      status == LogStatus.pendingSignature && signedAt == null;

  bool get isSigned => status == LogStatus.signed || signedAt != null;

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'date': DbValue.toPrimitive(date),
      'weatherMorning': weatherMorning.name,
      'weatherAfternoon': weatherAfternoon.name,
      'manpower': manpower,
      'activitiesDescription': activitiesDescription,
      'impediments': impediments,
      'photoUrls': photoUrls,
      'createdByUserId': createdByUserId,
      'status': status.name,
      'coordinatorId': coordinatorId,
      'coordinatorName': coordinatorName,
      'signatureRequestedAt':
          signatureRequestedAt != null
              ? DbValue.toPrimitive(signatureRequestedAt!)
              : null,
      'signedAt': signedAt != null ? DbValue.toPrimitive(signedAt!) : null,
      'signedByCoordinatorId': signedByCoordinatorId,
      'signedByCoordinatorName': signedByCoordinatorName,
    };
  }

  factory DailyLogModel.fromMap(Map<String, dynamic> map, String docId) {
    return DailyLogModel(
      id: docId,
      projectId: map['projectId'] ?? '',
      projectName: map['projectName'] ?? 'Projeto Desconhecido',
      date: DbValue.toDateTime(map['date']) ?? DateTime.now(),
      weatherMorning: WeatherCondition.values.firstWhere(
        (e) => e.name == map['weatherMorning'],
        orElse: () => WeatherCondition.sol,
      ),
      weatherAfternoon: WeatherCondition.values.firstWhere(
        (e) => e.name == map['weatherAfternoon'],
        orElse: () => WeatherCondition.sol,
      ),
      manpower: Map<String, int>.from(map['manpower'] ?? {}),
      activitiesDescription: map['activitiesDescription'] ?? '',
      impediments: map['impediments'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      createdByUserId: map['createdByUserId'] ?? '',
      status: _statusFrom(map['status']),
      coordinatorId: _nullableText(map['coordinatorId']),
      coordinatorName: _nullableText(map['coordinatorName']),
      signatureRequestedAt: DbValue.toDateTime(map['signatureRequestedAt']),
      signedAt: DbValue.toDateTime(map['signedAt']),
      signedByCoordinatorId: _nullableText(map['signedByCoordinatorId']),
      signedByCoordinatorName: _nullableText(map['signedByCoordinatorName']),
    );
  }

  DailyLogModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    DateTime? date,
    WeatherCondition? weatherMorning,
    WeatherCondition? weatherAfternoon,
    Map<String, int>? manpower,
    String? activitiesDescription,
    String? impediments,
    List<String>? photoUrls,
    String? createdByUserId,
    LogStatus? status,
    String? coordinatorId,
    String? coordinatorName,
    DateTime? signatureRequestedAt,
    DateTime? signedAt,
    String? signedByCoordinatorId,
    String? signedByCoordinatorName,
  }) {
    return DailyLogModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      date: date ?? this.date,
      weatherMorning: weatherMorning ?? this.weatherMorning,
      weatherAfternoon: weatherAfternoon ?? this.weatherAfternoon,
      manpower: manpower ?? Map<String, int>.from(this.manpower),
      activitiesDescription:
          activitiesDescription ?? this.activitiesDescription,
      impediments: impediments ?? this.impediments,
      photoUrls: photoUrls ?? List<String>.from(this.photoUrls),
      createdByUserId: createdByUserId ?? this.createdByUserId,
      status: status ?? this.status,
      coordinatorId: coordinatorId ?? this.coordinatorId,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      signatureRequestedAt: signatureRequestedAt ?? this.signatureRequestedAt,
      signedAt: signedAt ?? this.signedAt,
      signedByCoordinatorId:
          signedByCoordinatorId ?? this.signedByCoordinatorId,
      signedByCoordinatorName:
          signedByCoordinatorName ?? this.signedByCoordinatorName,
    );
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static LogStatus _statusFrom(dynamic value) {
    final raw = value?.toString();
    if (raw == 'pendente') return LogStatus.pendingSignature;
    return LogStatus.values.firstWhere(
      (status) => status.name == raw,
      orElse: () => LogStatus.draft,
    );
  }
}
