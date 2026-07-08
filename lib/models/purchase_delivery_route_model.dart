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
      id: _readString(map, 'id'),
      name: _readString(map, 'name'),
      driverId: _readNullableString(map, 'driverId', 'driver_id'),
      driverName: _readString(map, 'driverName', 'driver_name'),
      status: PurchaseRouteStatus.values.firstWhere(
        (status) => status.name == _readString(map, 'status'),
        orElse: () => PurchaseRouteStatus.planned,
      ),
      scheduledDate: DbValue.toDateTime(
        _read(map, 'scheduledDate', 'scheduled_date'),
      ),
      startedAt: DbValue.toDateTime(_read(map, 'startedAt', 'started_at')),
      completedAt: DbValue.toDateTime(
        _read(map, 'completedAt', 'completed_at'),
      ),
      estimatedDistanceKm: _readDouble(
        map,
        'estimatedDistanceKm',
        'estimated_distance_km',
      ),
      actualDistanceKm: _readDouble(
        map,
        'actualDistanceKm',
        'actual_distance_km',
      ),
      kmRate: _readDouble(map, 'kmRate', 'km_rate'),
      bonusValue: _readDouble(map, 'bonusValue', 'bonus_value'),
      notes: _readString(map, 'notes'),
      createdBy: _readNullableString(map, 'createdBy', 'created_by'),
      createdAt:
          DbValue.toDateTime(_read(map, 'createdAt', 'created_at')) ??
          DateTime.now(),
      updatedAt:
          DbValue.toDateTime(_read(map, 'updatedAt', 'updated_at')) ??
          DateTime.now(),
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
      id: _readString(map, 'id'),
      routeId: _readString(map, 'routeId', 'route_id'),
      purchaseId: _readString(map, 'purchaseId', 'purchase_id'),
      stopType: PurchaseRouteStopType.values.firstWhere(
        (type) => type.name == _readString(map, 'stopType', 'stop_type'),
        orElse: () => PurchaseRouteStopType.delivery,
      ),
      sequence: _readInt(map, 'sequence'),
      address: _readString(map, 'address'),
      supplierName: _readString(map, 'supplierName', 'supplier_name'),
      projectName: _readString(map, 'projectName', 'project_name'),
      status: PurchaseRouteStopStatus.values.firstWhere(
        (status) => status.name == _readString(map, 'status'),
        orElse: () => PurchaseRouteStopStatus.pending,
      ),
      notes: _readString(map, 'notes'),
      completedAt: DbValue.toDateTime(
        _read(map, 'completedAt', 'completed_at'),
      ),
      createdAt:
          DbValue.toDateTime(_read(map, 'createdAt', 'created_at')) ??
          DateTime.now(),
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

dynamic _read(Map<String, dynamic> map, String primary, [String? fallback]) {
  if (map.containsKey(primary)) return map[primary];
  if (fallback != null && map.containsKey(fallback)) return map[fallback];
  return null;
}

String _readString(
  Map<String, dynamic> map,
  String primary, [
  String? fallback,
]) {
  return _read(map, primary, fallback)?.toString() ?? '';
}

String? _readNullableString(
  Map<String, dynamic> map,
  String primary, [
  String? fallback,
]) {
  final value = _read(map, primary, fallback)?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

double _readDouble(
  Map<String, dynamic> map,
  String primary, [
  String? fallback,
]) {
  final value = _read(map, primary, fallback);
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(Map<String, dynamic> map, String primary, [String? fallback]) {
  final value = _read(map, primary, fallback);
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
