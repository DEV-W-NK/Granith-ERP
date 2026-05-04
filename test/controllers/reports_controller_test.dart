import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/reports_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';

import '../helpers/fake_reports_financial_service.dart';

void main() {
  group('ReportsController', () {
    test('setCurrentMonth, setCurrentYear e clearPeriod atualizam filtros', () {
      final controller = ReportsController(
        financialService: FakeReportsFinancialService(),
      );

      controller.setCurrentMonth();
      expect(controller.periodFrom, isNotNull);
      expect(controller.periodTo, isNotNull);
      expect(controller.periodFrom!.month, DateTime.now().month);

      controller.setCurrentYear();
      expect(controller.periodFrom!.month, 1);
      expect(controller.periodTo!.month, 12);

      controller.clearPeriod();
      expect(controller.periodFrom, isNull);
      expect(controller.periodTo, isNull);
    });

    test('fetchExpensesByCategory traduz labels e ordena por valor', () async {
      final service = FakeReportsFinancialService(
        categorySums: {'material': 9000, 'administrative': 2000, 'tax': 4000},
      );
      final controller = ReportsController(financialService: service);

      controller.setPeriod(
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 31, 23, 59, 59),
      );
      final result = await controller.fetchExpensesByCategory();

      expect(service.lastType, TransactionType.expense);
      expect(service.lastFrom, controller.periodFrom);
      expect(result.map((e) => e.label).toList(), [
        'Materiais',
        'Impostos',
        'Administrativo',
      ]);
      expect(result.first.value, 9000);
    });
  });
}
