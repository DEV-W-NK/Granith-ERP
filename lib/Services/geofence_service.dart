import 'dart:async';

import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/models/geofence_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/service_projetos.dart';
import 'package:uuid/uuid.dart';

class GeofenceService {
  final _uuid = const Uuid();
  final _streamController = StreamController<List<GeofenceArea>>.broadcast();
  final ServiceProjetos? _projectService;
  final List<GeofenceArea> _items;

  GeofenceService({
    ServiceProjetos? projectService,
    List<GeofenceArea>? initialItems,
    bool seedDefaults = true,
  }) : _projectService = projectService,
       _items = List<GeofenceArea>.from(
         initialItems ?? (seedDefaults ? _seedGeofences() : const []),
       );

  Stream<List<GeofenceArea>> watchGeofences() {
    if (_projectService != null) {
      Future.microtask(refreshFromProjects);
    } else {
      Future.microtask(_emit);
    }
    return _streamController.stream;
  }

  Future<List<GeofenceArea>> getGeofences() async {
    if (_projectService != null) {
      await refreshFromProjects();
    }
    return List<GeofenceArea>.unmodifiable(_items);
  }

  Future<void> refreshFromProjects() async {
    final service = _projectService;
    if (service == null) return;

    final projects = await service.getProjects();
    _items
      ..clear()
      ..addAll(
        projects
            .where((project) => project.hasGeofence)
            .map(_geofenceFromProject),
      );
    _emit();
  }

  Future<GeofenceArea> createGeofence(GeofenceArea geofence) async {
    final now = DateTime.now();
    final created = geofence.copyWith(
      id: geofence.id.isEmpty ? _uuid.v4() : geofence.id,
      createdAt: now,
      updatedAt: now,
    );

    _items.add(created);
    _emit();
    _notifyGeofencesChanged();
    return created;
  }

  Future<GeofenceArea> updateGeofence(GeofenceArea geofence) async {
    final index = _items.indexWhere((item) => item.id == geofence.id);
    if (index == -1) {
      throw GeofenceServiceException('Cerca nao encontrada.');
    }

    final updated = geofence.copyWith(updatedAt: DateTime.now());
    _items[index] = updated;
    _emit();
    _notifyGeofencesChanged();
    return updated;
  }

  Future<void> deleteGeofence(String id) async {
    _items.removeWhere((item) => item.id == id);
    _emit();
    _notifyGeofencesChanged();
  }

  void dispose() {
    _streamController.close();
  }

  void _emit() {
    if (_streamController.isClosed) return;
    _streamController.add(List<GeofenceArea>.unmodifiable(_items));
  }

  void _notifyGeofencesChanged() {
    AppDataRefreshBus.instance.notify(
      scopes: const [AppDataRefreshBus.geofences],
      source: 'GeofenceService',
    );
  }
}

class GeofenceServiceException implements Exception {
  final String message;

  GeofenceServiceException(this.message);

  @override
  String toString() => message;
}

GeofenceArea _geofenceFromProject(Project project) {
  return GeofenceArea(
    id: 'project-${project.id}',
    projectId: project.id,
    name: project.name,
    code: project.client,
    centerLatitude: project.latitude!,
    centerLongitude: project.longitude!,
    sideMeters: project.geofenceSideMeters,
    status: switch (project.status) {
      ProjectStatus.planning => GeofenceStatus.draft,
      ProjectStatus.inProgress => GeofenceStatus.active,
      ProjectStatus.completed => GeofenceStatus.inactive,
    },
    notes: project.location,
    createdAt: project.startDate,
    updatedAt: project.lastMeasurementAt ?? DateTime.now(),
  );
}

List<GeofenceArea> _seedGeofences() {
  final now = DateTime(2026, 5, 8);
  return [
    GeofenceArea(
      id: 'seed-geofence-1',
      name: 'Obra Matriz',
      code: 'OBRA-001',
      centerLatitude: -23.55052,
      centerLongitude: -46.633308,
      sideMeters: 140,
      status: GeofenceStatus.active,
      notes: 'Base operacional inicial para validacao do modulo.',
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
