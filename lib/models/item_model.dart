import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final String unit; // ex: un, kg, m, m², l
  
  // Dados para Frete (Opcionais)
  final double? weight; // em kg
  final double? width;  // em cm
  final double? height; // em cm
  final double? length; // em cm
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    this.description = '',
    required this.unit,
    this.weight,
    this.width,
    this.height,
    this.length,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromMap(Map<String, dynamic> map, String id) {
    return Item(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      unit: map['unit'] ?? 'un',
      weight: (map['weight'] as num?)?.toDouble(),
      width: (map['width'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      length: (map['length'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'unit': unit,
      'weight': weight,
      'width': width,
      'height': height,
      'length': length,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Item copyWith({
    String? id,
    String? name,
    String? description,
    String? unit,
    double? weight,
    double? width,
    double? height,
    double? length,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      weight: weight ?? this.weight,
      width: width ?? this.width,
      height: height ?? this.height,
      length: length ?? this.length,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}