import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/geofence_controller.dart';
import 'package:project_granith/models/geofence_model.dart';
import 'package:project_granith/services/geofence_service.dart';

GeofenceArea _geofence({
  required String id,
  required String name,
  GeofenceStatus status = GeofenceStatus.active,
}) {
  return GeofenceArea(
    id: id,
    name: name,
    code: 'OBRA-$id',
    centerLatitude: -23.55,
    centerLongitude: -46.63,
    sideMeters: 120,
    status: status,
    createdAt: DateTime(2026, 5, 8),
    updatedAt: DateTime(2026, 5, 8),
  );
}

void main() {
  group('GeofenceController', () {
    test('sincroniza stream, filtra e seleciona cercas', () async {
      final service = GeofenceService(
        seedDefaults: false,
        initialItems: [
          _geofence(id: '1', name: 'Obra Sul'),
          _geofence(id: '2', name: 'Patio Norte', status: GeofenceStatus.draft),
        ],
      );
      final controller = GeofenceController(service: service)..init();
      await Future<void>.delayed(Duration.zero);

      expect(controller.totalGeofences, 2);
      expect(controller.activeGeofences, 1);
      expect(controller.selectedGeofence?.name, 'Obra Sul');

      controller.setSearch('norte');
      expect(controller.filteredGeofences, hasLength(1));
      expect(controller.filteredGeofences.single.name, 'Patio Norte');

      controller.setStatusFilter(GeofenceStatus.draft);
      expect(controller.filteredGeofences.single.status, GeofenceStatus.draft);

      controller.selectGeofence('2');
      expect(controller.selectedGeofence?.id, '2');

      controller.dispose();
    });

    test('cria e remove cerca mantendo selecao consistente', () async {
      final service = GeofenceService(seedDefaults: false);
      final controller = GeofenceController(service: service)..init();
      await Future<void>.delayed(Duration.zero);

      final created = await controller.createGeofence(
        _geofence(id: '', name: 'Nova obra'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(created.id, isNotEmpty);
      expect(controller.totalGeofences, 1);
      expect(controller.selectedGeofenceId, created.id);

      await controller.deleteGeofence(created.id);
      await Future<void>.delayed(Duration.zero);

      expect(controller.totalGeofences, 0);
      expect(controller.selectedGeofence, isNull);

      controller.dispose();
    });
  });
}
