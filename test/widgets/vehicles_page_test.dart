import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/vehicle_controller.dart';
import 'package:project_granith/models/vehicle_model.dart';
import 'package:project_granith/widgets/vehicles/vehicles_page_widgets.dart';

import '../helpers/fake_vehicle_service.dart';

Vehicle _vehicle({
  required String id,
  required String plate,
  required String brand,
  required String model,
  VehicleStatus status = VehicleStatus.active,
}) {
  return Vehicle(
    id: id,
    plate: plate,
    brand: brand,
    model: model,
    manufactureYear: 2022,
    modelYear: 2023,
    status: status,
    fuelType: VehicleFuelType.flex,
    odometerKm: 18000,
    expectedCityKmPerLiter: 9.5,
    expectedHighwayKmPerLiter: 12.5,
    assignedEmployeeName: 'Carlos Operador',
    createdAt: DateTime(2026, 5, 8),
    updatedAt: DateTime(2026, 5, 8),
  );
}

void main() {
  group('VehiclesPageView', () {
    testWidgets('renderiza frota, busca e abre cadastro', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final service = FakeVehicleService();
      final controller = VehicleController(
        service: service,
        fipeService: FakeVehicleFipeService(),
      )..init();

      await tester.pumpWidget(
        MaterialApp(home: VehiclesPageView(controller: controller)),
      );

      service.emit([
        _vehicle(id: 'v1', plate: 'ABC1D23', brand: 'Toyota', model: 'Corolla'),
        _vehicle(
          id: 'v2',
          plate: 'DEF4G56',
          brand: 'Fiat',
          model: 'Toro',
          status: VehicleStatus.maintenance,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Frota e Veiculos'), findsOneWidget);
      expect(find.textContaining('Toyota Corolla'), findsOneWidget);
      expect(find.textContaining('Fiat Toro'), findsOneWidget);
      expect(find.text('2 cadastrados'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'toro');
      await tester.pumpAndSettle();

      expect(find.textContaining('Fiat Toro'), findsOneWidget);
      expect(find.textContaining('Toyota Corolla'), findsNothing);

      await tester.tap(find.text('Novo veiculo'));
      await tester.pumpAndSettle();

      expect(find.text('Novo veiculo'), findsWidgets);
      expect(find.text('Codigo FIPE'), findsNothing);
      expect(find.byTooltip('Consultar FIPE'), findsNothing);

      controller.dispose();
      await service.dispose();
    });

    testWidgets('salva cadastro manual de veiculo', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final service = FakeVehicleService();
      final controller = VehicleController(
        service: service,
        fipeService: FakeVehicleFipeService(),
      )..init();

      await tester.pumpWidget(
        MaterialApp(home: VehiclesPageView(controller: controller)),
      );
      service.emit();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Novo veiculo'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Placa'),
        'abc1d23',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Marca'),
        'Volkswagen',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Modelo'),
        'Saveiro',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Consumo cidade (km/l)'),
        '9.8',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Consumo estrada (km/l)'),
        '12.2',
      );

      await tester.ensureVisible(find.text('Cadastrar veiculo'));
      await tester.tap(find.text('Cadastrar veiculo'));
      await tester.pumpAndSettle();

      expect(service.lastCreatedVehicle?.plate, 'ABC1D23');
      expect(service.lastCreatedVehicle?.brand, 'Volkswagen');
      expect(service.lastCreatedVehicle?.model, 'Saveiro');
      expect(service.lastCreatedVehicle?.expectedCityKmPerLiter, 9.8);

      controller.dispose();
      await service.dispose();
    });
  });
}
