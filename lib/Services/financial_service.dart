import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/financial_transaction_model.dart';

class FinancialService {
  static const _table = 'financial_transactions';

  FinancialService();

  Stream<List<FinancialTransactionModel>> watchAll() {
    return AppSupabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('dueDate', ascending: false)
        .map(_rowsToTransactions);
  }

  Stream<List<FinancialTransactionModel>> watchByProject(String projectId) {
    return watchAll().map(
      (transactions) =>
          transactions
              .where((transaction) => transaction.projectId == projectId)
              .toList(),
    );
  }

  Stream<List<FinancialTransactionModel>> watchByPeriod(
    DateTime from,
    DateTime to,
  ) {
    return watchAll().map(
      (transactions) =>
          transactions.where((transaction) {
            return !transaction.dueDate.isBefore(from) &&
                !transaction.dueDate.isAfter(to);
          }).toList(),
    );
  }

  Stream<List<FinancialTransactionModel>> watchByType(TransactionType type) {
    return watchAll().map(
      (transactions) =>
          transactions
              .where((transaction) => transaction.type == type)
              .toList(),
    );
  }

  Stream<List<FinancialTransactionModel>> watchByStatus(
    TransactionStatus status,
  ) {
    return watchAll().map(
      (transactions) =>
          transactions
              .where((transaction) => transaction.status == status)
              .toList(),
    );
  }

  Stream<List<FinancialTransactionModel>> watchByOrigin(
    TransactionOrigin origin,
  ) {
    return watchAll().map(
      (transactions) =>
          transactions
              .where((transaction) => transaction.origin == origin)
              .toList(),
    );
  }

  Future<FinancialTransactionModel?> getById(String id) async {
    final row =
        await AppSupabase.client
            .from(_table)
            .select()
            .eq('id', id)
            .maybeSingle();
    if (row == null) return null;
    return _rowToTransaction(Map<String, dynamic>.from(row));
  }

  Future<List<FinancialTransactionModel>> getByReference(
    String referenceId,
  ) async {
    final response = await AppSupabase.client
        .from(_table)
        .select()
        .eq('referenceId', referenceId)
        .order('dueDate', ascending: false);

    return _rowsToTransactions(response as List);
  }

  Future<double> getTotalIncomeByProject(String projectId) {
    return _sumByProject(
      projectId: projectId,
      type: TransactionType.income,
      status: TransactionStatus.paid,
    );
  }

  Future<double> getTotalExpenseByProject(String projectId) {
    return _sumByProject(
      projectId: projectId,
      type: TransactionType.expense,
      status: TransactionStatus.paid,
    );
  }

  Future<Map<String, double>> getSumByCategory({
    required TransactionType type,
    DateTime? from,
    DateTime? to,
    String? projectId,
  }) async {
    dynamic query = AppSupabase.client
        .from(_table)
        .select('category, amount')
        .eq('type', type.name);

    if (projectId != null) {
      query = query.eq('projectId', projectId);
    }
    if (from != null) {
      query = query.gte('dueDate', DbValue.toPrimitive(from));
    }
    if (to != null) {
      query = query.lte('dueDate', DbValue.toPrimitive(to));
    }

    final response = await query;
    final result = <String, double>{};

    for (final row in response as List) {
      final data = Map<String, dynamic>.from(row as Map);
      final category = data['category'] as String? ?? 'other';
      final amount = (data['amount'] as num? ?? 0).toDouble();
      result[category] = (result[category] ?? 0) + amount;
    }

    return result;
  }

  Future<String> addTransaction(FinancialTransactionModel transaction) async {
    final data = DbValue.normalizeMap(transaction.toMap());
    if (transaction.id.isNotEmpty) {
      data['id'] = transaction.id;
    }

    final row =
        await AppSupabase.client
            .from(_table)
            .insert(data)
            .select('id')
            .single();

    return row['id'] as String;
  }

  Future<void> addTransactionsBatch(
    List<FinancialTransactionModel> transactions,
  ) async {
    if (transactions.isEmpty) return;

    final rows =
        transactions.map((transaction) {
          final data = DbValue.normalizeMap(transaction.toMap());
          if (transaction.id.isNotEmpty) {
            data['id'] = transaction.id;
          }
          return data;
        }).toList();

    await AppSupabase.client.from(_table).insert(rows);
  }

  Future<void> updateTransaction(FinancialTransactionModel transaction) async {
    await AppSupabase.client
        .from(_table)
        .update(DbValue.normalizeMap(transaction.toMap()))
        .eq('id', transaction.id);
  }

  Future<void> markAsPaid(String id) async {
    final now = DateTime.now();
    await AppSupabase.client
        .from(_table)
        .update({
          'status': TransactionStatus.paid.name,
          'paymentDate': DbValue.toPrimitive(now),
          'updatedAt': DbValue.toPrimitive(now),
        })
        .eq('id', id);
  }

  Future<void> cancelTransaction(String id) async {
    await AppSupabase.client
        .from(_table)
        .update({
          'status': TransactionStatus.cancelled.name,
          'updatedAt': DbValue.toPrimitive(DateTime.now()),
        })
        .eq('id', id);
  }

  Future<void> deleteTransaction(String id) async {
    await AppSupabase.client.from(_table).delete().eq('id', id);
  }

  Future<double> _sumByProject({
    required String projectId,
    required TransactionType type,
    required TransactionStatus status,
  }) async {
    final response = await AppSupabase.client
        .from(_table)
        .select('amount')
        .eq('projectId', projectId)
        .eq('type', type.name)
        .eq('status', status.name);

    return (response as List).fold<double>(0, (sum, row) {
      final data = Map<String, dynamic>.from(row as Map);
      return sum + (data['amount'] as num? ?? 0).toDouble();
    });
  }

  List<FinancialTransactionModel> _rowsToTransactions(List<dynamic> rows) {
    return rows
        .map((row) => _rowToTransaction(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  FinancialTransactionModel _rowToTransaction(Map<String, dynamic> row) {
    return FinancialTransactionModel.fromMap(row, row['id'] as String? ?? '');
  }
}
