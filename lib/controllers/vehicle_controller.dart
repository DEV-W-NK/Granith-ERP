import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:project_granith/models/vehicle_model.dart';
import 'package:project_granith/services/vehicle_service.dart';

class VehicleController extends ChangeNotifier {
  final VehicleService _service;
  final VehicleFipeService _fipeService;

  VehicleController({VehicleService? service, VehicleFipeService? fipeService})
    : _service = service ?? VehicleService(),
      _fipeService = fipeService ?? VehicleFipeService();

  List<Vehicle> _vehicles = [];
  StreamSubscription<List<Vehicle>>? _subscription;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String _searchQuery = '';
  VehicleStatus? _statusFilter;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  VehicleStatus? get statusFilter => _statusFilter;

  List<Vehicle> get filteredVehicles {
    var result = List<Vehicle>.from(_vehicles);

    if (_statusFilter != null) {
      result = result.where((item) => item.status == _statusFilter).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result =
          result.where((item) {
            return item.plate.toLowerCase().contains(query) ||
                item.brand.toLowerCase().contains(query) ||
                item.model.toLowerCase().contains(query) ||
                item.version.toLowerCase().contains(query) ||
                item.assignedEmployeeName.toLowerCase().contains(query);
          }).toList();
    }

    result.sort((a, b) {
      final statusCompare = a.status.index.compareTo(b.status.index);
      if (statusCompare != 0) return statusCompare;
      return a.displayName.compareTo(b.displayName);
    });
    return result;
  }

  int get totalVehicles => _vehicles.length;
  int get activeVehicles =>
      _vehicles.where((item) => item.status == VehicleStatus.active).length;
  int get maintenanceVehicles =>
      _vehicles
          .where((item) => item.status == VehicleStatus.maintenance)
          .length;
  int get vehiclesUnderExpected =>
      _vehicles.where((item) => item.isUnderExpectedConsumption).length;

  double get averageFleetAge {
    if (_vehicles.isEmpty) return 0;
    final currentYear = DateTime.now().year;
    final totalAge = _vehicles.fold<int>(
      0,
      (sum, item) => sum + (currentYear - item.modelYear).clamp(0, 80),
    );
    return totalAge / _vehicles.length;
  }

  void init() {
    _setLoading(true);
    _subscription?.cancel();
    _subscription = _service.watchVehicles().listen(
      (items) {
        _vehicles = items;
        _error = null;
        _setLoading(false);
      },
      onError: (Object error) {
        _error = error.toString();
        _setLoading(false);
      },
    );
  }

  void setSearch(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(VehicleStatus? value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    notifyListeners();
  }

  Future<void> createVehicle(Vehicle vehicle) async {
    await _save(() => _service.createVehicle(vehicle));
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _save(() => _service.updateVehicle(vehicle));
  }

  Future<void> deleteVehicle(String id) async {
    await _save(() => _service.deleteVehicle(id));
  }

  Future<VehicleFipeInfo?> fetchFipe(String code) async {
    try {
      _error = null;
      notifyListeners();
      return await _fipeService.fetchByCode(code);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _save(Future<dynamic> Function() operation) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await operation();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _fipeService.dispose();
    super.dispose();
  }
}
