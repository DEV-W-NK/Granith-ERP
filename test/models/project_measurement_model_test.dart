import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/services/project_measurement_service.dart';

void main() {
  group('ProjectMeasurement', () {
    test('fromMap preserva acumulados e fallback de liquido', () {
      final measurement = ProjectMeasurement.fromMap('m1', {
        'projectId': 'p1',
        'projectName': 'Obra Vista',
        'projectClient': 'Cliente Vista',
        'title': '1a medicao',
        'sequence': 1,
        'status': 'approved',
        'measurementDate': '2026-05-01T00:00:00.000Z',
        'grossAmount': 1500,
        'discountAmount': 200,
        'accumulatedGrossAmount': 1500,
        'measurementPercentage': 15,
        'accumulatedPercentage': 15,
        'contractBalance': 8500,
      });

      expect(measurement.projectId, 'p1');
      expect(measurement.status, ProjectMeasurementStatus.approved);
      expect(measurement.netAmount, 1300);
      expect(measurement.accumulatedGrossAmount, 1500);
      expect(measurement.accumulatedPercentage, 15);
      expect(measurement.isValid, isTrue);
    });

    test('projection calcula percentual acumulado a partir do contrato', () {
      final projection = ProjectMeasurementProjection.fromValues(
        contractValue: 10000,
        previousAccumulatedGross: 2500,
        grossAmount: 1800,
        discountAmount: 300,
      );

      expect(projection.netAmount, 1500);
      expect(projection.accumulatedGrossAmount, 4300);
      expect(projection.measurementPercentage, 18);
      expect(projection.accumulatedPercentage, 43);
      expect(projection.contractBalance, 5700);
    });
  });
}
