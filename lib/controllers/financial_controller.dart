import 'dart:async';
import 'package:flutter/material.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/services/financial_service.dart';

class FinancialController extends ChangeNotifier {
  final FinancialService _service;

  FinancialController({FinancialService? service})
    : _service = service ?? FinancialService();

  // ─── Estado interno ──────────────────────────────────────────────────────────

  List<FinancialTransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  /// Filtro de projeto ativo. Null = todas as transações.
  String? _activeProjectId;

  /// Filtro de período ativo.
  DateTime? _periodFrom;
  DateTime? _periodTo;

  StreamSubscription<List<FinancialTransactionModel>>? _subscription;

  // ─── Getters públicos ────────────────────────────────────────────────────────

  List<FinancialTransactionModel> get transactions => _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get activeProjectId => _activeProjectId;
  DateTime? get periodFrom => _periodFrom;
  DateTime? get periodTo => _periodTo;

  /// Transações após aplicar filtros de projeto e período.
  List<FinancialTransactionModel> get _filtered {
    var list = List<FinancialTransactionModel>.from(_transactions);

    if (_activeProjectId != null) {
      list = list.where((t) => t.projectId == _activeProjectId).toList();
    }

    if (_periodFrom != null) {
      list = list.where((t) => !t.dueDate.isBefore(_periodFrom!)).toList();
    }

    if (_periodTo != null) {
      list = list.where((t) => !t.dueDate.isAfter(_periodTo!)).toList();
    }

    return list;
  }

  // ─── Getters financeiros (calculados sobre _filtered) ────────────────────────

  /// Receitas efetivamente recebidas.
  double get totalIncome => _sumWhere(
    (t) =>
        t.type == TransactionType.income && t.status == TransactionStatus.paid,
  );

  /// Despesas efetivamente pagas.
  double get totalExpense => _sumWhere(
    (t) =>
        t.type == TransactionType.expense && t.status == TransactionStatus.paid,
  );

  /// Saldo atual (receitas pagas - despesas pagas).
  double get balance => totalIncome - totalExpense;

  /// Despesas pendentes ainda dentro do prazo.
  double get totalPendingExpense => _sumWhere(
    (t) =>
        t.type == TransactionType.expense &&
        t.status == TransactionStatus.pending,
  );

  /// Despesas vencidas e não pagas.
  double get totalOverdueExpense => _sumWhere(
    (t) =>
        t.type == TransactionType.expense &&
        (t.status == TransactionStatus.overdue || t.isOverdue),
  );

  /// Receitas previstas ainda não recebidas.
  double get totalPendingIncome => _sumWhere(
    (t) =>
        t.type == TransactionType.income &&
        t.status == TransactionStatus.pending,
  );

  /// Transações com status overdue (para badge de alerta na UI).
  List<FinancialTransactionModel> get overdueTransactions =>
      _filtered
          .where(
            (t) =>
                t.status == TransactionStatus.overdue ||
                (t.status == TransactionStatus.pending && t.isOverdue),
          )
          .toList();

  /// Agrupa despesas pagas por categoria — alimenta gráficos e DRE.
  Map<TransactionCategory, double> get expensesByCategory {
    final map = <TransactionCategory, double>{};
    for (final t in _filtered) {
      if (t.type == TransactionType.expense &&
          t.status == TransactionStatus.paid) {
        map[t.category] = (map[t.category] ?? 0.0) + t.amount;
      }
    }
    return map;
  }

  /// Agrupa receitas pagas por categoria.
  Map<TransactionCategory, double> get incomeByCategory {
    final map = <TransactionCategory, double>{};
    for (final t in _filtered) {
      if (t.type == TransactionType.income &&
          t.status == TransactionStatus.paid) {
        map[t.category] = (map[t.category] ?? 0.0) + t.amount;
      }
    }
    return map;
  }

  /// Agrupa despesas por origem — útil para separar M.O. de material de compras.
  Map<TransactionOrigin, double> get expensesByOrigin {
    final map = <TransactionOrigin, double>{};
    for (final t in _filtered) {
      if (t.type == TransactionType.expense) {
        map[t.origin] = (map[t.origin] ?? 0.0) + t.amount;
      }
    }
    return map;
  }

  // ─── Inicialização ───────────────────────────────────────────────────────────

  /// Inicia o stream de transacoes. Chamar no initState ou no Provider.
  void init() {
    _setLoading(true);
    _subscription?.cancel();
    _subscription = _service.watchAll().listen(
      (list) {
        _transactions = list;
        _syncOverdueStatus();
        _setLoading(false);
      },
      onError: (e) {
        _error = e.toString();
        _setLoading(false);
      },
    );
  }

  /// Troca o filtro de projeto e reinicia o stream filtrado.
  void setProjectFilter(String? projectId) {
    _activeProjectId = projectId;
    notifyListeners();
  }

  /// Define o intervalo de período para filtro.
  void setPeriodFilter(DateTime? from, DateTime? to) {
    _periodFrom = from;
    _periodTo = to;
    notifyListeners();
  }

  /// Atalho: filtra pelo mês atual.
  void setCurrentMonthFilter() {
    final now = DateTime.now();
    _periodFrom = DateTime(now.year, now.month, 1);
    _periodTo = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    notifyListeners();
  }

  /// Remove todos os filtros.
  void clearFilters() {
    _activeProjectId = null;
    _periodFrom = null;
    _periodTo = null;
    notifyListeners();
  }

  // ─── Ações ───────────────────────────────────────────────────────────────────

  Future<void> addTransaction(FinancialTransactionModel transaction) async {
    try {
      await _service.addTransaction(transaction);
      // Stream atualiza a lista automaticamente — não precisa notifyListeners aqui.
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Usado pelo purchase_service ao confirmar recebimento de compra.
  /// Cria a transação financeira e retorna o ID gerado.
  Future<String?> addTransactionFromPurchase({
    required String description,
    required double amount,
    required String projectId,
    required String supplierId,
    required String purchaseId,
    required String createdBy,
  }) async {
    try {
      final transaction = FinancialTransactionModel(
        id: '',
        description: description,
        amount: amount,
        type: TransactionType.expense,
        status: TransactionStatus.paid,
        origin: TransactionOrigin.purchase,
        category: TransactionCategory.material,
        dueDate: DateTime.now(),
        paymentDate: DateTime.now(),
        projectId: projectId,
        supplierId: supplierId,
        referenceId: purchaseId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
      );
      return await _service.addTransaction(transaction);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateTransaction(FinancialTransactionModel transaction) async {
    try {
      final updated = transaction.copyWith(updatedAt: DateTime.now());
      await _service.updateTransaction(updated);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsPaid(String id) async {
    try {
      await _service.markAsPaid(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelTransaction(String id) async {
    try {
      await _service.cancelTransaction(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _service.deleteTransaction(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Verifica e atualiza o status de overdue nas transações pendentes.
  /// O backend nao atualiza status automaticamente; fazemos client-side.
  void _syncOverdueStatus() {
    final now = DateTime.now();
    bool changed = false;

    for (int i = 0; i < _transactions.length; i++) {
      final t = _transactions[i];
      if (t.status == TransactionStatus.pending &&
          t.dueDate.isBefore(now) &&
          t.type == TransactionType.expense) {
        _transactions[i] = t.copyWith(status: TransactionStatus.overdue);
        changed = true;
        // Opcional: persistir o ajuste em background.
        _service.updateTransaction(_transactions[i]);
      }
    }

    if (changed) notifyListeners();
  }

  double _sumWhere(bool Function(FinancialTransactionModel) predicate) {
    return _filtered.where(predicate).fold(0.0, (sum, t) => sum + t.amount);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
