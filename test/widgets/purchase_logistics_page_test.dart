import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/purchase_delivery_route_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/services/purchase_delivery_route_service.dart';
import 'package:project_granith/widgets/purchase_logistics/purchase_logistics_page_widgets.dart';

class _FakePurchaseDeliveryRouteService extends PurchaseDeliveryRouteService {
  _FakePurchaseDeliveryRouteService({
    required this.candidates,
    required this.routes,
    this.drivers = const [],
    this.stops = const {},
  });

  final List<Purchase> candidates;
  final List<PurchaseDeliveryRoute> routes;
  final List<PurchaseRouteDriver> drivers;
  final Map<String, List<PurchaseDeliveryRouteStop>> stops;

  String? lastRouteName;
  String? lastDriverId;
  String? lastDriverName;
  DateTime? lastScheduledDate;
  List<Purchase>? lastPurchases;
  String? lastNotes;
  String? lastUpdatedRouteId;
  PurchaseRouteStatus? lastUpdatedStatus;

  @override
  Future<List<Purchase>> fetchRouteCandidates() async {
    return candidates;
  }

  @override
  Stream<List<PurchaseDeliveryRoute>> watchRoutes() {
    return Stream.value(routes);
  }

  @override
  Future<List<PurchaseRouteDriver>> fetchAvailableDrivers() async {
    return drivers;
  }

  @override
  Stream<List<PurchaseDeliveryRouteStop>> watchStops(String routeId) {
    return Stream.value(stops[routeId] ?? const []);
  }

  @override
  Future<String> createRoute({
    required String name,
    required String driverName,
    String? driverId,
    DateTime? scheduledDate,
    required List<Purchase> purchases,
    String notes = '',
    String? createdBy,
  }) async {
    lastRouteName = name;
    lastDriverId = driverId;
    lastDriverName = driverName;
    lastScheduledDate = scheduledDate;
    lastPurchases = purchases;
    lastNotes = notes;
    return 'route-new';
  }

  @override
  Future<void> updateRouteStatus({
    required String routeId,
    required PurchaseRouteStatus status,
    double? actualDistanceKm,
    double? kmRate,
  }) async {
    lastUpdatedRouteId = routeId;
    lastUpdatedStatus = status;
  }
}

Purchase _purchase({
  required String id,
  required String itemName,
  required String supplierName,
  required String projectName,
  PurchaseFulfillmentType fulfillmentType = PurchaseFulfillmentType.delivery,
}) {
  return Purchase(
    id: id,
    itemId: 'item-$id',
    itemName: itemName,
    supplierId: 'supplier-$id',
    supplierName: supplierName,
    projectId: 'project-$id',
    projectName: projectName,
    deliveryAddress: 'Rua $id, 100',
    fulfillmentType: fulfillmentType,
    pickupAddress:
        fulfillmentType == PurchaseFulfillmentType.pickup ? 'Loja $id' : '',
    totalValue: 1200,
    status: PurchaseStatus.ordered,
    purchaseDate: DateTime(2026, 5, 3),
    expectedDeliveryDate: DateTime(2026, 5, 10),
  );
}

PurchaseDeliveryRoute _route() {
  return PurchaseDeliveryRoute(
    id: 'route-1',
    name: 'Rota Centro',
    driverName: 'Joao Motorista',
    status: PurchaseRouteStatus.completed,
    scheduledDate: DateTime(2026, 5, 12),
    completedAt: DateTime(2026, 5, 12),
    estimatedDistanceKm: 42.8,
    actualDistanceKm: 38.4,
    createdAt: DateTime(2026, 5, 11),
    updatedAt: DateTime(2026, 5, 11),
  );
}

PurchaseDeliveryRouteStop _stop() {
  return PurchaseDeliveryRouteStop(
    id: 'stop-1',
    routeId: 'route-1',
    purchaseId: 'purchase-1',
    stopType: PurchaseRouteStopType.delivery,
    sequence: 1,
    address: 'Rua 1, 100',
    supplierName: 'Fornecedor Atlas',
    projectName: 'Residencial Azul',
    createdAt: DateTime(2026, 5, 11),
  );
}

void main() {
  testWidgets(
    'PurchaseLogisticsPageView acompanha rotas e KM em modo leitura',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 980);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = _FakePurchaseDeliveryRouteService(
        candidates: [
          _purchase(
            id: 'purchase-1',
            itemName: 'Cimento CP-II',
            supplierName: 'Fornecedor Atlas',
            projectName: 'Residencial Azul',
          ),
          _purchase(
            id: 'purchase-2',
            itemName: 'Brita 1',
            supplierName: 'Pedreira Norte',
            projectName: 'Galpao Industrial',
            fulfillmentType: PurchaseFulfillmentType.pickup,
          ),
        ],
        drivers: const [
          PurchaseRouteDriver(
            id: 'employee-maria',
            name: 'Maria Motorista',
            vehicleId: 'vehicle-1',
            vehicleLabel: 'Fiat Fiorino',
            plate: 'ABC1D23',
          ),
        ],
        routes: [_route()],
        stops: {
          'route-1': [_stop()],
        },
      );

      await tester.pumpWidget(
        MaterialApp(home: PurchaseLogisticsPageView(service: service)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Coletas e Entregas'), findsOneWidget);
      expect(find.text('Rotas e KM dos motoristas'), findsOneWidget);
      expect(find.text('Rota Centro'), findsOneWidget);
      expect(find.text('Joao Motorista'), findsOneWidget);
      expect(find.text('KM realizado: 38.4 km'), findsOneWidget);
      expect(find.text('Previsto: 42.8 km'), findsOneWidget);
      expect(find.textContaining('Fornecedor Atlas'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Buscar rota'),
        'Centro',
      );
      await tester.pump();

      expect(find.text('Rota Centro'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Buscar compra'), findsNothing);
      expect(find.text('Criar rota com 1 compra(s)'), findsNothing);
      expect(find.text('Iniciar rota'), findsNothing);
      expect(find.text('Concluir e lancar KM'), findsNothing);
      expect(service.lastDriverId, isNull);
      expect(service.lastUpdatedRouteId, isNull);
    },
  );
}
