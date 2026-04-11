import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/models/project_model.dart';

class ServiceOrcamentos {
  final String _collectionName = 'budgets';
  final String _projectsTable = 'projects';

  Future<void> addBudget(Budget budget) async {
    try {
      await AppSupabase.client
          .from(_collectionName)
          .insert(DbValue.normalizeMap(budget.toMap()));
    } catch (e) {
      throw Exception('Erro ao adicionar orçamento: $e');
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      await AppSupabase.client
          .from(_collectionName)
          .update(DbValue.normalizeMap(budget.toMap()))
          .eq('id', budget.id);
    } catch (e) {
      throw Exception('Erro ao atualizar orçamento: $e');
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await AppSupabase.client.from(_collectionName).delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar orçamento: $e');
    }
  }

  Stream<List<Budget>> getBudgets() {
    return getBudgetsStream();
  }

  Stream<List<Budget>> getBudgetsStream({String? clientAccountId}) {
    final stream = clientAccountId != null && clientAccountId.trim().isNotEmpty
        ? AppSupabase.client
            .from(_collectionName)
            .stream(primaryKey: ['id'])
            .eq('clientAccountId', clientAccountId.trim())
        : AppSupabase.client
            .from(_collectionName)
            .stream(primaryKey: ['id']);

    return stream.order('creationDate', ascending: false).asyncMap((rows) async {
          final budgets = rows
              .map((row) => Budget.fromMap(Map<String, dynamic>.from(row)))
              .toList();

          return _checkAndUpdateExpiredBudgetsSync(budgets);
        });
  }

  Future<List<Budget>> fetchBudgets({String? clientAccountId}) async {
    try {
      var query = AppSupabase.client.from(_collectionName).select();
      if (clientAccountId != null && clientAccountId.trim().isNotEmpty) {
        query = query.eq('clientAccountId', clientAccountId.trim());
      }

      final response = await query.order('creationDate', ascending: false);
      final budgets = (response as List)
          .map((row) => Budget.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
      return _checkAndUpdateExpiredBudgetsSync(budgets);
    } catch (e) {
      throw Exception('Erro ao carregar orcamentos: $e');
    }
  }

  Future<Budget> getBudget(String id) async {
    try {
      final doc = await AppSupabase.client
          .from(_collectionName)
          .select()
          .eq('id', id)
          .single();
      final budget = Budget.fromMap(Map<String, dynamic>.from(doc));

      if (_shouldMarkAsExpired(budget)) {
        final expiredBudget = budget.copyWith(status: BudgetStatus.expired);
        await updateBudget(expiredBudget);
        return expiredBudget;
      }

      return budget;
    } catch (e) {
      throw Exception('Erro ao buscar orçamento: $e');
    }
  }

  Stream<List<Budget>> getBudgetsByStatus(BudgetStatus status) {
    return AppSupabase.client
        .from(_collectionName)
        .stream(primaryKey: ['id'])
        .eq('status', status.index)
        .order('creationDate', ascending: false)
        .asyncMap((rows) async {
          final budgets = rows
              .map((row) => Budget.fromMap(Map<String, dynamic>.from(row)))
              .toList();

          return _checkAndUpdateExpiredBudgetsSync(budgets);
        });
  }

  bool _shouldMarkAsExpired(Budget budget) {
    return budget.expirationDate != null &&
        DateTime.now().isAfter(budget.expirationDate!) &&
        budget.status == BudgetStatus.pending;
  }

  Future<List<Budget>> _checkAndUpdateExpiredBudgetsSync(
    List<Budget> budgets,
  ) async {
    final updatedBudgets = <Budget>[];

    for (final budget in budgets) {
      if (_shouldMarkAsExpired(budget)) {
        final expiredBudget = budget.copyWith(status: BudgetStatus.expired);

        try {
          await updateBudget(expiredBudget);
          updatedBudgets.add(expiredBudget);
        } catch (_) {
          updatedBudgets.add(budget);
        }
      } else {
        updatedBudgets.add(budget);
      }
    }

    return updatedBudgets;
  }

  Future<void> _checkAndUpdateExpiredBudgets(List<Budget> budgets) async {
    final expiredBudgets = budgets.where(_shouldMarkAsExpired).toList();

    for (final budget in expiredBudgets) {
      try {
        await updateBudget(budget.copyWith(status: BudgetStatus.expired));
      } catch (_) {
        // Mantém o fluxo mesmo se um item falhar.
      }
    }
  }

  Future<void> checkExpiredBudgets() async {
    try {
      final querySnapshot = await AppSupabase.client
          .from(_collectionName)
          .select()
          .eq('status', BudgetStatus.pending.index);

      final budgets = (querySnapshot as List)
          .map((doc) => Budget.fromMap(Map<String, dynamic>.from(doc as Map)))
          .toList();

      await _checkAndUpdateExpiredBudgets(budgets);
    } catch (e) {
      throw Exception('Erro ao verificar orçamentos expirados: $e');
    }
  }

  Future<List<Budget>> getBudgetsExpiringInDays(int days) async {
    try {
      final targetDate = DateTime.now().add(Duration(days: days));
      final startOfDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await AppSupabase.client
          .from(_collectionName)
          .select()
          .eq('status', BudgetStatus.pending.index)
          .gte('expirationDate', startOfDay.toUtc().toIso8601String())
          .lt('expirationDate', endOfDay.toUtc().toIso8601String());

      return (querySnapshot as List)
          .map((doc) => Budget.fromMap(Map<String, dynamic>.from(doc as Map)))
          .toList();
    } catch (e) {
      throw Exception(
        'Erro ao buscar orçamentos que expiram em $days dias: $e',
      );
    }
  }

  Future<void> forceUpdateExpiredBudgets() async {
    try {
      final querySnapshot = await AppSupabase.client
          .from(_collectionName)
          .select()
          .eq('status', BudgetStatus.pending.index);

      final budgets = (querySnapshot as List)
          .map((doc) => Budget.fromMap(Map<String, dynamic>.from(doc as Map)))
          .toList();

      for (final budget in budgets) {
        if (_shouldMarkAsExpired(budget)) {
          await updateBudget(budget.copyWith(status: BudgetStatus.expired));
        }
      }
    } catch (e) {
      throw Exception('Erro ao forçar atualização de orçamentos expirados: $e');
    }
  }

  Future<Map<String, int>> getBudgetStats() async {
    try {
      final querySnapshot =
          await AppSupabase.client.from(_collectionName).select();
      final budgets = (querySnapshot as List)
          .map((doc) => Budget.fromMap(Map<String, dynamic>.from(doc as Map)))
          .toList();

      await _checkAndUpdateExpiredBudgets(budgets);

      final stats = <String, int>{
        'total': budgets.length,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'expired': 0,
        'expiringIn7Days': 0,
      };

      final now = DateTime.now();
      final in7Days = now.add(const Duration(days: 7));

      for (final budget in budgets) {
        final status =
            _shouldMarkAsExpired(budget) ? BudgetStatus.expired : budget.status;

        switch (status) {
          case BudgetStatus.pending:
            stats['pending'] = stats['pending']! + 1;
            if (budget.expirationDate != null &&
                budget.expirationDate!.isAfter(now) &&
                budget.expirationDate!.isBefore(in7Days)) {
              stats['expiringIn7Days'] = stats['expiringIn7Days']! + 1;
            }
            break;
          case BudgetStatus.approved:
            stats['approved'] = stats['approved']! + 1;
            break;
          case BudgetStatus.rejected:
            stats['rejected'] = stats['rejected']! + 1;
            break;
          case BudgetStatus.expired:
            stats['expired'] = stats['expired']! + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas de orçamentos: $e');
    }
  }

  Future<String> approveBudget(Budget budget) async {
    if (budget.status == BudgetStatus.approved && budget.projectId != null) {
      return budget.projectId!;
    }

    final now = DateTime.now();
    final projectPayload = DbValue.normalizeMap({
      'name': budget.projectName,
      'client': budget.clientName,
      'description': budget.description,
      'status': ProjectStatus.planning.name,
      'startDate': now,
      'endDate': budget.expirationDate,
      'budget': budget.totalValue,
      'currentCost': 0,
      'location': '',
      'tags': const ['Gerado por orçamento'],
      'teamSize': 0,
      'sourceBudgetId': budget.id,
      'createdAt': now,
      'created_at': now,
      'updatedAt': now,
      'updated_at': now,
      'projectKey':
          '${budget.projectName.trim().toLowerCase()}_${budget.clientName.trim().toLowerCase()}',
      'clientAccountId': budget.clientAccountId,
      'client_account_id': budget.clientAccountId,
      'clientAccountName': budget.clientAccountName,
      'client_account_name': budget.clientAccountName,
    });

    try {
      final existingProject = await AppSupabase.client
          .from(_projectsTable)
          .select('id')
          .eq('sourceBudgetId', budget.id)
          .maybeSingle();

      final String projectId;

      if (existingProject != null) {
        projectId = existingProject['id'].toString();
      } else {
        final projectRow = await AppSupabase.client
            .from(_projectsTable)
            .insert(projectPayload)
            .select('id')
            .single();
        projectId = projectRow['id'].toString();
      }

      await AppSupabase.client.from(_collectionName).update({
        'status': BudgetStatus.approved.index,
        'projectId': projectId,
        'clientAccountId': budget.clientAccountId,
        'client_account_id': budget.clientAccountId,
        'clientAccountName': budget.clientAccountName,
        'client_account_name': budget.clientAccountName,
      }).eq('id', budget.id);

      return projectId;
    } catch (e) {
      throw Exception('Erro ao aprovar orçamento: $e');
    }
  }

  Future<void> rejectBudget(String budgetId) async {
    await AppSupabase.client.from(_collectionName).update({
      'status': BudgetStatus.rejected.index,
    }).eq('id', budgetId);
  }
}
