import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';

enum VehicleStatus { active, maintenance, inactive }

extension VehicleStatusUi on VehicleStatus {
  String get label {
    switch (this) {
      case VehicleStatus.active:
        return 'Ativo';
      case VehicleStatus.maintenance:
        return 'Manutencao';
      case VehicleStatus.inactive:
        return 'Inativo';
    }
  }

  Color get color {
    switch (this) {
      case VehicleStatus.active:
        return Colors.greenAccent;
      case VehicleStatus.maintenance:
        return Colors.orangeAccent;
      case VehicleStatus.inactive:
        return Colors.redAccent;
    }
  }
}

enum VehicleFuelType {
  gasoline,
  ethanol,
  flex,
  diesel,
  hybrid,
  electric,
  other,
}

extension VehicleFuelTypeUi on VehicleFuelType {
  String get label {
    switch (this) {
      case VehicleFuelType.gasoline:
        return 'Gasolina';
      case VehicleFuelType.ethanol:
        return 'Etanol';
      case VehicleFuelType.flex:
        return 'Flex';
      case VehicleFuelType.diesel:
        return 'Diesel';
      case VehicleFuelType.hybrid:
        return 'Hibrido';
      case VehicleFuelType.electric:
        return 'Eletrico';
      case VehicleFuelType.other:
        return 'Outro';
    }
  }
}

class Vehicle {
  final String id;
  final String plate;
  final String brand;
  final String model;
  final String version;
  final int manufactureYear;
  final int modelYear;
  final VehicleFuelType fuelType;
  final VehicleStatus status;
  final double odometerKm;
  final double expectedCityKmPerLiter;
  final double expectedHighwayKmPerLiter;
  final double tankCapacityLiters;
  final String? assignedEmployeeId;
  final String assignedEmployeeName;
  final DateTime? acquisitionDate;
  final double acquisitionValue;
  final String? fipeCode;
  final double? fipeValue;
  final String? fipeReferenceMonth;
  final double? lastMeasuredKmPerLiter;
  final DateTime? lastFuelLogAt;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    this.version = '',
    required this.manufactureYear,
    required this.modelYear,
    this.fuelType = VehicleFuelType.flex,
    this.status = VehicleStatus.active,
    this.odometerKm = 0,
    this.expectedCityKmPerLiter = 0,
    this.expectedHighwayKmPerLiter = 0,
    this.tankCapacityLiters = 0,
    this.assignedEmployeeId,
    this.assignedEmployeeName = '',
    this.acquisitionDate,
    this.acquisitionValue = 0,
    this.fipeCode,
    this.fipeValue,
    this.fipeReferenceMonth,
    this.lastMeasuredKmPerLiter,
    this.lastFuelLogAt,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName {
    final versionSuffix = version.trim().isEmpty ? '' : ' $version';
    return '$brand $model$versionSuffix'.trim();
  }

  String get yearLabel {
    if (manufactureYear == modelYear) return '$modelYear';
    return '$manufactureYear/$modelYear';
  }

  String get normalizedPlate =>
      plate.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  double get expectedAverageKmPerLiter {
    final values = [
      if (expectedCityKmPerLiter > 0) expectedCityKmPerLiter,
      if (expectedHighwayKmPerLiter > 0) expectedHighwayKmPerLiter,
    ];
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double? get consumptionDeltaPercent {
    final measured = lastMeasuredKmPerLiter;
    final expected = expectedAverageKmPerLiter;
    if (measured == null || measured <= 0 || expected <= 0) return null;
    return ((measured - expected) / expected) * 100;
  }

  bool get isUnderExpectedConsumption {
    final delta = consumptionDeltaPercent;
    return delta != null && delta < -12;
  }

  factory Vehicle.fromMap(Map<String, dynamic> map, String id) {
    return Vehicle(
      id: id,
      plate: map['plate'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      model: map['model'] as String? ?? '',
      version: map['version'] as String? ?? '',
      manufactureYear: _toInt(map['manufactureYear']),
      modelYear: _toInt(map['modelYear']),
      fuelType: _enumFromName(
        VehicleFuelType.values,
        map['fuelType'],
        VehicleFuelType.flex,
      ),
      status: _enumFromName(
        VehicleStatus.values,
        map['status'],
        VehicleStatus.active,
      ),
      odometerKm: _toDouble(map['odometerKm']),
      expectedCityKmPerLiter: _toDouble(map['expectedCityKmPerLiter']),
      expectedHighwayKmPerLiter: _toDouble(map['expectedHighwayKmPerLiter']),
      tankCapacityLiters: _toDouble(map['tankCapacityLiters']),
      assignedEmployeeId: map['assignedEmployeeId'] as String?,
      assignedEmployeeName: map['assignedEmployeeName'] as String? ?? '',
      acquisitionDate: DbValue.toDateTime(map['acquisitionDate']),
      acquisitionValue: _toDouble(map['acquisitionValue']),
      fipeCode: map['fipeCode'] as String?,
      fipeValue: (map['fipeValue'] as num?)?.toDouble(),
      fipeReferenceMonth: map['fipeReferenceMonth'] as String?,
      lastMeasuredKmPerLiter:
          (map['lastMeasuredKmPerLiter'] as num?)?.toDouble(),
      lastFuelLogAt: DbValue.toDateTime(map['lastFuelLogAt']),
      notes: map['notes'] as String? ?? '',
      createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: DbValue.toDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plate': normalizedPlate,
      'brand': brand.trim(),
      'model': model.trim(),
      'version': version.trim(),
      'manufactureYear': manufactureYear,
      'modelYear': modelYear,
      'fuelType': fuelType.name,
      'status': status.name,
      'odometerKm': odometerKm,
      'expectedCityKmPerLiter': expectedCityKmPerLiter,
      'expectedHighwayKmPerLiter': expectedHighwayKmPerLiter,
      'tankCapacityLiters': tankCapacityLiters,
      'assignedEmployeeId': assignedEmployeeId,
      'assignedEmployeeName': assignedEmployeeName.trim(),
      'acquisitionDate': DbValue.toPrimitive(acquisitionDate),
      'acquisitionValue': acquisitionValue,
      'fipeCode': fipeCode,
      'fipeValue': fipeValue,
      'fipeReferenceMonth': fipeReferenceMonth,
      'lastMeasuredKmPerLiter': lastMeasuredKmPerLiter,
      'lastFuelLogAt': DbValue.toPrimitive(lastFuelLogAt),
      'notes': notes.trim(),
      'createdAt': DbValue.toPrimitive(createdAt),
      'updatedAt': DbValue.toPrimitive(updatedAt),
    };
  }

  Vehicle copyWith({
    String? id,
    String? plate,
    String? brand,
    String? model,
    String? version,
    int? manufactureYear,
    int? modelYear,
    VehicleFuelType? fuelType,
    VehicleStatus? status,
    double? odometerKm,
    double? expectedCityKmPerLiter,
    double? expectedHighwayKmPerLiter,
    double? tankCapacityLiters,
    String? assignedEmployeeId,
    String? assignedEmployeeName,
    DateTime? acquisitionDate,
    double? acquisitionValue,
    String? fipeCode,
    double? fipeValue,
    String? fipeReferenceMonth,
    double? lastMeasuredKmPerLiter,
    DateTime? lastFuelLogAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      version: version ?? this.version,
      manufactureYear: manufactureYear ?? this.manufactureYear,
      modelYear: modelYear ?? this.modelYear,
      fuelType: fuelType ?? this.fuelType,
      status: status ?? this.status,
      odometerKm: odometerKm ?? this.odometerKm,
      expectedCityKmPerLiter:
          expectedCityKmPerLiter ?? this.expectedCityKmPerLiter,
      expectedHighwayKmPerLiter:
          expectedHighwayKmPerLiter ?? this.expectedHighwayKmPerLiter,
      tankCapacityLiters: tankCapacityLiters ?? this.tankCapacityLiters,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      assignedEmployeeName: assignedEmployeeName ?? this.assignedEmployeeName,
      acquisitionDate: acquisitionDate ?? this.acquisitionDate,
      acquisitionValue: acquisitionValue ?? this.acquisitionValue,
      fipeCode: fipeCode ?? this.fipeCode,
      fipeValue: fipeValue ?? this.fipeValue,
      fipeReferenceMonth: fipeReferenceMonth ?? this.fipeReferenceMonth,
      lastMeasuredKmPerLiter:
          lastMeasuredKmPerLiter ?? this.lastMeasuredKmPerLiter,
      lastFuelLogAt: lastFuelLogAt ?? this.lastFuelLogAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VehicleFuelLog {
  final String id;
  final String vehicleId;
  final String vehiclePlate;
  final String employeeId;
  final String employeeName;
  final double liters;
  final double totalAmount;
  final double unitPrice;
  final double odometerKm;
  final double? previousOdometerKm;
  final double? kmTraveled;
  final double? kmPerLiter;
  final DateTime fuelingDate;
  final String? financialTransactionId;
  final String invoiceNumber;
  final String notes;
  final DateTime createdAt;

  const VehicleFuelLog({
    required this.id,
    required this.vehicleId,
    required this.vehiclePlate,
    required this.employeeId,
    required this.employeeName,
    required this.liters,
    required this.totalAmount,
    required this.unitPrice,
    required this.odometerKm,
    this.previousOdometerKm,
    this.kmTraveled,
    this.kmPerLiter,
    required this.fuelingDate,
    this.financialTransactionId,
    this.invoiceNumber = '',
    this.notes = '',
    required this.createdAt,
  });

  factory VehicleFuelLog.fromMap(Map<String, dynamic> map, String id) {
    return VehicleFuelLog(
      id: id,
      vehicleId: map['vehicleId'] as String? ?? '',
      vehiclePlate: map['vehiclePlate'] as String? ?? '',
      employeeId: map['employeeId'] as String? ?? '',
      employeeName: map['employeeName'] as String? ?? '',
      liters: _toDouble(map['liters']),
      totalAmount: _toDouble(map['totalAmount']),
      unitPrice: _toDouble(map['unitPrice']),
      odometerKm: _toDouble(map['odometerKm']),
      previousOdometerKm: (map['previousOdometerKm'] as num?)?.toDouble(),
      kmTraveled: (map['kmTraveled'] as num?)?.toDouble(),
      kmPerLiter: (map['kmPerLiter'] as num?)?.toDouble(),
      fuelingDate: DbValue.toDateTime(map['fuelingDate']) ?? DateTime.now(),
      financialTransactionId: map['financialTransactionId'] as String?,
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'vehiclePlate': vehiclePlate,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'liters': liters,
      'totalAmount': totalAmount,
      'unitPrice': unitPrice,
      'odometerKm': odometerKm,
      'previousOdometerKm': previousOdometerKm,
      'kmTraveled': kmTraveled,
      'kmPerLiter': kmPerLiter,
      'fuelingDate': DbValue.toPrimitive(fuelingDate),
      'financialTransactionId': financialTransactionId,
      'invoiceNumber': invoiceNumber,
      'notes': notes,
      'createdAt': DbValue.toPrimitive(createdAt),
    };
  }
}

T _enumFromName<T extends Enum>(List<T> values, dynamic name, T fallback) {
  if (name == null) return fallback;
  return values.firstWhere(
    (value) => value.name == name.toString(),
    orElse: () => fallback,
  );
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? DateTime.now().year;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
}
