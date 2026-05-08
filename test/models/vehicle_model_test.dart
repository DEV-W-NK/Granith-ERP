import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/vehicle_model.dart';

void main() {
  group('Vehicle', () {
    test('serializa cadastro e calcula consumo esperado', () {
      final vehicle = Vehicle(
        id: 'vehicle-1',
        plate: 'abc-1d23',
        brand: 'Toyota',
        model: 'Corolla',
        version: 'XEi',
        manufactureYear: 2023,
        modelYear: 2024,
        fuelType: VehicleFuelType.flex,
        status: VehicleStatus.active,
        odometerKm: 14500,
        expectedCityKmPerLiter: 10,
        expectedHighwayKmPerLiter: 13,
        assignedEmployeeName: 'Joao',
        lastMeasuredKmPerLiter: 8.5,
        createdAt: DateTime(2026, 5, 8),
        updatedAt: DateTime(2026, 5, 8),
      );

      expect(vehicle.normalizedPlate, 'ABC1D23');
      expect(vehicle.displayName, 'Toyota Corolla XEi');
      expect(vehicle.yearLabel, '2023/2024');
      expect(vehicle.expectedAverageKmPerLiter, 11.5);
      expect(vehicle.isUnderExpectedConsumption, isTrue);

      final map = vehicle.toMap();
      expect(map['plate'], 'ABC1D23');
      expect(map['fuelType'], 'flex');
      expect(map['status'], 'active');

      final parsed = Vehicle.fromMap(map, 'vehicle-1');
      expect(parsed.plate, 'ABC1D23');
      expect(parsed.fuelType, VehicleFuelType.flex);
      expect(parsed.status, VehicleStatus.active);
      expect(parsed.assignedEmployeeName, 'Joao');
    });
  });

  group('VehicleFuelLog', () {
    test('serializa metricas de abastecimento', () {
      final log = VehicleFuelLog(
        id: 'fuel-1',
        vehicleId: 'vehicle-1',
        vehiclePlate: 'ABC1D23',
        employeeId: 'employee-1',
        employeeName: 'Joao',
        liters: 42,
        totalAmount: 250,
        unitPrice: 5.95,
        odometerKm: 15100,
        previousOdometerKm: 14600,
        kmTraveled: 500,
        kmPerLiter: 11.9,
        fuelingDate: DateTime(2026, 5, 8),
        createdAt: DateTime(2026, 5, 8),
      );

      final map = log.toMap();
      expect(map['vehicleId'], 'vehicle-1');
      expect(map['kmPerLiter'], 11.9);

      final parsed = VehicleFuelLog.fromMap(map, 'fuel-1');
      expect(parsed.liters, 42);
      expect(parsed.kmTraveled, 500);
    });
  });
}
