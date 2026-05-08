import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/EmployeeBenefitModel.dart';

void main() {
  group('EmployeeBenefitModel', () {
    test(
      'fromMap restaura historico e totalHistoricalCost soma novos valores',
      () {
        final model = EmployeeBenefitModel.fromMap({
          'employeeId': 'e1',
          'benefitId': 'b1',
          'benefitName': 'VR',
          'dailyValue': 31.50,
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
        expect(model.dailyValue, 31.50);
        expect(model.costForWorkedDays(20), 630);
        expect(model.history.first.reason, 'Convencao');
      },
    );

    test('toMap e copyWith permitem encerrar beneficio', () {
      final model = EmployeeBenefitModel(
        id: 'eb1',
        employeeId: 'e1',
        benefitId: 'b1',
        benefitName: 'Plano',
        dailyValue: 9.10,
        startDate: DateTime(2026, 1, 1),
      );

      final ended = model.copyWith(
        benefitName: 'Plano atualizado',
        endDate: DateTime(2026, 6, 1),
        isActive: false,
      );

      expect(ended.isActive, isFalse);
      expect(ended.endDate, DateTime(2026, 6, 1));
      expect(ended.toMap()['benefitName'], 'Plano atualizado');
      expect(ended.toMap()['dailyValue'], 9.10);
    });

    test('copyWith permite reativar limpando data de fim', () {
      final model = EmployeeBenefitModel(
        id: 'eb1',
        employeeId: 'e1',
        benefitId: 'b1',
        benefitName: 'VR',
        dailyValue: 13.65,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 5, 1),
        isActive: false,
      );

      final active = model.copyWith(isActive: true, clearEndDate: true);

      expect(active.isActive, isTrue);
      expect(active.endDate, isNull);
    });

    test('fromMap aceita monthlyValue legado como valor diario', () {
      final model = EmployeeBenefitModel.fromMap({
        'employeeId': 'e1',
        'benefitId': 'b1',
        'benefitName': 'VT legado',
        'monthlyValue': 12,
      }, 'eb2');

      expect(model.dailyValue, 12);
      expect(model.toMap()['dailyValue'], 12);
      expect(model.toMap()['monthlyValue'], 12);
    });
  });
}
