import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:project_granith/models/vehicle_model.dart';
import 'package:project_granith/services/vehicle_service.dart';

class FakeVehicleService extends VehicleService {
  FakeVehicleService({List<Vehicle>? initialVehicles})
    : _vehicles = List<Vehicle>.from(initialVehicles ?? const <Vehicle>[]);

  final List<Vehicle> _vehicles;
  final StreamController<List<Vehicle>> _controller =
      StreamController<List<Vehicle>>.broadcast();

  Vehicle? lastCreatedVehicle;
  Vehicle? lastUpdatedVehicle;
  String? lastDeletedId;
  Object? createError;
  Object? updateError;
  Object? deleteError;

  void emit([List<Vehicle>? vehicles]) {
    if (vehicles != null) {
      _vehicles
        ..clear()
        ..addAll(vehicles);
    }
    _controller.add(List<Vehicle>.from(_vehicles));
  }

  @override
  Stream<List<Vehicle>> watchVehicles() => _controller.stream;

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    if (createError != null) throw createError!;
    final created = vehicle.copyWith(
      id: vehicle.id.isEmpty ? 'generated-vehicle-id' : vehicle.id,
      plate: vehicle.normalizedPlate,
    );
    lastCreatedVehicle = created;
    _vehicles.add(created);
    emit();
    return created;
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    if (updateError != null) throw updateError!;
    final updated = vehicle.copyWith(plate: vehicle.normalizedPlate);
    lastUpdatedVehicle = updated;
    final index = _vehicles.indexWhere((item) => item.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = updated;
    }
    emit();
    return updated;
  }

  @override
  Future<void> deleteVehicle(String id) async {
    if (deleteError != null) throw deleteError!;
    lastDeletedId = id;
    _vehicles.removeWhere((item) => item.id == id);
    emit();
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class FakeVehicleFipeService extends VehicleFipeService {
  FakeVehicleFipeService({this.result, this.error})
    : super(client: _NoopHttpClient());

  final VehicleFipeInfo? result;
  final Object? error;
  String? lastCode;

  @override
  Future<VehicleFipeInfo?> fetchByCode(String fipeCode) async {
    lastCode = fipeCode;
    if (error != null) throw error!;
    return result;
  }

  @override
  void dispose() {}
}

class _NoopHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw StateError('HTTP nao deve ser chamado no teste.');
  }
}
