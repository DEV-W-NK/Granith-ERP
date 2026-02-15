import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum PurchaseStatus {
  pending,
  ordered,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case PurchaseStatus.pending: return 'Pendente';
      case PurchaseStatus.ordered: return 'Pedido Realizado';
      case PurchaseStatus.delivered: return 'Entregue';
      case PurchaseStatus.cancelled: return 'Cancelado';
    }
  }

  Color get color {
    switch (this) {
      case PurchaseStatus.pending: return Colors.orange;
      case PurchaseStatus.ordered: return Colors.blue;
      case PurchaseStatus.delivered: return Colors.green;
      case PurchaseStatus.cancelled: return Colors.red;
    }
  }
}

class Purchase {
  final String id;
  
  // Relacionamentos
  final String itemId;
  final String itemName;
  
  final String supplierId;
  final String supplierName;

  // NOVO: Associação com Projeto
  final String projectId;
  final String projectName;
  
  final String deliveryAddress;
  final double totalValue;
  final PurchaseStatus status;
  final DateTime purchaseDate;
  final DateTime? deliveryDate;

  Purchase({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.supplierId,
    required this.supplierName,
    required this.projectId, // Obrigatório
    required this.projectName, // Obrigatório
    required this.deliveryAddress,
    required this.totalValue,
    this.status = PurchaseStatus.pending,
    required this.purchaseDate,
    this.deliveryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'projectId': projectId,
      'projectName': projectName,
      'deliveryAddress': deliveryAddress,
      'totalValue': totalValue,
      'status': status.index,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'deliveryDate': deliveryDate != null ? Timestamp.fromDate(deliveryDate!) : null,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map, String id) {
    return Purchase(
      id: id,
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? 'Item Desconhecido',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? 'Fornecedor Desconhecido',
      projectId: map['projectId'] ?? '',
      projectName: map['projectName'] ?? 'Projeto não informado',
      deliveryAddress: map['deliveryAddress'] ?? '',
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      status: PurchaseStatus.values[map['status'] ?? 0],
      purchaseDate: (map['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryDate: (map['deliveryDate'] as Timestamp?)?.toDate(),
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
    double? totalValue,
    PurchaseStatus? status,
    DateTime? purchaseDate,
    DateTime? deliveryDate,
  }) {
    return Purchase(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      totalValue: totalValue ?? this.totalValue,
      status: status ?? this.status,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
    );
  }
}