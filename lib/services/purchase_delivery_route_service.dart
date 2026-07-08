import 'dart:async';

import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/purchase_delivery_route_model.dart';
import 'package:project_granith/models/purchase_model.dart';
import 'package:project_granith/models/vehicle_model.dart';
import 'package:project_granith/services/mobile_push_dispatch_service.dart';
import 'package:project_granith/services/vehicle_service.dart';

class PurchaseRouteDriver {
  final String id;
  final String name;
  final String vehicleId;
  final String vehicleLabel;
  final String plate;

  const PurchaseRouteDriver({
    required this.id,
    required this.name,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.plate,
  });

  bool get hasMobileBinding => id.trim().isNotEmpty;

  String get displayLabel {
    final vehicle = [
      if (plate.trim().isNotEmpty) plate.trim(),
      if (vehicleLabel.trim().isNotEmpty) vehicleLabel.trim(),
    ].join(' - ');
    return vehicle.isEmpty ? name : '$name | $vehicle';
  }
}

class PurchaseDeliveryRouteService {
  static const _routesTable = 'purchase_delivery_routes';
  static const _stopsTable = 'purchase_delivery_route_stops';
  static const _purchasesTable = 'purchases';

  final VehicleService _vehicleService;

  PurchaseDeliveryRouteService({VehicleService? vehicleService})
    : _vehicleService = vehicleService ?? VehicleService();

  Stream<List<PurchaseDeliveryRoute>> watchRoutes() {
    return AppSupabase.client
        .from(_routesTable)
        .stream(primaryKey: ['id'])
        .order('scheduledDate', ascending: false)
        .map(
          (rows) =>
              rows.map((row) => PurchaseDeliveryRoute.fromMap(row)).toList(),
        );
  }

  Stream<List<PurchaseDeliveryRoute>> watchRoutesForDriver({
    required String driverId,
    String? driverName,
    bool includeCompleted = false,
  }) {
    final normalizedDriverId = driverId.trim();
    final normalizedDriverName = driverName?.trim().toLowerCase() ?? '';

    if (normalizedDriverId.isEmpty && normalizedDriverName.isEmpty) {
      return Stream.value(const <PurchaseDeliveryRoute>[]);
    }

    return watchRoutes().map((routes) {
      final filtered =
          routes.where((route) {
            final matchesId =
                normalizedDriverId.isNotEmpty &&
                route.driverId?.trim() == normalizedDriverId;
            final matchesName =
                normalizedDriverName.isNotEmpty &&
                route.driverName.trim().toLowerCase() == normalizedDriverName;
            final matchesDriver = matchesId || matchesName;
            if (!matchesDriver) return false;
            if (includeCompleted) return true;
            return route.status == PurchaseRouteStatus.planned ||
                route.status == PurchaseRouteStatus.inProgress;
          }).toList();

      filtered.sort((a, b) {
        final status = _mobileRouteStatusRank(
          a.status,
        ).compareTo(_mobileRouteStatusRank(b.status));
        if (status != 0) return status;
        return _compareNullableDateAsc(a.scheduledDate, b.scheduledDate);
      });
      return filtered;
    });
  }

  Stream<List<PurchaseDeliveryRouteStop>> watchStops(String routeId) {
    return AppSupabase.client
        .from(_stopsTable)
        .stream(primaryKey: ['id'])
        .eq('routeId', routeId)
        .order('sequence')
        .map(
          (rows) =>
              rows
                  .map((row) => PurchaseDeliveryRouteStop.fromMap(row))
                  .toList(),
        );
  }

  Future<List<PurchaseRouteDriver>> fetchAvailableDrivers() async {
    final vehicles = await _vehicleService.getVehicles();
    final driversById = <String, PurchaseRouteDriver>{};

    for (final vehicle in vehicles) {
      if (vehicle.status != VehicleStatus.active) continue;

      final name = vehicle.assignedEmployeeName.trim();
      if (name.isEmpty) continue;

      final employeeId = vehicle.assignedEmployeeId?.trim();
      if (employeeId == null || employeeId.isEmpty) continue;

      driversById.putIfAbsent(
        employeeId,
        () => PurchaseRouteDriver(
          id: employeeId,
          name: name,
          vehicleId: vehicle.id,
          vehicleLabel: vehicle.displayName,
          plate: vehicle.normalizedPlate,
        ),
      );
    }

    final drivers =
        driversById.values.toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    return drivers;
  }

  Future<List<Purchase>> fetchRouteCandidates() async {
    final response = await AppSupabase.client
        .from(_purchasesTable)
        .select()
        .eq('status', PurchaseStatus.ordered.index)
        .order('expectedDeliveryDate', ascending: true);

    return (response as List)
        .map((row) {
          final data = Map<String, dynamic>.from(row as Map);
          return Purchase.fromMap(data, data['id'] as String? ?? '');
        })
        .where((purchase) {
          if (purchase.routeId?.trim().isNotEmpty == true) return false;
          if (purchase.status == PurchaseStatus.delivered ||
              purchase.status == PurchaseStatus.cancelled) {
            return false;
          }
          if (purchase.fulfillmentType == PurchaseFulfillmentType.pickup) {
            return purchase.pickupAddress.trim().isNotEmpty ||
                purchase.deliveryAddress.trim().isNotEmpty;
          }
          return purchase.deliveryAddress.trim().isNotEmpty;
        })
        .toList();
  }

  Future<String> createRoute({
    required String name,
    required String driverName,
    String? driverId,
    DateTime? scheduledDate,
    required List<Purchase> purchases,
    String notes = '',
    String? createdBy,
  }) async {
    if (driverName.trim().isEmpty) {
      throw Exception('Informe o motorista responsavel pela rota.');
    }
    if (driverId?.trim().isEmpty ?? true) {
      throw Exception('Selecione um motorista com veiculo ativo.');
    }
    if (purchases.isEmpty) {
      throw Exception('Selecione ao menos uma compra para montar a rota.');
    }

    final now = DateTime.now();
    final routePayload = DbValue.normalizeMap({
      'name':
          name.trim().isEmpty ? 'Rota de ${driverName.trim()}' : name.trim(),
      'driverId': driverId!.trim(),
      'driverName': driverName.trim(),
      'status': PurchaseRouteStatus.planned.name,
      'scheduledDate': DbValue.toPrimitive(scheduledDate),
      'notes': notes.trim(),
      'createdBy': createdBy,
      'createdAt': DbValue.toPrimitive(now),
      'updatedAt': DbValue.toPrimitive(now),
    });

    final routeRow =
        await AppSupabase.client
            .from(_routesTable)
            .insert(routePayload)
            .select('id')
            .single();
    final routeId = routeRow['id'] as String;

    final stops = <Map<String, dynamic>>[];
    var sequence = 1;
    for (final purchase in purchases) {
      if (purchase.fulfillmentType == PurchaseFulfillmentType.pickup &&
          purchase.pickupAddress.trim().isNotEmpty) {
        stops.add(
          _stopPayload(
            routeId: routeId,
            purchase: purchase,
            sequence: sequence++,
            type: PurchaseRouteStopType.pickup,
            address: purchase.pickupAddress,
          ),
        );
      }

      final deliveryAddress = purchase.deliveryAddress.trim();
      if (deliveryAddress.isNotEmpty) {
        stops.add(
          _stopPayload(
            routeId: routeId,
            purchase: purchase,
            sequence: sequence++,
            type: PurchaseRouteStopType.delivery,
            address: deliveryAddress,
          ),
        );
      }
    }

    if (stops.isEmpty) {
      await AppSupabase.client.from(_routesTable).delete().eq('id', routeId);
      throw Exception('As compras selecionadas nao possuem enderecos de rota.');
    }

    await AppSupabase.client.from(_stopsTable).insert(stops);

    for (final purchase in purchases) {
      await AppSupabase.client
          .from(_purchasesTable)
          .update({'routeId': routeId})
          .eq('id', purchase.id);
    }

    _notifyRoutesChanged(
      extraScopes: const [
        AppDataRefreshBus.purchaseDeliveryRouteStops,
        AppDataRefreshBus.purchases,
      ],
    );
    unawaited(MobilePushDispatchService.dispatchPending());
    return routeId;
  }

  Future<void> updateRouteStatus({
    required String routeId,
    required PurchaseRouteStatus status,
    double? actualDistanceKm,
    double? kmRate,
  }) async {
    final now = DateTime.now();
    final payload = <String, dynamic>{
      'status': status.name,
      'actualDistanceKm': actualDistanceKm,
      'kmRate': kmRate,
    };

    if (actualDistanceKm != null && kmRate != null) {
      payload['bonusValue'] = actualDistanceKm * kmRate;
    }
    if (status == PurchaseRouteStatus.inProgress) {
      payload['startedAt'] = DbValue.toPrimitive(now);
    }
    if (status == PurchaseRouteStatus.completed) {
      payload['completedAt'] = DbValue.toPrimitive(now);
    }

    await AppSupabase.client
        .from(_routesTable)
        .update(DbValue.normalizeMap(payload))
        .eq('id', routeId);
    _notifyRoutesChanged();
    unawaited(MobilePushDispatchService.dispatchPending());
  }

  Map<String, dynamic> _stopPayload({
    required String routeId,
    required Purchase purchase,
    required int sequence,
    required PurchaseRouteStopType type,
    required String address,
  }) {
    return DbValue.normalizeMap({
      'routeId': routeId,
      'purchaseId': purchase.id,
      'stopType': type.name,
      'sequence': sequence,
      'address': address.trim(),
      'supplierName': purchase.supplierName,
      'projectName': purchase.projectName,
      'status': PurchaseRouteStopStatus.pending.name,
      'notes':
          type == PurchaseRouteStopType.pickup
              ? 'Coletar ${purchase.itemName} em ${purchase.supplierName}.'
              : 'Entregar ${purchase.itemName} em ${purchase.projectName}.',
    });
  }

  void _notifyRoutesChanged({List<String> extraScopes = const []}) {
    AppDataRefreshBus.instance.notify(
      scopes: [AppDataRefreshBus.purchaseDeliveryRoutes, ...extraScopes],
      source: 'PurchaseDeliveryRouteService',
    );
  }
}

int _mobileRouteStatusRank(PurchaseRouteStatus status) {
  switch (status) {
    case PurchaseRouteStatus.inProgress:
      return 0;
    case PurchaseRouteStatus.planned:
      return 1;
    case PurchaseRouteStatus.completed:
      return 2;
    case PurchaseRouteStatus.cancelled:
      return 3;
  }
}

int _compareNullableDateAsc(DateTime? left, DateTime? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return left.compareTo(right);
}
