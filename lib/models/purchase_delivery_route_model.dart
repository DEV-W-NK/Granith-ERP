import 'package:project_granith/core/data/db_value.dart';

enum PurchaseRouteStatus {
  planned,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case PurchaseRouteStatus.planned:
        return 'Planejada';
      case PurchaseRouteStatus.inProgress:
        return 'Em rota';
      case PurchaseRouteStatus.completed:
        return 'Concluida';
      case PurchaseRouteStatus.cancelled:
        return 'Cancelada';
    }
  }
}

enum PurchaseRouteStopType {
  pickup,
  delivery;

  String get label {
    switch (this) {
      case PurchaseRouteStopType.pickup:
        return 'Coleta';
      case PurchaseRouteStopType.delivery:
        return 'Entrega';
    }
  }
}

enum PurchaseRouteStopStatus {
  pending,
  completed,
  skipped;

  String get label {
    switch (this) {
      case PurchaseRouteStopStatus.pending:
        return 'Pendente';
      case PurchaseRouteStopStatus.completed:
        return 'Concluida';
      case PurchaseRouteStopStatus.skipped:
        return 'Pulada';
    }
  }
}

class PurchaseDeliveryRoute {
  final String id;
  final String name;
  final String? driverId;
  final String driverName;
  final PurchaseRouteStatus status;
  final DateTime? scheduledDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double estimatedDistanceKm;
  final double actualDistanceKm;
  final double kmRate;
  final double bonusValue;
  final String notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PurchaseDeliveryRoute({
    required this.id,
    required this.name,
    this.driverId,
    required this.driverName,
    this.status = PurchaseRouteStatus.planned,
    this.scheduledDate,
    this.startedAt,
    this.completedAt,
    this.estimatedDistanceKm = 0,
    this.actualDistanceKm = 0,
    this.kmRate = 0,
    this.bonusValue = 0,
    this.notes = '',
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PurchaseDeliveryRoute.fromMap(Map<String, dynamic> map) {
    return PurchaseDeliveryRoute(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      driverId: map['driverId'] as String?,
      driverName: map['driverName'] as String? ?? '',
      status: PurchaseRouteStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => PurchaseRouteStatus.planned,
      ),
      scheduledDate: DbValue.toDateTime(map['scheduledDate']),
      startedAt: DbValue.toDateTime(map['startedAt']),
      completedAt: DbValue.toDateTime(map['completedAt']),
      estimatedDistanceKm: (map['estimatedDistanceKm'] as num? ?? 0).toDouble(),
      actualDistanceKm: (map['actualDistanceKm'] as num? ?? 0).toDouble(),
      kmRate: (map['kmRate'] as num? ?? 0).toDouble(),
      bonusValue: (map['bonusValue'] as num? ?? 0).toDouble(),
      notes: map['notes'] as String? ?? '',
      createdBy: map['createdBy'] as String?,
      createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: DbValue.toDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'driverId': driverId,
      'driverName': driverName,
      'status': status.name,
      'scheduledDate': DbValue.toPrimitive(scheduledDate),
      'startedAt': DbValue.toPrimitive(startedAt),
      'completedAt': DbValue.toPrimitive(completedAt),
      'estimatedDistanceKm': estimatedDistanceKm,
      'actualDistanceKm': actualDistanceKm,
      'kmRate': kmRate,
      'bonusValue': bonusValue,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': DbValue.toPrimitive(createdAt),
      'updatedAt': DbValue.toPrimitive(updatedAt),
    };
  }
}

class PurchaseDeliveryRouteStop {
  final String id;
  final String routeId;
  final String purchaseId;
  final PurchaseRouteStopType stopType;
  final int sequence;
  final String address;
  final String supplierName;
  final String projectName;
  final PurchaseRouteStopStatus status;
  final String notes;
  final DateTime? completedAt;
  final DateTime createdAt;

  const PurchaseDeliveryRouteStop({
    required this.id,
    required this.routeId,
    required this.purchaseId,
    required this.stopType,
    required this.sequence,
    required this.address,
    required this.supplierName,
    required this.projectName,
    this.status = PurchaseRouteStopStatus.pending,
    this.notes = '',
    this.completedAt,
    required this.createdAt,
  });

  factory PurchaseDeliveryRouteStop.fromMap(Map<String, dynamic> map) {
    return PurchaseDeliveryRouteStop(
      id: map['id'] as String? ?? '',
      routeId: map['routeId'] as String? ?? '',
      purchaseId: map['purchaseId'] as String? ?? '',
      stopType: PurchaseRouteStopType.values.firstWhere(
        (type) => type.name == map['stopType'],
        orElse: () => PurchaseRouteStopType.delivery,
      ),
      sequence: (map['sequence'] as num? ?? 0).toInt(),
      address: map['address'] as String? ?? '',
      supplierName: map['supplierName'] as String? ?? '',
      projectName: map['projectName'] as String? ?? '',
      status: PurchaseRouteStopStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => PurchaseRouteStopStatus.pending,
      ),
      notes: map['notes'] as String? ?? '',
      completedAt: DbValue.toDateTime(map['completedAt']),
      createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeId': routeId,
      'purchaseId': purchaseId,
      'stopType': stopType.name,
      'sequence': sequence,
      'address': address,
      'supplierName': supplierName,
      'projectName': projectName,
      'status': status.name,
      'notes': notes,
      'completedAt': DbValue.toPrimitive(completedAt),
      'createdAt': DbValue.toPrimitive(createdAt),
    };
  }
}
