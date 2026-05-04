import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/EmployeeBenefitModel.dart';

void main() {
  group('EmployeeBenefitModel', () {
    test('fromMap restaura historico e totalHistoricalCost soma novos valores', () {
      final model = EmployeeBenefitModel.fromMap({
        'employeeId': 'e1',
        'benefitId': 'b1',
        'benefitName': 'VR',
        'monthlyValue': 450,
        'startDate': '2026-01-01T00:00:00.000Z',
        'history': [
          {
            'previousValue': 300,
            'newValue': 350,
            'changedAt': '2026-02-01T00:00:00.000Z',
            'changedBy': 'rh',
            'reason': 'Convencao',
          },
          {
            'previousValue': 350,
            'newValue': 450,
            'changedAt': '2026-03-01T00:00:00.000Z',
            'changedBy': 'rh',
            'reason': 'Ajuste',
          },
        ],
      }, 'eb1');

      expect(model.history, hasLength(2));
      expect(model.totalHistoricalCost, 800);
      expect(model.history.first.reason, 'Convencao');
    });

    test('toMap e copyWith permitem encerrar beneficio', () {
      final model = EmployeeBenefitModel(
        id: 'eb1',
        employeeId: 'e1',
        benefitId: 'b1',
        benefitName: 'Plano',
        monthlyValue: 200,
        startDate: DateTime(2026, 1, 1),
      );

      final ended = model.copyWith(
        endDate: DateTime(2026, 6, 1),
        isActive: false,
      );

      expect(ended.isActive, isFalse);
      expect(ended.endDate, DateTime(2026, 6, 1));
      expect(ended.toMap()['benefitName'], 'Plano');
    });
  });
}
