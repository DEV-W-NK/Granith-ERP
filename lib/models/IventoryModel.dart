import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final String unit;
  final double quantity;
  final double minQuantity;
  final DateTime updatedAt;
  final DateTime? lastEntryDate;

  /// ID da última compra que gerou entrada neste item.
  final String? lastPurchaseId;

  InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.quantity,
    this.minQuantity = 0,
    required this.updatedAt,
    this.lastEntryDate,
    this.lastPurchaseId,
  });

  // ─── Computed ─────────────────────────────────────────────────────────────

  bool get isLowStock    => minQuantity > 0 && quantity <= minQuantity;
  bool get isOutOfStock  => quantity <= 0;

  double get stockHealthPercent {
    if (minQuantity == 0) return 100;
    return (quantity / minQuantity * 100).clamp(0.0, 200.0);
  }

  // ─── Serialização ──────────────────────────────────────────────────────────

  factory InventoryItem.fromMap(String id, Map<String, dynamic> data) {
    return InventoryItem(
      id:          id,
      name:        data['name']  ?? '',
      unit:        data['unit']  ?? 'un',
      quantity:    (data['quantity']    ?? 0).toDouble(),
      minQuantity: (data['minQuantity'] ?? 0).toDouble(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastEntryDate: data['lastEntryDate'] is Timestamp
          ? (data['lastEntryDate'] as Timestamp).toDate()
          : null,
      lastPurchaseId: data['lastPurchaseId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name':            name,
      'name_normalized': name.trim().toLowerCase(),
      'unit':            unit,
      'quantity':        quantity,
      'minQuantity':     minQuantity,
      'updatedAt':       FieldValue.serverTimestamp(),
      'lastPurchaseId':  lastPurchaseId,
    };
  }

  InventoryItem copyWith({
    String? id, String? name, String? unit,
    double? quantity, double? minQuantity,
    DateTime? updatedAt, DateTime? lastEntryDate,
    String? lastPurchaseId,
  }) {
    return InventoryItem(
      id:             id             ?? this.id,
      name:           name           ?? this.name,
      unit:           unit           ?? this.unit,
      quantity:       quantity       ?? this.quantity,
      minQuantity:    minQuantity    ?? this.minQuantity,
      updatedAt:      updatedAt      ?? this.updatedAt,
      lastEntryDate:  lastEntryDate  ?? this.lastEntryDate,
      lastPurchaseId: lastPurchaseId ?? this.lastPurchaseId,
    );
  }
}