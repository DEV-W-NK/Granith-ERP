import 'package:cloud_firestore/cloud_firestore.dart';

enum InventoryMovementType { 
  outbound, // Baixa / Uso
  transfer  // Transferência
}

class InventoryMovement {
  final String id;
  final String itemId;
  final String itemName;
  final double quantity;
  final InventoryMovementType type;
  final String? projectId;
  final String? projectName;
  final DateTime date;
  final String? notes;
  final String? userId;

  InventoryMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.type,
    this.projectId,
    this.projectName,
    required this.date,
    this.notes,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'type': type.name,
      'projectId': projectId,
      'projectName': projectName,
      'date': FieldValue.serverTimestamp(),
      'notes': notes,
      'userId': userId,
    };
  }
}