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
  });
}
