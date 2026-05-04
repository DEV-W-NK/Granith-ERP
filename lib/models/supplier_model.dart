import 'package:project_granith/core/data/db_value.dart';

class Supplier {
  final String id;
  final String name;
  final String cnpj;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Supplier({
    required this.id,
    required this.name,
    required this.cnpj,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    // Trata datas vindas de diferentes fontes.
    DateTime parseDate(dynamic value) {
      return DbValue.toDateTime(value) ?? DateTime.now();
    }

    return Supplier(
      id: json['id'] as String? ?? '', // Garante string vazia se nulo
      name: json['name'] as String? ?? '',
      cnpj: json['cnpj'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      // Usa a função auxiliar para ler as datas corretamente
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cnpj': cnpj,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Supplier copyWith({
    String? id,
    String? name,
    String? cnpj,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Supplier && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Supplier(id: $id, name: $name, cnpj: $cnpj, isActive: $isActive)';
  }

  // Helper methods
  String get formattedCnpj {
    if (cnpj.length != 14) return cnpj;

    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
  }

  bool get isValidCnpj {
    return cnpj.length == 14 && RegExp(r'^\d{14}$').hasMatch(cnpj);
  }
}
