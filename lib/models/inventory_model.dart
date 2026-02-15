import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name; // Nome do produto/material
  final String unit; // Unidade (kg, un, m, etc)
  final double quantity; // Quantidade atual
  final double minQuantity; // Estoque mínimo (para alertas futuros)
  final DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.minQuantity = 0,
    required this.updatedAt,
  });

  // Factory para criar a partir do Firestore
  factory InventoryItem.fromMap(String id, Map<String, dynamic> data) {
    return InventoryItem(
      id: id,
      name: data['name'] ?? '',
      unit: data['unit'] ?? 'un',
      quantity: (data['quantity'] ?? 0).toDouble(),
      minQuantity: (data['minQuantity'] ?? 0).toDouble(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  // Converter para Map para salvar no Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? unit,
    double? quantity,
    double? minQuantity,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}