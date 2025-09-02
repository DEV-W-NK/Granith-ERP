import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetType {
  final String id;
  final String name;
  final String description;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? iconName;
  final String? color;

  const BudgetType({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.iconName,
    this.color,
  });

  factory BudgetType.fromMap(Map<String, dynamic> map, String id) {
    return BudgetType(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      iconName: map['iconName'],
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'iconName': iconName,
      'color': color,
    };
  }

  BudgetType copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? iconName,
    String? color,
  }) {
    return BudgetType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BudgetType(id: $id, name: $name, category: $category, isActive: $isActive)';
  }
}