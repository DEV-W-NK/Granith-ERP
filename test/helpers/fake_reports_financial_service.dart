import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/services/financial_service.dart';

class FakeReportsFinancialService extends FinancialService {
  FakeReportsFinancialService({
    Map<String, double>? categorySums,
    List<FinancialTransactionModel>? transactions,
  }) : _categorySums = categorySums ?? const <String, double>{},
       _transactions = transactions ?? const <FinancialTransactionModel>[],
       super();

  final Map<String, double> _categorySums;
  final List<FinancialTransactionModel> _transactions;

  TransactionType? lastType;
  DateTime? lastFrom;
  DateTime? lastTo;
  String? lastProjectId;

  @override
  Future<Map<String, double>> getSumByCategory({
    required TransactionType type,
    DateTime? from,
    DateTime? to,
    String? projectId,
  }) async {
    lastType = type;
    lastFrom = from;
    lastTo = to;
    lastProjectId = projectId;
    return Map<String, double>.from(_categorySums);
  }

  @override
  Future<List<FinancialTransactionModel>> getTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    return _transactions.where((transaction) {
      if (from != null && transaction.dueDate.isBefore(from)) return false;
      if (to != null && transaction.dueDate.isAfter(to)) return false;
      return true;
    }).toList();
  }
}
