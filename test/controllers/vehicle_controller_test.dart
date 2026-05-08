import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/vehicle_controller.dart';
import 'package:project_granith/models/vehicle_model.dart';
import 'package:project_granith/services/vehicle_service.dart';

import '../helpers/fake_vehicle_service.dart';

Vehicle _vehicle({
  required String id,
  required String plate,
  required String brand,
  required String model,
  VehicleStatus status = VehicleStatus.active,
  double expectedCity = 10,
  double expectedHighway = 12,
  double? measured,
}) {
  return Vehicle(
    id: id,
    plate: plate,
    brand: brand,
    model: model,
    manufactureYear: 2021,
    modelYear: 2022,
    status: status,
    expectedCityKmPerLiter: expectedCity,
    expectedHighwayKmPerLiter: expectedHighway,
    lastMeasuredKmPerLiter: measured,
    createdAt: DateTime(2026, 5, 8),
    updatedAt: DateTime(2026, 5, 8),
  );
}

void main() {
  group('VehicleController', () {
    test('sincroniza stream, filtra e consolida indicadores', () async {
      final service = FakeVehicleService();
      final controller = VehicleController(
        service: service,
        fipeService: FakeVehicleFipeService(),
      );

      controller.init();
      service.emit([
        _vehicle(
          id: 'v1',
          plate: 'ABC1D23',
          brand: 'Toyota',
          model: 'Corolla',
          measured: 8,
        ),
        _vehicle(
          id: 'v2',
          plate: 'DEF4G56',
          brand: 'Fiat',
          model: 'Toro',
          status: VehicleStatus.maintenance,
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.totalVehicles, 2);
      expect(controller.activeVehicles, 1);
      expect(controller.maintenanceVehicles, 1);
      expect(controller.vehiclesUnderExpected, 1);

      controller.setSearch('toro');
      expect(controller.filteredVehicles.map((item) => item.id), ['v2']);

      controller.setStatusFilter(VehicleStatus.active);
      expect(controller.filteredVehicles, isEmpty);

      controller.clearFilters();
      expect(controller.filteredVehicles, hasLength(2));

      controller.dispose();
      await service.dispose();
    });

    test('delega create update delete e consulta FIPE', () async {
      final service = FakeVehicleService();
      final fipeService = FakeVehicleFipeService(
        result: const VehicleFipeInfo(
          brand: 'Honda',
          model: 'Civic EXL',
          modelYear: 2022,
          fuelType: VehicleFuelType.gasoline,
          fipeCode: '014088-6',
          fipeValue: 120000,
          referenceMonth: 'maio de 2026',
        ),
      );
      final controller = VehicleController(
        service: service,
        fipeService: fipeService,
      );
      final vehicle = _vehicle(
        id: '',
        plate: 'abc1d23',
        brand: 'Honda',
        model: 'Civic',
      );

      await controller.createVehicle(vehicle);
      await controller.updateVehicle(
        vehicle.copyWith(id: 'generated-vehicle-id'),
      );
      await controller.deleteVehicle('generated-vehicle-id');
      final fipe = await controller.fetchFipe('014088-6');

      expect(service.lastCreatedVehicle?.id, 'generated-vehicle-id');
      expect(service.lastUpdatedVehicle?.id, 'generated-vehicle-id');
      expect(service.lastDeletedId, 'generated-vehicle-id');
      expect(fipe?.brand, 'Honda');
      expect(fipeService.lastCode, '014088-6');

      controller.dispose();
      await service.dispose();
    });
  });
}
