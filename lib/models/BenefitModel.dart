import 'package:cloud_firestore/cloud_firestore.dart';

enum BenefitType { vt, vr, health, dental, lifeInsurance, other }

class BenefitModel {
  final String id;
  final String name;        // "Vale Transporte", "Vale Refeição"...
  final BenefitType type;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  BenefitModel({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
  });

  String get typeLabel => switch (type) {
        BenefitType.vt           => 'Vale Transporte',
        BenefitType.vr           => 'Vale Refeição',
        BenefitType.health       => 'Plano de Saúde',
        BenefitType.dental       => 'Plano Odontológico',
        BenefitType.lifeInsurance=> 'Seguro de Vida',
        BenefitType.other        => 'Outro',
      };

  Map<String, dynamic> toMap() => {
        'name':        name,
        'type':        type.name,
        'description': description,
        'isActive':    isActive,
        'createdAt':   Timestamp.fromDate(createdAt),
      };

  factory BenefitModel.fromMap(Map<String, dynamic> map, String docId) =>
      BenefitModel(
        id:          docId,
        name:        map['name'] ?? '',
        type:        BenefitType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => BenefitType.other,
        ),
        description: map['description'] ?? '',
        isActive:    map['isActive'] ?? true,
        createdAt:   (map['createdAt'] as Timestamp).toDate(),
      );

  BenefitModel copyWith({
    String? name,
    BenefitType? type,
    String? description,
    bool? isActive,
  }) =>
      BenefitModel(
        id:          id,
        name:        name ?? this.name,
        type:        type ?? this.type,
        description: description ?? this.description,
        isActive:    isActive ?? this.isActive,
        createdAt:   createdAt,
      );
}