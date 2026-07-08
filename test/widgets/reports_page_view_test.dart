import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/controllers/reports_controller.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/reports_chart_models.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:project_granith/widgets/reports/reports_page_page_widgets.dart';
import 'package:provider/provider.dart';

class _TestReportsController extends ReportsController {
  _TestReportsController(this.report);

  final DreExecutiveReport report;
  int loadCount = 0;

  @override
  Future<DreExecutiveReport> fetchDreExecutiveReport() async {
    loadCount += 1;
    return report;
  }
}

void main() {
  testWidgets('ReportsPageView renderiza DRE executivo com contexto geral', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = _TestReportsController(_sampleReport());

    await tester.pumpWidget(
      ChangeNotifierProvider<ReportsController>.value(
        value: controller,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ReportsPageView(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.loadCount, 1);
    expect(find.text('DRE Gerencial'), findsOneWidget);
    expect(find.text('Resultado operacional'), findsWidgets);
    expect(find.text('Demonstrativo de resultado'), findsOneWidget);
    expect(find.text('Ponte de margem'), findsOneWidget);
    expect(find.text('Leitura para o CEO'), findsOneWidget);
    expect(find.text('Contexto geral da empresa'), findsOneWidget);
    expect(find.text('Gastos por natureza'), findsOneWidget);
    expect(find.text('ver detalhes'), findsNothing);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Compras abertas'), findsOneWidget);
    expect(find.textContaining('Cobertura de contas'), findsOneWidget);
  });

  testWidgets('ReportsPageView mantem layout estavel em viewports comuns', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [
      Size(390, 844),
      Size(1280, 720),
      Size(1920, 1080),
    ]) {
      await tester.binding.setSurfaceSize(size);
      final controller = _TestReportsController(_sampleReport());

      await tester.pumpWidget(
        ChangeNotifierProvider<ReportsController>.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const ReportsPageView(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('DRE Gerencial'), findsOneWidget);
      expect(find.text('Ponte de margem'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}

DreExecutiveReport _sampleReport() {
  return ReportsController.buildDreExecutiveReportFromData(
    periodFrom: DateTime(2026, 1, 1),
    periodTo: DateTime(2026, 12, 31, 23, 59, 59),
    projects: [
      {
        'id': 'project-1',
        'status': 'inProgress',
        'budget': 200000,
        'currentCost': 72000,
        'measuredAmount': 90000,
      },
    ],
    employees: [
      {'id': 'employee-1', 'status': 'ativo', 'baseSalary': 5000},
    ],
    inventory: [
      {'id': 'item-1', 'quantity': 2, 'minQuantity': 4},
    ],
    purchases: [
      {'id': 'purchase-1', 'status': 1, 'totalValue': 14000},
    ],
    measurements: [
      {
        'id': 'measurement-1',
        'status': 'approved',
        'netAmount': 38000,
        'measurementDate': DateTime(2026, 4, 10).toIso8601String(),
      },
    ],
    dailyLogs: [
      {'id': 'daily-log-1'},
    ],
    transactions: [
      _tx(
        id: 'income',
        amount: 120000,
        type: TransactionType.income,
        status: TransactionStatus.paid,
        category: TransactionCategory.measurement,
        projectId: 'project-1',
      ),
      _tx(
        id: 'tax',
        amount: 8000,
        status: TransactionStatus.paid,
        category: TransactionCategory.tax,
      ),
      _tx(
        id: 'materials',
        amount: 42000,
        status: TransactionStatus.paid,
        category: TransactionCategory.material,
        origin: TransactionOrigin.purchase,
        projectId: 'project-1',
      ),
      _tx(
        id: 'labor',
        amount: 18000,
        status: TransactionStatus.paid,
        category: TransactionCategory.labor,
        projectId: 'project-1',
      ),
      _tx(
        id: 'admin',
        amount: 16000,
        status: TransactionStatus.paid,
        category: TransactionCategory.administrative,
      ),
    ],
  );
}

FinancialTransactionModel _tx({
  required String id,
  required double amount,
  TransactionType type = TransactionType.expense,
  TransactionStatus status = TransactionStatus.pending,
  TransactionOrigin origin = TransactionOrigin.manual,
  TransactionCategory category = TransactionCategory.other,
  String? projectId,
}) {
  return FinancialTransactionModel(
    id: id,
    description: id,
    amount: amount,
    type: type,
    status: status,
    origin: origin,
    category: category,
    dueDate: DateTime(2026, 5, 2),
    paymentDate: status == TransactionStatus.paid ? DateTime(2026, 5, 2) : null,
    projectId: projectId,
    createdBy: 'test',
    createdAt: DateTime(2026, 5, 1),
  );
}
