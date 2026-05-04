import 'dart:async';

import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/services/financial_service.dart';

class FakeFinancialService extends FinancialService {
  FakeFinancialService({List<FinancialTransactionModel>? initialTransactions})
    : _transactions = List<FinancialTransactionModel>.from(
        initialTransactions ?? const <FinancialTransactionModel>[],
      ),
      super();

  final StreamController<List<FinancialTransactionModel>> _controller =
      StreamController<List<FinancialTransactionModel>>.broadcast();
  final List<FinancialTransactionModel> _transactions;

  FinancialTransactionModel? lastAddedTransaction;
  FinancialTransactionModel? lastUpdatedTransaction;
  String? lastMarkedAsPaidId;
  String? lastCancelledId;
  String? lastDeletedId;
  Object? addError;
  Object? updateError;
  Object? markAsPaidError;
  Object? cancelError;
  Object? deleteError;

  void emit(List<FinancialTransactionModel> transactions) {
    _transactions
      ..clear()
      ..addAll(transactions);
    _controller.add(List<FinancialTransactionModel>.from(_transactions));
  }

  @override
  Stream<List<FinancialTransactionModel>> watchAll() => _controller.stream;

  @override
  Future<String> addTransaction(FinancialTransactionModel transaction) async {
    if (addError != null) {
      throw addError!;
    }

    lastAddedTransaction = transaction;
    _transactions.add(transaction);
    _controller.add(List<FinancialTransactionModel>.from(_transactions));
    return transaction.id.isEmpty ? 'generated-financial-id' : transaction.id;
  }

  @override
  Future<void> updateTransaction(FinancialTransactionModel transaction) async {
    if (updateError != null) {
      throw updateError!;
    }

    lastUpdatedTransaction = transaction;
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _controller.add(List<FinancialTransactionModel>.from(_transactions));
    }
  }

  @override
  Future<void> markAsPaid(String id) async {
    if (markAsPaidError != null) {
      throw markAsPaidError!;
    }

    lastMarkedAsPaidId = id;
  }

  @override
  Future<void> cancelTransaction(String id) async {
    if (cancelError != null) {
      throw cancelError!;
    }

    lastCancelledId = id;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (deleteError != null) {
      throw deleteError!;
    }

    lastDeletedId = id;
    _transactions.removeWhere((item) => item.id == id);
    _controller.add(List<FinancialTransactionModel>.from(_transactions));
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
