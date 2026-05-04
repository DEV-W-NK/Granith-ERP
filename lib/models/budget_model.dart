import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';
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
  final String? projectId;
  final String? budgetTypeId;
  final BudgetType? budgetType;
  final String? clientAccountId;
  final String? clientAccountName;

  const Budget({
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
    this.clientAccountId,
    this.clientAccountName,
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
      'clientAccountId': clientAccountId,
      'client_account_id': clientAccountId,
      'clientAccountName': clientAccountName,
      'client_account_name': clientAccountName,
    };
  }

  static Budget fromMap(Map<String, dynamic> map) {
    final creationDateValue = map['creationDate'] ?? map['created_at'];
    final expirationDateValue = map['expirationDate'];

    DateTime parseDate(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DbValue.toDateTime(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DbValue.toDateTime(value);
    }

    return Budget(
      id: (map['id'] ?? '').toString(),
      clientName: (map['clientName'] ?? '').toString(),
      projectName: (map['projectName'] ?? '').toString(),
      totalValue: (map['totalValue'] ?? 0.0).toDouble(),
      creationDate: parseDate(creationDateValue),
      expirationDate: parseNullableDate(expirationDateValue),
      status: BudgetStatus.values[(map['status'] ?? 0) as int],
      description: (map['description'] ?? '').toString(),
      items: List<BudgetItem>.from(
        map['items']?.map((item) => BudgetItem.fromMap(item)) ?? [],
      ),
      projectId: map['projectId']?.toString(),
      budgetTypeId: map['budgetTypeId']?.toString(),
      clientAccountId:
          map['clientAccountId']?.toString() ??
          map['client_account_id']?.toString(),
      clientAccountName:
          map['clientAccountName']?.toString() ??
          map['client_account_name']?.toString(),
    );
  }

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
    String? clientAccountId,
    String? clientAccountName,
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
      clientAccountId: clientAccountId ?? this.clientAccountId,
      clientAccountName: clientAccountName ?? this.clientAccountName,
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
      description: (map['description'] ?? '').toString(),
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
