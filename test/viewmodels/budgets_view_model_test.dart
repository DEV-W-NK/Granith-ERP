import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/BudgetsViewModel.dart';
import 'package:project_granith/models/budget_model.dart';

import '../helpers/fake_service_orcamentos.dart';

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Budget _budget({
  required String id,
  required String client,
  required String project,
  required BudgetStatus status,
}) {
  return Budget(
    id: id,
    clientName: client,
    projectName: project,
    totalValue: 1000,
    creationDate: DateTime(2026, 5, 1),
    status: status,
  );
}

void main() {
  group('BudgetsViewModel', () {
    test('escuta stream, atualiza lista e executa check inicial', () async {
      final service = FakeServiceOrcamentos();
      final viewModel = BudgetsViewModel(service);

      service.emitBudgets([
        _budget(
          id: 'budget-1',
          client: 'Cliente Atlas',
          project: 'Torre Norte',
          status: BudgetStatus.pending,
        ),
      ]);
      await _flushAsync();

      expect(service.forceUpdateCalled, isTrue);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.filteredBudgets, hasLength(1));
      expect(viewModel.filteredBudgets.single.clientName, 'Cliente Atlas');

      await service.dispose();
      viewModel.dispose();
    });

    test('aplica busca e filtro por status', () async {
      final service = FakeServiceOrcamentos();
      final viewModel = BudgetsViewModel(service);

      service.emitBudgets([
        _budget(
          id: 'budget-1',
          client: 'Cliente Atlas',
          project: 'Torre Norte',
          status: BudgetStatus.pending,
        ),
        _budget(
          id: 'budget-2',
          client: 'Cliente Boreal',
          project: 'Retrofit Sul',
          status: BudgetStatus.approved,
        ),
      ]);
      await _flushAsync();

      viewModel.setSearchQuery('retrofit');
      expect(viewModel.filteredBudgets, hasLength(1));
      expect(viewModel.filteredBudgets.single.id, 'budget-2');

      viewModel.setFilterStatus(BudgetStatus.approved);
      expect(viewModel.filteredBudgets, hasLength(1));
      expect(viewModel.filteredBudgets.single.status, BudgetStatus.approved);

      viewModel.clearFilters();
      viewModel.setSearchQuery('');
      expect(viewModel.filteredBudgets, hasLength(2));

      await service.dispose();
      viewModel.dispose();
    });

    test(
      'approveBudget controla ids em aprovacao e callback de sucesso',
      () async {
        final service = FakeServiceOrcamentos();
        final viewModel = BudgetsViewModel(service, bootstrapOnInit: false);
        final budget = _budget(
          id: 'budget-3',
          client: 'Cliente Atlas',
          project: 'Obra A',
          status: BudgetStatus.pending,
        );
        String? successMessage;

        final future = viewModel.approveBudget(
          budget,
          onSuccess: (message) => successMessage = message,
        );

        expect(viewModel.approvingIds, contains('budget-3'));
        await future;

        expect(service.approvedBudget?.id, 'budget-3');
        expect(viewModel.approvingIds, isEmpty);
        expect(successMessage, contains('Or'));
        viewModel.dispose();
      },
    );

    test(
      'forceCheckExpiredBudgets expõe erro amigavel e reseta loading',
      () async {
        final service =
            FakeServiceOrcamentos()..forceUpdateError = Exception('offline');
        final viewModel = BudgetsViewModel(service, bootstrapOnInit: false);
        String? errorMessage;

        await viewModel.forceCheckExpiredBudgets(
          onError: (message) => errorMessage = message,
        );

        expect(viewModel.isUpdatingExpired, isFalse);
        expect(errorMessage, contains('Erro ao verificar'));
        await service.dispose();
        viewModel.dispose();
      },
    );
  });
}
