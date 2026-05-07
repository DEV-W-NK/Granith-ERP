import 'package:project_granith/core/data/db_value.dart';

class BenefitCategoryModel {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BenefitCategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'isActive': isActive,
    'createdAt': DbValue.toPrimitive(createdAt),
    'updatedAt': DbValue.toPrimitive(updatedAt),
  };

  factory BenefitCategoryModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) => BenefitCategoryModel(
    id: docId,
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    isActive: map['isActive'] ?? true,
    createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
    updatedAt: DbValue.toDateTime(map['updatedAt']) ?? DateTime.now(),
  );

  BenefitCategoryModel copyWith({
    String? name,
    String? description,
    bool? isActive,
    DateTime? updatedAt,
  }) => BenefitCategoryModel(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
