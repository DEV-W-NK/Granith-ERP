import 'package:project_granith/core/data/db_value.dart';

class JobRoleModel {
  final String id;
  final String title;
  final String sector;
  final String description;
  final List<String> requirements;
  final bool isActive;
  final DateTime createdAt;

  JobRoleModel({
    required this.id,
    required this.title,
    required this.sector,
    this.description = '',
    this.requirements = const [],
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'sector': sector,
    'description': description,
    'requirements': requirements,
    'isActive': isActive,
    'createdAt': DbValue.toPrimitive(createdAt),
  };

  factory JobRoleModel.fromMap(Map<String, dynamic> map, String docId) =>
      JobRoleModel(
        id: docId,
        title: map['title'] ?? '',
        sector: map['sector'] ?? '',
        description: map['description'] ?? '',
        requirements: List<String>.from(map['requirements'] ?? []),
        isActive: map['isActive'] ?? true,
        createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      );

  JobRoleModel copyWith({
    String? title,
    String? sector,
    String? description,
    List<String>? requirements,
    bool? isActive,
  }) => JobRoleModel(
    id: id,
    title: title ?? this.title,
    sector: sector ?? this.sector,
    description: description ?? this.description,
    requirements: requirements ?? this.requirements,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}
