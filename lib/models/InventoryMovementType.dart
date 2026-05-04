import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';

enum InventoryMovementType {
  inbound, // Entrada (compra recebida)
  outbound, // Saída / uso em obra
  transfer, // Transferência entre projetos
  adjustment, // Ajuste manual de inventário
}

extension InventoryMovementTypeExt on InventoryMovementType {
  String get label => switch (this) {
    InventoryMovementType.inbound => 'Entrada',
    InventoryMovementType.outbound => 'Saída',
    InventoryMovementType.transfer => 'Transferência',
    InventoryMovementType.adjustment => 'Ajuste',
  };

  Color get color => switch (this) {
    InventoryMovementType.inbound => Colors.greenAccent,
    InventoryMovementType.outbound => Colors.redAccent,
    InventoryMovementType.transfer => Colors.blueAccent,
    InventoryMovementType.adjustment => Colors.orangeAccent,
  };

  IconData get icon => switch (this) {
    InventoryMovementType.inbound => Icons.arrow_downward,
    InventoryMovementType.outbound => Icons.arrow_upward,
    InventoryMovementType.transfer => Icons.swap_horiz,
    InventoryMovementType.adjustment => Icons.tune,
  };

  /// True = adiciona ao saldo. False = subtrai.
  bool get isAdditive =>
      this == InventoryMovementType.inbound ||
      this == InventoryMovementType.adjustment;

  /// Alias para addMovement() genérico no inventory_service.
  bool get isIncrease => isAdditive;
}

class InventoryMovement {
  final String id;
  final String itemId;
  final String itemName;
  final double quantity;
  final InventoryMovementType type;

  final String? projectId;
  final String? projectName;

  /// ID da compra que gerou esta entrada (type == inbound).
  final String? purchaseId;

  /// ID genérico de origem (requisição, diário de obra, etc.).
  final String? referenceId;

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
    this.purchaseId,
    this.referenceId,
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
      'purchaseId': purchaseId,
      'referenceId': referenceId,
      'date': DbValue.toPrimitive(date),
      'notes': notes,
      'userId': userId,
    };
  }

  factory InventoryMovement.fromMap(Map<String, dynamic> map, String docId) {
    return InventoryMovement(
      id: docId,
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      type: InventoryMovementType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InventoryMovementType.inbound,
      ),
      projectId: map['projectId'] as String?,
      projectName: map['projectName'] as String?,
      purchaseId: map['purchaseId'] as String?,
      referenceId: map['referenceId'] as String?,
      date: DbValue.toDateTime(map['date']) ?? DateTime.now(),
      notes: map['notes'] as String?,
      userId: map['userId'] as String?,
    );
  }
}
