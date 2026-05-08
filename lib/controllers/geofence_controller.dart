import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:project_granith/models/geofence_model.dart';
import 'package:project_granith/services/geofence_service.dart';
import 'package:project_granith/services/service_projetos.dart';

class GeofenceController extends ChangeNotifier {
  final GeofenceService _service;

  GeofenceController({GeofenceService? service})
    : _service = service ?? GeofenceService(projectService: ServiceProjetos());

  List<GeofenceArea> _geofences = [];
  StreamSubscription<List<GeofenceArea>>? _subscription;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String _searchQuery = '';
  GeofenceStatus? _statusFilter;
  String? _selectedGeofenceId;

  List<GeofenceArea> get geofences => _geofences;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  GeofenceStatus? get statusFilter => _statusFilter;
  String? get selectedGeofenceId => _selectedGeofenceId;

  GeofenceArea? get selectedGeofence {
    if (_geofences.isEmpty) return null;
    if (_selectedGeofenceId == null) return _geofences.first;
    for (final item in _geofences) {
      if (item.id == _selectedGeofenceId) return item;
    }
    return _geofences.first;
  }

  List<GeofenceArea> get filteredGeofences {
    var result = List<GeofenceArea>.from(_geofences);

    if (_statusFilter != null) {
      result = result.where((item) => item.status == _statusFilter).toList();
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result =
          result.where((item) {
            return item.name.toLowerCase().contains(query) ||
                item.code.toLowerCase().contains(query) ||
                item.centerCoordinate.toLowerCase().contains(query);
          }).toList();
    }

    result.sort((a, b) {
      final statusCompare = a.status.index.compareTo(b.status.index);
      if (statusCompare != 0) return statusCompare;
      return a.name.compareTo(b.name);
    });
    return result;
  }

  int get totalGeofences => _geofences.length;
  int get activeGeofences =>
      _geofences.where((item) => item.status == GeofenceStatus.active).length;
  int get draftGeofences =>
      _geofences.where((item) => item.status == GeofenceStatus.draft).length;

  double get averageSideMeters {
    if (_geofences.isEmpty) return 0;
    final total = _geofences.fold<double>(
      0,
      (sum, item) => sum + item.sideMeters,
    );
    return total / _geofences.length;
  }

  void init() {
    _setLoading(true);
    _subscription?.cancel();
    _subscription = _service.watchGeofences().listen(
      (items) {
        _geofences = items;
        _selectedGeofenceId ??= items.isEmpty ? null : items.first.id;
        _error = null;
        _setLoading(false);
      },
      onError: (Object error) {
        _error = error.toString();
        _setLoading(false);
      },
    );
  }

  void selectGeofence(String id) {
    if (_selectedGeofenceId == id) return;
    _selectedGeofenceId = id;
    notifyListeners();
  }

  void setSearch(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(GeofenceStatus? value) {
    if (_statusFilter == value) return;
    _statusFilter = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    _setLoading(true);
    try {
      await _service.refreshFromProjects();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<GeofenceArea> createGeofence(GeofenceArea geofence) async {
    return _save(() async {
      final created = await _service.createGeofence(geofence);
      _selectedGeofenceId = created.id;
      return created;
    });
  }

  Future<GeofenceArea> updateGeofence(GeofenceArea geofence) async {
    return _save(() async {
      final updated = await _service.updateGeofence(geofence);
      _selectedGeofenceId = updated.id;
      return updated;
    });
  }

  Future<void> deleteGeofence(String id) async {
    await _save(() async {
      final remaining = _geofences.where((item) => item.id != id).toList();
      await _service.deleteGeofence(id);
      if (_selectedGeofenceId == id) {
        _selectedGeofenceId = remaining.isEmpty ? null : remaining.first.id;
      }
    });
  }

  Future<T> _save<T>(Future<T> Function() operation) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      return await operation();
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
    _service.dispose();
    super.dispose();
  }
}
