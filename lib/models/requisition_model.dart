import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';

enum RequisitionStatus {
  pending, // Aguardando aprovação
  approved, // Aprovado — pronto para virar compra
  rejected, // Rejeitado
  purchased, // Compra gerada
  delivered, // Material entregue na obra
}

extension RequisitionStatusExt on RequisitionStatus {
  String get label => switch (this) {
    RequisitionStatus.pending => 'Pendente',
    RequisitionStatus.approved => 'Aprovado',
    RequisitionStatus.rejected => 'Rejeitado',
    RequisitionStatus.purchased => 'Comprado',
    RequisitionStatus.delivered => 'Entregue',
  };

  Color get color => switch (this) {
    RequisitionStatus.pending => Colors.orangeAccent,
    RequisitionStatus.approved => Colors.greenAccent,
    RequisitionStatus.rejected => Colors.redAccent,
    RequisitionStatus.purchased => Colors.blueAccent,
    RequisitionStatus.delivered => Colors.tealAccent,
  };

  IconData get icon => switch (this) {
    RequisitionStatus.pending => Icons.hourglass_empty_rounded,
    RequisitionStatus.approved => Icons.check_circle_outline,
    RequisitionStatus.rejected => Icons.cancel_outlined,
    RequisitionStatus.purchased => Icons.shopping_cart_outlined,
    RequisitionStatus.delivered => Icons.inventory_2_outlined,
  };

  static RequisitionStatus fromString(String? s) {
    if (s == null) return RequisitionStatus.pending;
    return RequisitionStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == s.toLowerCase(),
      orElse: () => RequisitionStatus.pending,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class RequisitionItem {
  final String itemName;
  final double quantity;
  final String unit;
  final String? observation;

  RequisitionItem({
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.observation,
  });

  Map<String, dynamic> toMap() => {
    'itemName': itemName,
    'quantity': quantity,
    'unit': unit,
    'observation': observation,
  };

  factory RequisitionItem.fromMap(Map<String, dynamic> map) {
    return RequisitionItem(
      itemName: map['itemName'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'un',
      observation: map['observation'] as String?,
    );
  }

  RequisitionItem copyWith({
    String? itemName,
    double? quantity,
    String? unit,
    String? observation,
  }) => RequisitionItem(
    itemName: itemName ?? this.itemName,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    observation: observation ?? this.observation,
  );

  @override
  bool operator ==(Object other) =>
      other is RequisitionItem &&
      other.itemName == itemName &&
      other.quantity == quantity &&
      other.unit == unit &&
      other.observation == observation;

  @override
  int get hashCode => Object.hash(itemName, quantity, unit, observation);
}

// ─────────────────────────────────────────────────────────────────────────────

class MaterialRequisitionModel {
  final String id;
  final String projectId;
  final String projectName;
  final String requesterName;
  final String? requesterId;
  final DateTime requestDate;
  final RequisitionStatus status;
  final List<RequisitionItem> items;
  final String priority; // 'Baixa' | 'Média' | 'Alta'

  // ── Aprovação ──
  final String? approvedBy; // UID de quem aprovou/rejeitou
  final String? approvedByName; // Nome legível
  final DateTime? approvedAt;
  final String? rejectionReason; // Obrigatório ao rejeitar

  // ── Compra gerada ──
  final String? purchaseId; // ID da Purchase criada a partir desta requisição

  final DateTime createdAt;

  MaterialRequisitionModel({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.requesterName,
    this.requesterId,
    required this.requestDate,
    required this.status,
    required this.items,
    this.priority = 'Média',
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.purchaseId,
    required this.createdAt,
  });

  double get totalQuantity => items.fold(0.0, (s, i) => s + i.quantity);

  int get itemCount => items.length;

  // Helper para exibir resumo rápido de itens
  String get itemsSummary =>
      items.isEmpty
          ? 'Nenhum item'
          : items.length == 1
          ? items.first.itemName
          : '${items.first.itemName} e mais ${items.length - 1}';

  Map<String, dynamic> toMap() => {
    'projectId': projectId,
    'projectName': projectName,
    'requesterName': requesterName,
    'requesterId': requesterId,
    'requestDate': DbValue.toPrimitive(requestDate),
    'status': status.name,
    'items': items.map((x) => x.toMap()).toList(),
    'priority': priority,
    'approvedBy': approvedBy,
    'approvedByName': approvedByName,
    'approvedAt': approvedAt != null ? DbValue.toPrimitive(approvedAt!) : null,
    'rejectionReason': rejectionReason,
    'purchaseId': purchaseId,
    'createdAt': DbValue.toPrimitive(createdAt),
  };

  factory MaterialRequisitionModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    DateTime parse(dynamic v) {
      if (v == null) return DateTime.now();
      return DbValue.toDateTime(v) ?? DateTime.now();
    }

    return MaterialRequisitionModel(
      id: docId,
      projectId: map['projectId'] ?? '',
      projectName: map['projectName'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterId: map['requesterId'] as String?,
      requestDate: parse(map['requestDate']),
      status: RequisitionStatusExt.fromString(map['status'] as String?),
      items:
          (map['items'] as List<dynamic>?)
              ?.map(
                (x) => RequisitionItem.fromMap(Map<String, dynamic>.from(x)),
              )
              .toList() ??
          [],
      priority: map['priority'] ?? 'Média',
      approvedBy: map['approvedBy'] as String?,
      approvedByName: map['approvedByName'] as String?,
      approvedAt: map['approvedAt'] != null ? parse(map['approvedAt']) : null,
      rejectionReason: map['rejectionReason'] as String?,
      purchaseId: map['purchaseId'] as String?,
      createdAt: parse(map['createdAt']),
    );
  }

  MaterialRequisitionModel copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? requesterName,
    String? requesterId,
    DateTime? requestDate,
    RequisitionStatus? status,
    List<RequisitionItem>? items,
    String? priority,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    String? purchaseId,
    DateTime? createdAt,
  }) => MaterialRequisitionModel(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    projectName: projectName ?? this.projectName,
    requesterName: requesterName ?? this.requesterName,
    requesterId: requesterId ?? this.requesterId,
    requestDate: requestDate ?? this.requestDate,
    status: status ?? this.status,
    items: items ?? List.from(this.items),
    priority: priority ?? this.priority,
    approvedBy: approvedBy ?? this.approvedBy,
    approvedByName: approvedByName ?? this.approvedByName,
    approvedAt: approvedAt ?? this.approvedAt,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    purchaseId: purchaseId ?? this.purchaseId,
    createdAt: createdAt ?? this.createdAt,
  );
}
