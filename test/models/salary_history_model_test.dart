import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/SalaryHistoryModel.dart';

void main() {
  group('SalaryHistoryModel', () {
    test('percentualAumento calcula reajuste e fallback sem base anterior', () {
      final model = SalaryHistoryModel(
        id: 's1',
        employeeId: 'e1',
        previousSalary: 2000,
        newSalary: 2500,
        effectiveDate: DateTime(2026, 5, 1),
        reason: 'Promocao',
        updatedBy: 'admin',
        createdAt: DateTime(2026, 5, 1),
      );

      expect(model.percentualAumento, 25);

      final noBase = SalaryHistoryModel(
        id: 's2',
        employeeId: 'e1',
        previousSalary: 0,
        newSalary: 1800,
        effectiveDate: DateTime(2026, 6, 1),
        reason: 'Primeiro salario',
        updatedBy: 'rh',
        createdAt: DateTime(2026, 6, 1),
      );
      expect(noBase.percentualAumento, 0);
    });

    test('fromMap e toMap preservam historico salarial', () {
      final model = SalaryHistoryModel.fromMap({
        'employeeId': 'e1',
        'previousSalary': 1800,
        'newSalary': 2100,
        'effectiveDate': '2026-05-01T00:00:00.000Z',
        'reason': 'Reajuste anual',
        'updatedBy': 'rh',
        'createdAt': '2026-05-02T00:00:00.000Z',
      }, 'hist-1');

      expect(model.employeeId, 'e1');
      expect(model.newSalary, 2100);
      expect(model.toMap()['reason'], 'Reajuste anual');
    });
  });
}
