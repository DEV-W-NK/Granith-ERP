import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/budget_model.dart';
import 'package:project_granith/models/project_model.dart';


class ServiceOrcamentos {
  final FirebaseFirestore _firestore;
  final String _collectionName = 'budgets';

  ServiceOrcamentos({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addBudget(Budget budget) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(budget.id)
          .set(budget.toMap());
    } catch (e) {
      throw Exception('Erro ao adicionar orçamento: $e');
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(budget.id)
          .update(budget.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar orçamento: $e');
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao deletar orçamento: $e');
    }
  }

  Stream<List<Budget>> getBudgets() {
    return _firestore
        .collection(_collectionName)
        .orderBy('creationDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final budgets =
              snapshot.docs.map((doc) => Budget.fromMap(doc.data())).toList();

          // Verificar e atualizar orçamentos expirados
          final updatedBudgets = await _checkAndUpdateExpiredBudgetsSync(
            budgets,
          );

          return updatedBudgets;
        });
  }

  Future<Budget> getBudget(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      final budget = Budget.fromMap(doc.data() as Map<String, dynamic>);

      // Verificar se este orçamento específico expirou
      if (_shouldMarkAsExpired(budget)) {
        final expiredBudget = Budget(
          id: budget.id,
          clientName: budget.clientName,
          projectName: budget.projectName,
          totalValue: budget.totalValue,
          creationDate: budget.creationDate,
          expirationDate: budget.expirationDate,
          status: BudgetStatus.expired,
          description: budget.description,
          items: budget.items,
          projectId: budget.projectId,
        );

        // Atualizar no banco de dados
        await updateBudget(expiredBudget);
        return expiredBudget;
      }

      return budget;
    } catch (e) {
      throw Exception('Erro ao buscar orçamento: $e');
    }
  }

  Stream<List<Budget>> getBudgetsByStatus(BudgetStatus status) {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: status.index)
        .orderBy('creationDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final budgets =
              snapshot.docs.map((doc) => Budget.fromMap(doc.data())).toList();

          // Verificar e atualizar orçamentos expirados
          final updatedBudgets = await _checkAndUpdateExpiredBudgetsSync(
            budgets,
          );

          return updatedBudgets;
        });
  }

  /// Verifica se um orçamento deve ser marcado como expirado
  bool _shouldMarkAsExpired(Budget budget) {
    return budget.expirationDate != null &&
        DateTime.now().isAfter(budget.expirationDate!) &&
        budget.status == BudgetStatus.pending;
  }

  /// Versão síncrona que aguarda a atualização antes de retornar
  Future<List<Budget>> _checkAndUpdateExpiredBudgetsSync(
    List<Budget> budgets,
  ) async {
    final updatedBudgets = <Budget>[];

    for (final budget in budgets) {
      if (_shouldMarkAsExpired(budget)) {
        print(
          '🔄 Atualizando orçamento expirado: ${budget.id} - Cliente: ${budget.clientName}',
        );

        final expiredBudget = Budget(
          id: budget.id,
          clientName: budget.clientName,
          projectName: budget.projectName,
          totalValue: budget.totalValue,
          creationDate: budget.creationDate,
          expirationDate: budget.expirationDate,
          status: BudgetStatus.expired,
          description: budget.description,
          items: budget.items,
          projectId: budget.projectId,
        );

        try {
          await updateBudget(expiredBudget);
          updatedBudgets.add(expiredBudget);
          print('✅ Orçamento ${budget.id} atualizado para expirado');
        } catch (e) {
          print('❌ Erro ao atualizar orçamento expirado ${budget.id}: $e');
          updatedBudgets.add(budget); // Manter original em caso de erro
        }
      } else {
        updatedBudgets.add(budget);
      }
    }

    return updatedBudgets;
  }

  /// Verifica e atualiza orçamentos expirados automaticamente (versão assíncrona)
  Future<void> _checkAndUpdateExpiredBudgets(List<Budget> budgets) async {
    final expiredBudgets = budgets.where(_shouldMarkAsExpired).toList();

    for (final budget in expiredBudgets) {
      final expiredBudget = Budget(
        id: budget.id,
        clientName: budget.clientName,
        projectName: budget.projectName,
        totalValue: budget.totalValue,
        creationDate: budget.creationDate,
        expirationDate: budget.expirationDate,
        status: BudgetStatus.expired,
        description: budget.description,
        items: budget.items,
        projectId: budget.projectId,
      );

      try {
        await updateBudget(expiredBudget);
      } catch (e) {
        print('Erro ao atualizar orçamento expirado ${budget.id}: $e');
      }
    }
  }

  /// Método para verificar manualmente orçamentos expirados
  /// Pode ser chamado periodicamente ou em momentos específicos
  Future<void> checkExpiredBudgets() async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collectionName)
              .where('status', isEqualTo: BudgetStatus.pending.index)
              .get();

      final budgets =
          querySnapshot.docs.map((doc) => Budget.fromMap(doc.data())).toList();

      await _checkAndUpdateExpiredBudgets(budgets);
    } catch (e) {
      throw Exception('Erro ao verificar orçamentos expirados: $e');
    }
  }

  /// Busca orçamentos que expiram em X dias
  Future<List<Budget>> getBudgetsExpiringInDays(int days) async {
    try {
      final targetDate = DateTime.now().add(Duration(days: days));
      final startOfDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot =
          await _firestore
              .collection(_collectionName)
              .where('status', isEqualTo: BudgetStatus.pending.index)
              .where(
                'expirationDate',
                isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch,
              )
              .where(
                'expirationDate',
                isLessThan: endOfDay.millisecondsSinceEpoch,
              )
              .get();

      return querySnapshot.docs
          .map((doc) => Budget.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception(
        'Erro ao buscar orçamentos que expiram em $days dias: $e',
      );
    }
  }

  /// Força a verificação e atualização de todos os orçamentos expirados
  /// Use este método quando precisar garantir que todos os orçamentos estejam atualizados
  Future<void> forceUpdateExpiredBudgets() async {
    try {
      print('🔍 Iniciando verificação forçada de orçamentos expirados...');

      final querySnapshot =
          await _firestore
              .collection(_collectionName)
              .where('status', isEqualTo: BudgetStatus.pending.index)
              .get();

      final budgets =
          querySnapshot.docs.map((doc) => Budget.fromMap(doc.data())).toList();

      print(
        '📊 Encontrados ${budgets.length} orçamentos pendentes para verificação',
      );

      int updatedCount = 0;
      for (final budget in budgets) {
        if (_shouldMarkAsExpired(budget)) {
          final expiredBudget = Budget(
            id: budget.id,
            clientName: budget.clientName,
            projectName: budget.projectName,
            totalValue: budget.totalValue,
            creationDate: budget.creationDate,
            expirationDate: budget.expirationDate,
            status: BudgetStatus.expired,
            description: budget.description,
            items: budget.items,
            projectId: budget.projectId,
          );

          try {
            await updateBudget(expiredBudget);
            updatedCount++;
            print(
              '✅ Orçamento ${budget.id} (${budget.clientName}) marcado como expirado',
            );
          } catch (e) {
            print('❌ Erro ao atualizar orçamento ${budget.id}: $e');
          }
        }
      }

      print(
        '🏁 Verificação concluída. $updatedCount orçamentos foram atualizados para expirado',
      );
    } catch (e) {
      print('❌ Erro na verificação forçada: $e');
      throw Exception('Erro ao forçar atualização de orçamentos expirados: $e');
    }
  }

  /// Busca estatísticas de orçamentos
  Future<Map<String, int>> getBudgetStats() async {
    try {
      final querySnapshot = await _firestore.collection(_collectionName).get();
      final budgets =
          querySnapshot.docs.map((doc) => Budget.fromMap(doc.data())).toList();

      // Verificar orçamentos expirados primeiro
      await _checkAndUpdateExpiredBudgets(budgets);

      // Contar por status
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
            // Verificar se expira em 7 dias
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
  // ─────────────────────────────────────────────────────────────────────────────
// PATCH — ServiceOrcamentos
// Adicione este método dentro da classe ServiceOrcamentos.
//
// Dependências necessárias no topo do arquivo (adicione se não existirem):
//   import 'package:project_granith/models/project_model.dart';
// ─────────────────────────────────────────────────────────────────────────────

/// Aprova um orçamento e cria o projeto vinculado atomicamente.
///
/// Regra #21: orçamento aprovado → projeto criado automaticamente.
///
/// O que faz em batch único:
///   1. Muda budget.status → approved
///   2. Cria documento em /projects com dados do orçamento
///   3. Vincula budget.projectId → ID do projeto criado
///
/// Retorna o ID do projeto criado.
Future<String> approveBudget(Budget budget) async {
  if (budget.status == BudgetStatus.approved && budget.projectId != null) {
    // Já aprovado e vinculado — retorna o projeto existente sem duplicar.
    return budget.projectId!;
  }

  final db = _firestore;
  final batch = db.batch();

  // ── 1. Referência do novo projeto (ID gerado pelo Firestore) ──────────────
  final projectRef = db.collection('projects').doc();

  // ── 2. Monta o Project a partir dos dados do Budget ───────────────────────
  final now = DateTime.now();
  final project = Project(
    id:          projectRef.id,
    name:        budget.projectName,
    client:      budget.clientName,
    description: budget.description,
    status:      ProjectStatus.planning,   // começa em planejamento
    startDate:   now,
    endDate:     budget.expirationDate,    // prazo do orçamento vira prazo do projeto
    budget:      budget.totalValue,
    currentCost: 0,
    location:    '',                        // usuário preenche depois no projeto
    tags:        ['Gerado por orçamento'],
    teamSize:    0,
  );

  // ── 3. Batch: cria projeto ────────────────────────────────────────────────
  batch.set(projectRef, {
    ...project.toMap(),
    // Rastreabilidade: qual orçamento originou este projeto
    'sourceBudgetId': budget.id,
    'createdAt':      Timestamp.fromDate(now),
    'updatedAt':      Timestamp.fromDate(now),
  });

  // ── 4. Batch: atualiza orçamento → approved + projectId ──────────────────
  final budgetRef = db.collection(_collectionName).doc(budget.id);
  batch.update(budgetRef, {
    'status':    BudgetStatus.approved.index,
    'projectId': projectRef.id,
  });

  await batch.commit();

  return projectRef.id;
}

/// Rejeita um orçamento (sem efeitos colaterais).
Future<void> rejectBudget(String budgetId) async {
  await _firestore.collection(_collectionName).doc(budgetId).update({
    'status': BudgetStatus.rejected.index,
  });
}
}
