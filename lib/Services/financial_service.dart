import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_granith/models/financial_transaction_model.dart';

class FinancialService {
  final FirebaseFirestore _firestore;

  FinancialService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col =>
      _firestore.collection('financial_transactions');

  // ─── Streams ────────────────────────────────────────────────────────────────

  /// Todas as transações, ordenadas por vencimento.
  Stream<List<FinancialTransactionModel>> watchAll() {
    return _col
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// Transações de um projeto específico.
  Stream<List<FinancialTransactionModel>> watchByProject(String projectId) {
    return _col
        .where('projectId', isEqualTo: projectId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// Transações dentro de um intervalo de datas (pelo dueDate).
  Stream<List<FinancialTransactionModel>> watchByPeriod(
      DateTime from, DateTime to) {
    return _col
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// Transações por tipo (income / expense).
  Stream<List<FinancialTransactionModel>> watchByType(TransactionType type) {
    return _col
        .where('type', isEqualTo: type.name)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// Transações por status (pending, paid, overdue, cancelled).
  Stream<List<FinancialTransactionModel>> watchByStatus(
      TransactionStatus status) {
    return _col
        .where('status', isEqualTo: status.name)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  /// Transações por origem (purchase, laborCost, manual, etc.).
  Stream<List<FinancialTransactionModel>> watchByOrigin(
      TransactionOrigin origin) {
    return _col
        .where('origin', isEqualTo: origin.name)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map(_mapSnapshot);
  }

  // ─── Futures (consultas pontuais) ────────────────────────────────────────────

  /// Busca uma transação específica pelo ID.
  Future<FinancialTransactionModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return FinancialTransactionModel.fromMap(
        doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Busca todas as transações vinculadas a um documento de origem.
  /// Ex: buscar todas as transações geradas por uma compra específica.
  Future<List<FinancialTransactionModel>> getByReference(
      String referenceId) async {
    final snap = await _col
        .where('referenceId', isEqualTo: referenceId)
        .orderBy('dueDate', descending: true)
        .get();
    return snap.docs
        .map((d) => FinancialTransactionModel.fromMap(
            d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  /// Soma de receitas pagas de um projeto.
  Future<double> getTotalIncomeByProject(String projectId) async {
    final snap = await _col
        .where('projectId', isEqualTo: projectId)
        .where('type', isEqualTo: TransactionType.income.name)
        .where('status', isEqualTo: TransactionStatus.paid.name)
        .get();
    return snap.docs.fold<double>(
        0, (sum, d) => sum + ((d.data() as Map)['amount'] ?? 0.0));
  }

  /// Soma de despesas pagas de um projeto (custo realizado).
  Future<double> getTotalExpenseByProject(String projectId) async {
    final snap = await _col
        .where('projectId', isEqualTo: projectId)
        .where('type', isEqualTo: TransactionType.expense.name)
        .where('status', isEqualTo: TransactionStatus.paid.name)
        .get();
    return snap.docs.fold<double>(
        0, (sum, d) => sum + ((d.data() as Map)['amount'] ?? 0.0));
  }

  /// Transações agrupadas por categoria — base para DRE real.
  /// Retorna um mapa { categoryName: totalAmount }.
  Future<Map<String, double>> getSumByCategory({
    required TransactionType type,
    DateTime? from,
    DateTime? to,
    String? projectId,
  }) async {
    Query query = _col.where('type', isEqualTo: type.name);

    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    if (from != null) {
      query = query.where('dueDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query =
          query.where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(to));
    }

    final snap = await query.get();
    final result = <String, double>{};

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final cat = data['category'] as String? ?? 'other';
      final amount = (data['amount'] ?? 0.0).toDouble();
      result[cat] = (result[cat] ?? 0.0) + amount;
    }

    return result;
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────────

  /// Adiciona uma nova transação. O ID é gerado pelo Firestore.
  Future<String> addTransaction(FinancialTransactionModel transaction) async {
    final docRef = await _col.add(transaction.toMap());
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  /// Adiciona múltiplas transações em batch.
  /// Útil quando um recebimento de compra gera entrada no estoque
  /// e despesa financeira simultaneamente.
  Future<void> addTransactionsBatch(
      List<FinancialTransactionModel> transactions) async {
    final batch = _firestore.batch();
    for (final t in transactions) {
      final docRef = _col.doc();
      batch.set(docRef, {...t.toMap(), 'id': docRef.id});
    }
    await batch.commit();
  }

  Future<void> updateTransaction(FinancialTransactionModel transaction) async {
    await _col.doc(transaction.id).update(transaction.toMap());
  }

  /// Marca como pago e registra a data de pagamento.
  Future<void> markAsPaid(String id) async {
    await _col.doc(id).update({
      'status': TransactionStatus.paid.name,
      'paymentDate': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Cancela uma transação (não deleta — mantém histórico).
  Future<void> cancelTransaction(String id) async {
    await _col.doc(id).update({
      'status': TransactionStatus.cancelled.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteTransaction(String id) async {
    await _col.doc(id).delete();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  List<FinancialTransactionModel> _mapSnapshot(QuerySnapshot snap) {
    return snap.docs
        .map((d) => FinancialTransactionModel.fromMap(
            d.data() as Map<String, dynamic>, d.id))
        .toList();
  }
}