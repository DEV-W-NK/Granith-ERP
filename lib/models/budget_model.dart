import 'package:flutter/material.dart';
import 'package:project_granith/models/budget_type.dart';

class Budget {
  final String id;
  final String clientName;
  final String projectName;
  final double totalValue;
  final DateTime creationDate;
  final DateTime? expirationDate;
  final BudgetStatus status;
  final String description;
  final List<BudgetItem> items;
  final String? projectId; // Referência ao projeto relacionado
  final String? budgetTypeId; // ID do tipo de orçamento
  final BudgetType? budgetType; // Objeto do tipo de orçamento (não persistido)

  Budget({
    required this.id,
    required this.clientName,
    required this.projectName,
    required this.totalValue,
    required this.creationDate,
    this.expirationDate,
    this.status = BudgetStatus.pending,
    this.description = '',
    this.items = const [],
    this.projectId,
    this.budgetTypeId,
    this.budgetType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientName': clientName,
      'projectName': projectName,
      'totalValue': totalValue,
      'creationDate': creationDate.millisecondsSinceEpoch,
      'expirationDate': expirationDate?.millisecondsSinceEpoch,
      'status': status.index,
      'description': description,
      'items': items.map((item) => item.toMap()).toList(),
      'projectId': projectId,
      'budgetTypeId': budgetTypeId,
    };
  }

  static Budget fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] ?? '',
      clientName: map['clientName'] ?? '',
      projectName: map['projectName'] ?? '',
      totalValue: (map['totalValue'] ?? 0.0).toDouble(),
      creationDate: DateTime.fromMillisecondsSinceEpoch(map['creationDate'] ?? 0),
      expirationDate: map['expirationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expirationDate'])
          : null,
      status: BudgetStatus.values[map['status'] ?? 0],
      description: map['description'] ?? '',
      items: List<BudgetItem>.from(
        map['items']?.map((item) => BudgetItem.fromMap(item)) ?? [],
      ),
      projectId: map['projectId'],
      budgetTypeId: map['budgetTypeId'],
      // budgetType será carregado separadamente quando necessário
    );
  }

  // Método copyWith para facilitar atualizações
  Budget copyWith({
    String? id,
    String? clientName,
    String? projectName,
    double? totalValue,
    DateTime? creationDate,
    DateTime? expirationDate,
    BudgetStatus? status,
    String? description,
    List<BudgetItem>? items,
    String? projectId,
    String? budgetTypeId,
    BudgetType? budgetType,
  }) {
    return Budget(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      projectName: projectName ?? this.projectName,
      totalValue: totalValue ?? this.totalValue,
      creationDate: creationDate ?? this.creationDate,
      expirationDate: expirationDate ?? this.expirationDate,
      status: status ?? this.status,
      description: description ?? this.description,
      items: items ?? this.items,
      projectId: projectId ?? this.projectId,
      budgetTypeId: budgetTypeId ?? this.budgetTypeId,
      budgetType: budgetType ?? this.budgetType,
    );
  }
}

class BudgetItem {
  final String description;
  final int quantity;
  final double unitPrice;
  final double total;

  BudgetItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  }) : total = quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  static BudgetItem fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
    );
  }
}

enum BudgetStatus {
  pending,
  approved,
  rejected,
  expired;

  String get displayName {
    switch (this) {
      case BudgetStatus.pending:
        return 'Pendente';
      case BudgetStatus.approved:
        return 'Aprovado';
      case BudgetStatus.rejected:
        return 'Rejeitado';
      case BudgetStatus.expired:
        return 'Expirado';
    }
  }

  Color get color {
    switch (this) {
      case BudgetStatus.pending:
        return Colors.orange;
      case BudgetStatus.approved:
        return Colors.green;
      case BudgetStatus.rejected:
        return Colors.red;
      case BudgetStatus.expired:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case BudgetStatus.pending:
        return Icons.pending_actions;
      case BudgetStatus.approved:
        return Icons.check_circle;
      case BudgetStatus.rejected:
        return Icons.cancel;
      case BudgetStatus.expired:
        return Icons.timelapse;
    }
  }
}