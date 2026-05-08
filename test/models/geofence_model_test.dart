import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/geofence_model.dart';

void main() {
  group('GeofenceArea', () {
    test('calcula vertices de cerca quadrada pela coordenada central', () {
      final geofence = GeofenceArea(
        id: 'geo-1',
        name: 'Patio central',
        centerLatitude: 0,
        centerLongitude: 0,
        sideMeters: 100,
        createdAt: DateTime(2026, 5, 8),
        updatedAt: DateTime(2026, 5, 8),
      );

      final vertices = geofence.squareVertices;

      expect(vertices, hasLength(4));
      expect(vertices.first.latitude, closeTo(0.000449, 0.000001));
      expect(vertices.first.longitude, closeTo(-0.000449, 0.000001));
      expect(geofence.areaSquareMeters, 10000);
      expect(geofence.centerCoordinate, '0.000000, 0.000000');
    });

    test('serializa status e medidas da cerca', () {
      final geofence = GeofenceArea(
        id: 'geo-1',
        name: 'Obra Norte',
        code: 'OBRA-123',
        centerLatitude: -23.5,
        centerLongitude: -46.6,
        sideMeters: 180,
        status: GeofenceStatus.draft,
        notes: 'validacao',
        createdAt: DateTime(2026, 5, 8),
        updatedAt: DateTime(2026, 5, 8),
      );

      final map = geofence.toMap();
      expect(map['status'], 'draft');
      expect(map['sideMeters'], 180);

      final parsed = GeofenceArea.fromMap(map, 'geo-1');
      expect(parsed.status, GeofenceStatus.draft);
      expect(parsed.code, 'OBRA-123');
      expect(parsed.centerCoordinate, '-23.500000, -46.600000');
    });
  });
}
