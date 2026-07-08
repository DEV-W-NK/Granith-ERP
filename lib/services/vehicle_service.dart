import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/vehicle_model.dart';
import 'package:project_granith/services/mobile_push_dispatch_service.dart';

class VehicleService {
  static const _table = 'vehicles';
  static const _fuelLogsTable = 'vehicle_fuel_logs';

  Stream<List<Vehicle>> watchVehicles() {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('updatedAt', ascending: false)
        .map((rows) => rows.map(_vehicleFromRow).toList());
  }

  Future<List<Vehicle>> getVehicles() async {
    final rows = await AppSupabase.client
        .from(_table)
        .select()
        .order('updatedAt', ascending: false);
    return (rows as List)
        .map((row) => _vehicleFromRow(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<Vehicle?> getVehicle(String id) async {
    final row =
        await AppSupabase.client
            .from(_table)
            .select()
            .eq('id', id)
            .maybeSingle();
    if (row == null) return null;
    return _vehicleFromRow(Map<String, dynamic>.from(row));
  }

  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final now = DateTime.now();
    final data =
        vehicle.copyWith(createdAt: now, updatedAt: now).toMap()..remove('id');

    final row =
        await AppSupabase.client
            .from(_table)
            .insert(DbValue.normalizeMap(data))
            .select('id')
            .single();

    final created = vehicle.copyWith(
      id: row['id'] as String,
      plate: vehicle.normalizedPlate,
      createdAt: now,
      updatedAt: now,
    );
    _notifyVehiclesChanged();
    return created;
  }

  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    final updated = vehicle.copyWith(
      plate: vehicle.normalizedPlate,
      updatedAt: DateTime.now(),
    );

    await AppSupabase.client
        .from(_table)
        .update(DbValue.normalizeMap(updated.toMap()))
        .eq('id', vehicle.id);

    _notifyVehiclesChanged();
    return updated;
  }

  Future<void> deleteVehicle(String id) async {
    await AppSupabase.client.from(_table).delete().eq('id', id);
    _notifyVehiclesChanged();
  }

  Stream<List<VehicleFuelLog>> watchFuelLogs(String vehicleId) {
    return AppSupabase.client
        .from(_fuelLogsTable)
        .stream(primaryKey: ['id'])
        .eq('vehicleId', vehicleId)
        .order('fuelingDate', ascending: false)
        .map((rows) => rows.map(_fuelLogFromRow).toList());
  }

  Future<String> addFuelLog(VehicleFuelLog log) async {
    final data = DbValue.normalizeMap(log.toMap());
    if (log.id.isNotEmpty) {
      data['id'] = log.id;
    }

    final row =
        await AppSupabase.client
            .from(_fuelLogsTable)
            .insert(data)
            .select('id')
            .single();

    await AppSupabase.client
        .from(_table)
        .update({
          'odometerKm': log.odometerKm,
          'lastMeasuredKmPerLiter': log.kmPerLiter,
          'lastFuelLogAt': DbValue.toPrimitive(log.fuelingDate),
          'updatedAt': DbValue.toPrimitive(DateTime.now()),
        })
        .eq('id', log.vehicleId);

    final id = row['id'] as String;
    _notifyVehiclesChanged(
      extraScopes: const [AppDataRefreshBus.vehicleFuelLogs],
    );
    return id;
  }

  Vehicle _vehicleFromRow(dynamic row) {
    final data = Map<String, dynamic>.from(row as Map);
    return Vehicle.fromMap(data, data['id'] as String? ?? '');
  }

  VehicleFuelLog _fuelLogFromRow(dynamic row) {
    final data = Map<String, dynamic>.from(row as Map);
    return VehicleFuelLog.fromMap(data, data['id'] as String? ?? '');
  }

  void _notifyVehiclesChanged({List<String> extraScopes = const []}) {
    AppDataRefreshBus.instance.notify(
      scopes: [AppDataRefreshBus.vehicles, ...extraScopes],
      source: 'VehicleService',
    );
    unawaited(MobilePushDispatchService.dispatchPending());
  }
}

class VehicleFipeService {
  static const _baseUrl = 'https://brasilapi.com.br/api/fipe/preco/v1';
  static const _timeout = Duration(seconds: 20);

  final http.Client _client;

  VehicleFipeService({http.Client? client}) : _client = client ?? http.Client();

  Future<VehicleFipeInfo?> fetchByCode(String fipeCode) async {
    final cleanCode = fipeCode.trim();
    if (cleanCode.isEmpty) return null;

    final uri = Uri.parse('$_baseUrl/$cleanCode');
    final response = await _client.get(uri).timeout(_timeout);

    if (response.statusCode == 404) {
      throw VehicleFipeException('Codigo FIPE nao encontrado.');
    }
    if (response.statusCode != 200) {
      throw VehicleFipeException(
        'Falha ao consultar FIPE (${response.statusCode}).',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      return null;
    }

    return VehicleFipeInfo.fromJson(
      Map<String, dynamic>.from(decoded.first as Map),
    );
  }

  void dispose() {
    _client.close();
  }
}

class VehicleFipeInfo {
  final String brand;
  final String model;
  final int modelYear;
  final VehicleFuelType fuelType;
  final String fipeCode;
  final double? fipeValue;
  final String referenceMonth;

  const VehicleFipeInfo({
    required this.brand,
    required this.model,
    required this.modelYear,
    required this.fuelType,
    required this.fipeCode,
    this.fipeValue,
    required this.referenceMonth,
  });

  factory VehicleFipeInfo.fromJson(Map<String, dynamic> json) {
    return VehicleFipeInfo(
      brand: json['marca'] as String? ?? '',
      model: json['modelo'] as String? ?? '',
      modelYear: (json['anoModelo'] as num?)?.toInt() ?? DateTime.now().year,
      fuelType: _fuelTypeFromFipe(json['combustivel'] as String? ?? ''),
      fipeCode: json['codigoFipe'] as String? ?? '',
      fipeValue: _parseCurrency(json['valor'] as String?),
      referenceMonth: json['mesReferencia'] as String? ?? '',
    );
  }
}

class VehicleFipeException implements Exception {
  final String message;

  VehicleFipeException(this.message);

  @override
  String toString() => message;
}

VehicleFuelType _fuelTypeFromFipe(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('diesel')) return VehicleFuelType.diesel;
  if (normalized.contains('gasolina')) return VehicleFuelType.gasoline;
  if (normalized.contains('alcool') || normalized.contains('etanol')) {
    return VehicleFuelType.ethanol;
  }
  if (normalized.contains('eletric')) return VehicleFuelType.electric;
  if (normalized.contains('hibrid')) return VehicleFuelType.hybrid;
  return VehicleFuelType.other;
}

double? _parseCurrency(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final normalized =
      value
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
  return double.tryParse(normalized);
}
