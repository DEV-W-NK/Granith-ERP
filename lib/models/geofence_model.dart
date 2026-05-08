import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';

enum GeofenceStatus { active, draft, inactive }

extension GeofenceStatusUi on GeofenceStatus {
  String get label {
    switch (this) {
      case GeofenceStatus.active:
        return 'Ativa';
      case GeofenceStatus.draft:
        return 'Rascunho';
      case GeofenceStatus.inactive:
        return 'Inativa';
    }
  }

  Color get color {
    switch (this) {
      case GeofenceStatus.active:
        return Colors.greenAccent;
      case GeofenceStatus.draft:
        return Colors.orangeAccent;
      case GeofenceStatus.inactive:
        return Colors.redAccent;
    }
  }
}

class GeofencePoint {
  final double latitude;
  final double longitude;

  const GeofencePoint({required this.latitude, required this.longitude});

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }

  factory GeofencePoint.fromMap(Map<String, dynamic> map) {
    return GeofencePoint(
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
    );
  }
}

class GeofenceArea {
  static const double _metersPerLatitudeDegree = 111320;

  final String id;
  final String? projectId;
  final String name;
  final String code;
  final double centerLatitude;
  final double centerLongitude;
  final double sideMeters;
  final GeofenceStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeofenceArea({
    required this.id,
    this.projectId,
    required this.name,
    this.code = '',
    required this.centerLatitude,
    required this.centerLongitude,
    required this.sideMeters,
    this.status = GeofenceStatus.active,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  String get centerCoordinate =>
      '${centerLatitude.toStringAsFixed(6)}, ${centerLongitude.toStringAsFixed(6)}';

  String get sideLabel => '${sideMeters.toStringAsFixed(0)} m';

  double get areaSquareMeters => sideMeters * sideMeters;

  bool get hasValidCoordinates {
    return centerLatitude >= -90 &&
        centerLatitude <= 90 &&
        centerLongitude >= -180 &&
        centerLongitude <= 180 &&
        sideMeters > 0;
  }

  List<GeofencePoint> get squareVertices {
    final halfSide = sideMeters / 2;
    final latitudeOffset = halfSide / _metersPerLatitudeDegree;
    final latitudeRadians = centerLatitude * math.pi / 180;
    final longitudeMetersPerDegree =
        _metersPerLatitudeDegree *
        math.max(0.000001, math.cos(latitudeRadians).abs());
    final longitudeOffset = halfSide / longitudeMetersPerDegree;

    return [
      GeofencePoint(
        latitude: centerLatitude + latitudeOffset,
        longitude: centerLongitude - longitudeOffset,
      ),
      GeofencePoint(
        latitude: centerLatitude + latitudeOffset,
        longitude: centerLongitude + longitudeOffset,
      ),
      GeofencePoint(
        latitude: centerLatitude - latitudeOffset,
        longitude: centerLongitude + longitudeOffset,
      ),
      GeofencePoint(
        latitude: centerLatitude - latitudeOffset,
        longitude: centerLongitude - longitudeOffset,
      ),
    ];
  }

  factory GeofenceArea.fromMap(Map<String, dynamic> map, String id) {
    return GeofenceArea(
      id: id,
      projectId: map['projectId'] as String? ?? map['project_id'] as String?,
      name: map['name'] as String? ?? '',
      code: map['code'] as String? ?? '',
      centerLatitude: _toDouble(map['centerLatitude']),
      centerLongitude: _toDouble(map['centerLongitude']),
      sideMeters: _toDouble(map['sideMeters']),
      status: _enumFromName(
        GeofenceStatus.values,
        map['status'],
        GeofenceStatus.active,
      ),
      notes: map['notes'] as String? ?? '',
      createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: DbValue.toDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'projectId': projectId,
      'project_id': projectId,
      'code': code.trim(),
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'sideMeters': sideMeters,
      'status': status.name,
      'notes': notes.trim(),
      'createdAt': DbValue.toPrimitive(createdAt),
      'updatedAt': DbValue.toPrimitive(updatedAt),
    };
  }

  GeofenceArea copyWith({
    String? id,
    String? projectId,
    String? name,
    String? code,
    double? centerLatitude,
    double? centerLongitude,
    double? sideMeters,
    GeofenceStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GeofenceArea(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      code: code ?? this.code,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      sideMeters: sideMeters ?? this.sideMeters,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

T _enumFromName<T extends Enum>(List<T> values, dynamic value, T fallback) {
  final name = value?.toString();
  if (name == null || name.isEmpty) return fallback;
  return values.firstWhere((item) => item.name == name, orElse: () => fallback);
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }
  return 0;
}
