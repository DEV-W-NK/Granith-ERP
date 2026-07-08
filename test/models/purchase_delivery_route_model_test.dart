import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/purchase_delivery_route_model.dart';

void main() {
  group('PurchaseDeliveryRoute', () {
    test('fromMap restaura rota e parada de entrega/coleta', () {
      final now = DateTime(2026, 5, 9, 10);
      final route = PurchaseDeliveryRoute.fromMap({
        'id': 'route-1',
        'name': 'Rota Joao',
        'driverId': 'driver-1',
        'driverName': 'Joao',
        'status': 'completed',
        'scheduledDate': now.toIso8601String(),
        'actualDistanceKm': 42.5,
        'kmRate': 2.5,
        'bonusValue': 106.25,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
      final stop = PurchaseDeliveryRouteStop.fromMap({
        'id': 'stop-1',
        'routeId': 'route-1',
        'purchaseId': 'purchase-1',
        'stopType': 'pickup',
        'sequence': 1,
        'address': 'CD Fornecedor',
        'supplierName': 'Fornecedor A',
        'projectName': 'Obra Alfa',
        'status': 'pending',
        'createdAt': now.toIso8601String(),
      });

      expect(route.status, PurchaseRouteStatus.completed);
      expect(route.actualDistanceKm, 42.5);
      expect(route.bonusValue, 106.25);
      expect(stop.stopType, PurchaseRouteStopType.pickup);
      expect(stop.sequence, 1);
      expect(stop.address, 'CD Fornecedor');
    });

    test('fromMap aceita nomes snake_case vindos do banco/mobile', () {
      final now = DateTime(2026, 5, 9, 10);
      final route = PurchaseDeliveryRoute.fromMap({
        'id': 'route-2',
        'name': 'Rota Mobile',
        'driver_id': 'driver-mobile',
        'driver_name': 'Maria',
        'status': 'inProgress',
        'scheduled_date': now.toIso8601String(),
        'estimated_distance_km': '18.5',
        'actual_distance_km': 21,
        'km_rate': '2.75',
        'bonus_value': 57.75,
        'created_by': 'admin',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      final stop = PurchaseDeliveryRouteStop.fromMap({
        'id': 'stop-2',
        'route_id': 'route-2',
        'purchase_id': 'purchase-2',
        'stop_type': 'delivery',
        'sequence': '2',
        'address': 'Rua Mobile, 10',
        'supplier_name': 'Fornecedor Mobile',
        'project_name': 'Obra Mobile',
        'status': 'completed',
        'completed_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
      });

      expect(route.driverId, 'driver-mobile');
      expect(route.driverName, 'Maria');
      expect(route.status, PurchaseRouteStatus.inProgress);
      expect(route.estimatedDistanceKm, 18.5);
      expect(route.kmRate, 2.75);
      expect(route.createdBy, 'admin');
      expect(stop.routeId, 'route-2');
      expect(stop.purchaseId, 'purchase-2');
      expect(stop.stopType, PurchaseRouteStopType.delivery);
      expect(stop.sequence, 2);
      expect(stop.supplierName, 'Fornecedor Mobile');
      expect(stop.completedAt, now);
    });
  });
}
