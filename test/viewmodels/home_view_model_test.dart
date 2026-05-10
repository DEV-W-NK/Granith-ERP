import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/HomeViewModel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('HomeViewModel', () {
    test(
      'loadDashboardData consolida metricas, alertas e atividades',
      () async {
        final rows = <String, List<Map<String, dynamic>>>{
          'financial_transactions': [
            {
              'id': 'overdue-expense',
              'description': 'Fornecedor concreto',
              'amount': 2000.0,
              'type': 'expense',
              'status': 'pending',
              'dueDate': DateTime(2026, 5, 2),
              'createdAt': DateTime(2026, 5, 2),
            },
            {
              'id': 'income-paid',
              'description': 'Recebimento obra',
              'amount': 10000.0,
              'type': 'income',
              'status': 'paid',
              'dueDate': DateTime(2026, 5, 1),
              'paymentDate': DateTime(2026, 5, 1),
              'createdAt': DateTime(2026, 5, 1),
            },
            {
              'id': 'expense-paid',
              'description': 'Pagamento equipe',
              'amount': 8500.0,
              'type': 'expense',
              'status': 'paid',
              'dueDate': DateTime(2026, 5, 2),
              'paymentDate': DateTime(2026, 5, 2),
              'createdAt': DateTime(2026, 5, 2),
            },
          ],
          'employees': [
            {
              'name': 'Ana Costa',
              'status': 'active',
              'admissionDate': DateTime(2026, 5, 1),
            },
            {
              'name': 'Bruno Lima',
              'status': 'ativo',
              'admissionDate': DateTime(2026, 4, 10),
            },
            {'name': 'Inativo', 'status': 'inactive'},
          ],
          'daily_logs': [
            {
              'date': DateTime(2026, 5, 3, 9),
              'manpower': {'pedreiros': 3, 'serventes': 2},
            },
            {
              'date': DateTime(2026, 5, 2, 16),
              'projectName': 'Obra Finalizada',
              'status': 'signed',
              'signedAt': DateTime(2026, 5, 2, 18),
              'manpower': {'equipe': 4},
            },
          ],
          'material_requisitions': [
            {'status': 'pending'},
            {'status': 'approved'},
            {'status': 'delivered'},
          ],
          'talent_candidates': [
            {'status': 'pending'},
          ],
        };

        final viewModel = HomeViewModel(
          nowProvider: () => DateTime(2026, 5, 3, 12),
          listLoader:
              (table, {columns = '*'}) async =>
                  List<Map<String, dynamic>>.from(rows[table] ?? const []),
          projectsLoader:
              () async => [
                {
                  'id': 'project-1',
                  'name': 'Obra Centro',
                  'status': 'inProgress',
                  'budget': 10000.0,
                  'currentCost': 12000.0,
                  'endDate': DateTime(2026, 5, 10),
                },
                {
                  'id': 'project-2',
                  'name': 'Obra Finalizada',
                  'status': 'completed',
                  'budget': 20000.0,
                  'currentCost': 18000.0,
                  'endDate': DateTime(2026, 5, 2),
                },
              ],
          recentActivitiesLoader:
              () async => [
                {
                  'description': 'Recebimento obra',
                  'amount': 10000.0,
                  'type': 'income',
                  'status': 'paid',
                  'paymentDate': DateTime(2026, 5, 3, 10),
                },
              ],
        );

        await viewModel.loadDashboardData();

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
        expect(viewModel.projects, hasLength(1));
        expect(viewModel.projects.single.isOverBudget, isTrue);
        expect(viewModel.stats, hasLength(4));
        expect(viewModel.stats.first.value, 'Ana Costa');
        expect(viewModel.stats[1].value, 'Obra Finalizada');
        expect(viewModel.stats[2].value, '5 pessoas');
        expect(viewModel.stats[3].value, '1 assinado');
        expect(viewModel.recentActivities.single.title, 'Recebimento obra');
        expect(
          viewModel.alerts.any(
            (alert) => alert.message.contains('Ultima obra fechada'),
          ),
          isTrue,
        );
        expect(
          viewModel.alerts.any((alert) => alert.message.contains('requisic')),
          isTrue,
        );
        expect(
          viewModel.alerts.any((alert) => alert.message.contains('curriculo')),
          isTrue,
        );
      },
    );

    test(
      'loadDashboardData trata tabela ausente como dado parcial e cria fallback de atividades',
      () async {
        final viewModel = HomeViewModel(
          nowProvider: () => DateTime(2026, 5, 3, 12),
          listLoader: (table, {columns = '*'}) async {
            if (table == 'talent_candidates') {
              throw PostgrestException(
                message: 'relation does not exist',
                code: '42P01',
              );
            }
            return const [];
          },
          projectsLoader: () async => const [],
          recentActivitiesLoader: () async {
            throw PostgrestException(
              message: 'jwt not accepted',
              code: 'PGRST301',
            );
          },
        );

        await viewModel.loadDashboardData();

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, isNull);
        expect(viewModel.recentActivities, hasLength(1));
        expect(
          viewModel.recentActivities.single.title,
          'Dia pronto para bons avancos',
        );
        expect(viewModel.alerts, isEmpty);
      },
    );

    test(
      'falha em uma secao relevante gera erro agregador sem abortar dashboard inteiro',
      () async {
        final viewModel = HomeViewModel(
          nowProvider: () => DateTime(2026, 5, 3, 12),
          listLoader: (table, {columns = '*'}) async {
            if (table == 'material_requisitions') {
              throw Exception('offline');
            }
            return const [];
          },
          projectsLoader: () async => const [],
          recentActivitiesLoader: () async => const [],
        );

        await viewModel.loadDashboardData();

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.error, contains('requisicoes'));
        expect(viewModel.stats, hasLength(4));
        expect(viewModel.recentActivities, hasLength(1));
      },
    );
  });
}
