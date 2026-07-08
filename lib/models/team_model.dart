import 'package:project_granith/core/data/db_value.dart';

class TeamModel {
  static const Object _unset = Object();

  final String id;
  final String name; // Ex: "Equipe Alfa"
  final String
  description; // Ex: "Equipe responsável pela obra do Residencial Alphaville"
  final List<String> memberIds; // IDs dos EmployeeModel
  final String? leaderId; // ID do líder (opcional)
  final String?
  projectId; // Equipe pode estar vinculada a um projeto (opcional)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamModel({
    required this.id,
    required this.name,
    this.description = '',
    this.memberIds = const [],
    this.leaderId,
    this.projectId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'memberIds': memberIds,
      'leaderId': leaderId,
      'projectId': projectId,
      'isActive': isActive,
      'createdAt': DbValue.toPrimitive(createdAt),
      'updatedAt': DbValue.toPrimitive(updatedAt),
    };
  }

  factory TeamModel.fromMap(Map<String, dynamic> map, String docId) {
    return TeamModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      leaderId: map['leaderId'] as String?,
      projectId: map['projectId'] as String?,
      isActive: map['isActive'] ?? true,
      createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: DbValue.toDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? memberIds,
    Object? leaderId = _unset,
    Object? projectId = _unset,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      memberIds: memberIds ?? this.memberIds,
      leaderId:
          identical(leaderId, _unset) ? this.leaderId : leaderId as String?,
      projectId:
          identical(projectId, _unset) ? this.projectId : projectId as String?,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
