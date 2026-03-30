import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PurchaseStatus {
  awaitingApproval,
  pending,
  ordered,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case PurchaseStatus.awaitingApproval: return 'Ag. Aprovação CEO';
      case PurchaseStatus.pending:          return 'Pendente';
      case PurchaseStatus.ordered:          return 'Pedido Realizado';
      case PurchaseStatus.delivered:        return 'Entregue';
      case PurchaseStatus.cancelled:        return 'Cancelado';
    }
  }

  Color get color {
    switch (this) {
      case PurchaseStatus.awaitingApproval: return Colors.purpleAccent;
      case PurchaseStatus.pending:          return Colors.orange;
      case PurchaseStatus.ordered:          return Colors.blue;
      case PurchaseStatus.delivered:        return Colors.green;
      case PurchaseStatus.cancelled:        return Colors.red;
    }
  }
}

class Purchase {
  final String id;

  final String itemId;
  final String itemName;
  final String supplierId;
  final String supplierName;
  final String projectId;
  final String projectName;

  final String? requisitionId;
  final String? financialTransactionId;

  final String deliveryAddress;
  final double quantity;
  final double totalValue;
  final PurchaseStatus status;
  final DateTime purchaseDate;
  final DateTime? deliveryDate;
  final String? receivedBy;

  // ── Aprovação CEO ──────────────────────────────────────────────────────────
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;

  Purchase({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.supplierId,
    required this.supplierName,
    required this.projectId,
    required this.projectName,
    required this.deliveryAddress,
    this.quantity = 1.0,
    required this.totalValue,
    this.status = PurchaseStatus.pending,
    required this.purchaseDate,
    this.deliveryDate,
    this.requisitionId,
    this.financialTransactionId,
    this.receivedBy,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId':                 itemId,
      'itemName':               itemName,
      'supplierId':             supplierId,
      'supplierName':           supplierName,
      'projectId':              projectId,
      'projectName':            projectName,
      'deliveryAddress':        deliveryAddress,
      'quantity':               quantity,
      'totalValue':             totalValue,
      'status':                 status.index,
      'purchaseDate':           Timestamp.fromDate(purchaseDate),
      'deliveryDate':           deliveryDate != null
          ? Timestamp.fromDate(deliveryDate!) : null,
      'requisitionId':          requisitionId,
      'financialTransactionId': financialTransactionId,
      'receivedBy':             receivedBy,
      'approvedBy':             approvedBy,
      'approvedByName':         approvedByName,
      'approvedAt':             approvedAt != null
          ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason':        rejectionReason,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map, String id) {
    return Purchase(
      id:              id,
      itemId:          map['itemId']       ?? '',
      itemName:        map['itemName']     ?? 'Item Desconhecido',
      supplierId:      map['supplierId']   ?? '',
      supplierName:    map['supplierName'] ?? 'Fornecedor Desconhecido',
      projectId:       map['projectId']    ?? '',
      projectName:     map['projectName']  ?? 'Projeto não informado',
      deliveryAddress: map['deliveryAddress'] ?? '',
      quantity:        (map['quantity'] ?? 1.0).toDouble(),
      totalValue:      (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      status:          PurchaseStatus.values[map['status'] ?? 0],
      purchaseDate:    (map['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryDate:    (map['deliveryDate'] as Timestamp?)?.toDate(),
      requisitionId:          map['requisitionId']          as String?,
      financialTransactionId: map['financialTransactionId'] as String?,
      receivedBy:             map['receivedBy']             as String?,
      approvedBy:             map['approvedBy']             as String?,
      approvedByName:         map['approvedByName']         as String?,
      approvedAt:    (map['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason:        map['rejectionReason']        as String?,
    );
  }

  Purchase copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? supplierId,
    String? supplierName,
    String? projectId,
    String? projectName,
    String? deliveryAddress,
    double? quantity,
    double? totalValue,
    PurchaseStatus? status,
    DateTime? purchaseDate,
    DateTime? deliveryDate,
    String? requisitionId,
    String? financialTransactionId,
    String? receivedBy,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
  }) {
    return Purchase(
      id:                     id                     ?? this.id,
      itemId:                 itemId                 ?? this.itemId,
      itemName:               itemName               ?? this.itemName,
      supplierId:             supplierId             ?? this.supplierId,
      supplierName:           supplierName           ?? this.supplierName,
      projectId:              projectId              ?? this.projectId,
      projectName:            projectName            ?? this.projectName,
      deliveryAddress:        deliveryAddress        ?? this.deliveryAddress,
      quantity:               quantity               ?? this.quantity,
      totalValue:             totalValue             ?? this.totalValue,
      status:                 status                 ?? this.status,
      purchaseDate:           purchaseDate           ?? this.purchaseDate,
      deliveryDate:           deliveryDate           ?? this.deliveryDate,
      requisitionId:          requisitionId          ?? this.requisitionId,
      financialTransactionId: financialTransactionId ?? this.financialTransactionId,
      receivedBy:             receivedBy             ?? this.receivedBy,
      approvedBy:             approvedBy             ?? this.approvedBy,
      approvedByName:         approvedByName         ?? this.approvedByName,
      approvedAt:             approvedAt             ?? this.approvedAt,
      rejectionReason:        rejectionReason        ?? this.rejectionReason,
    );
  }
}