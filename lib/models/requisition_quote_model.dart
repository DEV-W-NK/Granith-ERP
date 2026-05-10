import 'package:project_granith/core/data/db_value.dart';

enum RequisitionQuoteStatus {
  draft,
  sent,
  received,
  selected,
  rejected;

  String get label {
    switch (this) {
      case RequisitionQuoteStatus.draft:
        return 'Rascunho';
      case RequisitionQuoteStatus.sent:
        return 'Enviado';
      case RequisitionQuoteStatus.received:
        return 'Recebido';
      case RequisitionQuoteStatus.selected:
        return 'Selecionado';
      case RequisitionQuoteStatus.rejected:
        return 'Rejeitado';
    }
  }
}

class RequisitionSupplierQuote {
  final String id;
  final String requisitionId;
  final String? supplierId;
  final String supplierName;
  final String contactName;
  final double totalValue;
  final double freightValue;
  final int deliveryDays;
  final String paymentTerms;
  final DateTime? validUntil;
  final List<Map<String, dynamic>> quoteItems;
  final String notes;
  final RequisitionQuoteStatus status;
  final bool isSelected;
  final DateTime quotedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RequisitionSupplierQuote({
    required this.id,
    required this.requisitionId,
    this.supplierId,
    required this.supplierName,
    this.contactName = '',
    required this.totalValue,
    this.freightValue = 0,
    this.deliveryDays = 0,
    this.paymentTerms = '',
    this.validUntil,
    this.quoteItems = const [],
    this.notes = '',
    this.status = RequisitionQuoteStatus.received,
    this.isSelected = false,
    required this.quotedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  double get negotiatedTotal => totalValue + freightValue;

  factory RequisitionSupplierQuote.fromMap(Map<String, dynamic> map) {
    return RequisitionSupplierQuote(
      id: map['id'] as String? ?? '',
      requisitionId: map['requisitionId'] as String? ?? '',
      supplierId: map['supplierId'] as String?,
      supplierName: map['supplierName'] as String? ?? '',
      contactName: map['contactName'] as String? ?? '',
      totalValue: (map['totalValue'] as num? ?? 0).toDouble(),
      freightValue: (map['freightValue'] as num? ?? 0).toDouble(),
      deliveryDays: (map['deliveryDays'] as num? ?? 0).toInt(),
      paymentTerms: map['paymentTerms'] as String? ?? '',
      validUntil: DbValue.toDateTime(map['validUntil']),
      quoteItems:
          (map['quoteItems'] as List? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
      notes: map['notes'] as String? ?? '',
      status: RequisitionQuoteStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => RequisitionQuoteStatus.received,
      ),
      isSelected: map['isSelected'] as bool? ?? false,
      quotedAt: DbValue.toDateTime(map['quotedAt']) ?? DateTime.now(),
      createdBy: map['createdBy'] as String?,
      createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: DbValue.toDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requisitionId': requisitionId,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'contactName': contactName,
      'totalValue': totalValue,
      'freightValue': freightValue,
      'deliveryDays': deliveryDays,
      'paymentTerms': paymentTerms,
      'validUntil': DbValue.toPrimitive(validUntil),
      'quoteItems': quoteItems,
      'notes': notes,
      'status': status.name,
      'isSelected': isSelected,
      'quotedAt': DbValue.toPrimitive(quotedAt),
      'createdBy': createdBy,
      'createdAt': DbValue.toPrimitive(createdAt),
      'updatedAt': DbValue.toPrimitive(updatedAt),
    };
  }

  RequisitionSupplierQuote copyWith({
    String? id,
    String? requisitionId,
    String? supplierId,
    String? supplierName,
    String? contactName,
    double? totalValue,
    double? freightValue,
    int? deliveryDays,
    String? paymentTerms,
    DateTime? validUntil,
    List<Map<String, dynamic>>? quoteItems,
    String? notes,
    RequisitionQuoteStatus? status,
    bool? isSelected,
    DateTime? quotedAt,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RequisitionSupplierQuote(
      id: id ?? this.id,
      requisitionId: requisitionId ?? this.requisitionId,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      contactName: contactName ?? this.contactName,
      totalValue: totalValue ?? this.totalValue,
      freightValue: freightValue ?? this.freightValue,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      validUntil: validUntil ?? this.validUntil,
      quoteItems: quoteItems ?? this.quoteItems,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isSelected: isSelected ?? this.isSelected,
      quotedAt: quotedAt ?? this.quotedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
