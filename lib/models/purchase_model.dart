import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';

enum PurchaseStatus {
  awaitingApproval,
  pending,
  ordered,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case PurchaseStatus.awaitingApproval:
        return 'Ag. aprovacao do setor';
      case PurchaseStatus.pending:
        return 'Aprovada p/ compra';
      case PurchaseStatus.ordered:
        return 'Compra consolidada';
      case PurchaseStatus.delivered:
        return 'Entregue';
      case PurchaseStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color get color {
    switch (this) {
      case PurchaseStatus.awaitingApproval:
        return Colors.purpleAccent;
      case PurchaseStatus.pending:
        return Colors.orange;
      case PurchaseStatus.ordered:
        return Colors.blue;
      case PurchaseStatus.delivered:
        return Colors.green;
      case PurchaseStatus.cancelled:
        return Colors.red;
    }
  }
}

enum PurchaseFulfillmentType {
  delivery,
  pickup;

  String get label {
    switch (this) {
      case PurchaseFulfillmentType.delivery:
        return 'Entrega do fornecedor';
      case PurchaseFulfillmentType.pickup:
        return 'Coleta interna';
    }
  }

  String get routeLabel {
    switch (this) {
      case PurchaseFulfillmentType.delivery:
        return 'Entrega';
      case PurchaseFulfillmentType.pickup:
        return 'Coleta';
    }
  }

  IconData get icon {
    switch (this) {
      case PurchaseFulfillmentType.delivery:
        return Icons.local_shipping_outlined;
      case PurchaseFulfillmentType.pickup:
        return Icons.store_mall_directory_outlined;
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
  final PurchaseFulfillmentType fulfillmentType;
  final String pickupAddress;
  final String? routeId;
  final double quantity;
  final double totalValue;
  final PurchaseStatus status;
  final DateTime purchaseDate;
  final DateTime? deliveryDate;
  final DateTime? expectedDeliveryDate;
  final String? receivedBy;

  final String? invoiceNumber;
  final String? invoiceAccessKey;
  final String? notes;

  final String? approvalSector;
  final String? quotedBy;
  final String? quotedByName;
  final DateTime? quotedAt;

  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;

  final String? consolidatedBy;
  final String? consolidatedByName;
  final DateTime? consolidatedAt;

  Purchase({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.supplierId,
    required this.supplierName,
    required this.projectId,
    required this.projectName,
    required this.deliveryAddress,
    this.fulfillmentType = PurchaseFulfillmentType.delivery,
    this.pickupAddress = '',
    this.routeId,
    this.quantity = 1.0,
    required this.totalValue,
    this.status = PurchaseStatus.pending,
    required this.purchaseDate,
    this.deliveryDate,
    this.expectedDeliveryDate,
    this.requisitionId,
    this.financialTransactionId,
    this.receivedBy,
    this.invoiceNumber,
    this.invoiceAccessKey,
    this.notes,
    this.approvalSector,
    this.quotedBy,
    this.quotedByName,
    this.quotedAt,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.consolidatedBy,
    this.consolidatedByName,
    this.consolidatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'supplierId': _nullableText(supplierId),
      'supplierName': supplierName,
      'projectId': _nullableText(projectId),
      'projectName': projectName,
      'deliveryAddress': deliveryAddress,
      'fulfillmentType': fulfillmentType.name,
      'pickupAddress': pickupAddress,
      'routeId': routeId,
      'quantity': quantity,
      'totalValue': totalValue,
      'status': status.index,
      'purchaseDate': DbValue.toPrimitive(purchaseDate),
      'deliveryDate': DbValue.toPrimitive(deliveryDate),
      'expectedDeliveryDate': DbValue.toPrimitive(expectedDeliveryDate),
      'requisitionId': _nullableText(requisitionId),
      'financialTransactionId': _nullableText(financialTransactionId),
      'receivedBy': receivedBy,
      'invoiceNumber': invoiceNumber,
      'invoiceAccessKey': invoiceAccessKey,
      'notes': notes,
      'approvalSector': approvalSector,
      'quotedBy': quotedBy,
      'quotedByName': quotedByName,
      'quotedAt': DbValue.toPrimitive(quotedAt),
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': DbValue.toPrimitive(approvedAt),
      'rejectionReason': rejectionReason,
      'consolidatedBy': consolidatedBy,
      'consolidatedByName': consolidatedByName,
      'consolidatedAt': DbValue.toPrimitive(consolidatedAt),
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
      projectName: map['projectName'] ?? 'Projeto nao informado',
      deliveryAddress: map['deliveryAddress'] ?? '',
      fulfillmentType: _parseFulfillmentType(map['fulfillmentType']),
      pickupAddress: map['pickupAddress'] as String? ?? '',
      routeId: map['routeId'] as String?,
      quantity: (map['quantity'] as num? ?? 1.0).toDouble(),
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(map['status']),
      purchaseDate: DbValue.toDateTime(map['purchaseDate']) ?? DateTime.now(),
      deliveryDate: DbValue.toDateTime(map['deliveryDate']),
      expectedDeliveryDate: DbValue.toDateTime(map['expectedDeliveryDate']),
      requisitionId: map['requisitionId'] as String?,
      financialTransactionId: map['financialTransactionId'] as String?,
      receivedBy: map['receivedBy'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      invoiceAccessKey: map['invoiceAccessKey'] as String?,
      notes: map['notes'] as String?,
      approvalSector: map['approvalSector'] as String?,
      quotedBy: map['quotedBy'] as String?,
      quotedByName: map['quotedByName'] as String?,
      quotedAt: DbValue.toDateTime(map['quotedAt']),
      approvedBy: map['approvedBy'] as String?,
      approvedByName: map['approvedByName'] as String?,
      approvedAt: DbValue.toDateTime(map['approvedAt']),
      rejectionReason: map['rejectionReason'] as String?,
      consolidatedBy: map['consolidatedBy'] as String?,
      consolidatedByName: map['consolidatedByName'] as String?,
      consolidatedAt: DbValue.toDateTime(map['consolidatedAt']),
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
    PurchaseFulfillmentType? fulfillmentType,
    String? pickupAddress,
    String? routeId,
    double? quantity,
    double? totalValue,
    PurchaseStatus? status,
    DateTime? purchaseDate,
    DateTime? deliveryDate,
    DateTime? expectedDeliveryDate,
    String? requisitionId,
    String? financialTransactionId,
    String? receivedBy,
    String? invoiceNumber,
    String? invoiceAccessKey,
    String? notes,
    String? approvalSector,
    String? quotedBy,
    String? quotedByName,
    DateTime? quotedAt,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    String? consolidatedBy,
    String? consolidatedByName,
    DateTime? consolidatedAt,
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
      fulfillmentType: fulfillmentType ?? this.fulfillmentType,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      routeId: routeId ?? this.routeId,
      quantity: quantity ?? this.quantity,
      totalValue: totalValue ?? this.totalValue,
      status: status ?? this.status,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      requisitionId: requisitionId ?? this.requisitionId,
      financialTransactionId:
          financialTransactionId ?? this.financialTransactionId,
      receivedBy: receivedBy ?? this.receivedBy,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceAccessKey: invoiceAccessKey ?? this.invoiceAccessKey,
      notes: notes ?? this.notes,
      approvalSector: approvalSector ?? this.approvalSector,
      quotedBy: quotedBy ?? this.quotedBy,
      quotedByName: quotedByName ?? this.quotedByName,
      quotedAt: quotedAt ?? this.quotedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      consolidatedBy: consolidatedBy ?? this.consolidatedBy,
      consolidatedByName: consolidatedByName ?? this.consolidatedByName,
      consolidatedAt: consolidatedAt ?? this.consolidatedAt,
    );
  }

  static PurchaseStatus _parseStatus(dynamic value) {
    if (value is int && value >= 0 && value < PurchaseStatus.values.length) {
      return PurchaseStatus.values[value];
    }

    if (value is String) {
      final byName = PurchaseStatus.values.where(
        (status) => status.name.toLowerCase() == value.toLowerCase(),
      );
      if (byName.isNotEmpty) return byName.first;

      final byIndex = int.tryParse(value);
      if (byIndex != null &&
          byIndex >= 0 &&
          byIndex < PurchaseStatus.values.length) {
        return PurchaseStatus.values[byIndex];
      }
    }

    return PurchaseStatus.awaitingApproval;
  }

  static PurchaseFulfillmentType _parseFulfillmentType(dynamic value) {
    if (value is PurchaseFulfillmentType) return value;
    if (value is String) {
      return PurchaseFulfillmentType.values.firstWhere(
        (type) => type.name.toLowerCase() == value.toLowerCase(),
        orElse: () => PurchaseFulfillmentType.delivery,
      );
    }
    return PurchaseFulfillmentType.delivery;
  }

  static String? _nullableText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
