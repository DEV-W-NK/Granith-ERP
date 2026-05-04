import 'package:project_granith/core/data/db_value.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

/// Direção da transação no fluxo de caixa.
enum TransactionType { income, expense }

/// Ciclo de vida do pagamento.
enum TransactionStatus { pending, paid, overdue, cancelled }

/// Qual módulo originou esta transação.
/// Usado para rastreabilidade e para montar relatórios por tipo de custo.
enum TransactionOrigin {
  manual, // lançado diretamente pelo usuário na tela financeira
  purchase, // gerado automaticamente pelo recebimento de uma compra
  laborCost, // gerado pelo diário de obra (horas × valor/hora) — futuro
  materialUsage, // gerado pelo consumo de material no diário de obra — futuro
  budget, // receita vinculada à medição / aprovação de orçamento
}

/// Categoria do custo/receita para agrupamento em relatórios.
/// Substitui o campo String livre — garante consistência nas queries.
enum TransactionCategory {
  material, // compra ou consumo de material
  labor, // mão de obra
  equipment, // aluguel ou compra de equipamento
  administrative, // despesas administrativas (escritório, contador, etc.)
  measurement, // medição / faturamento ao cliente
  tax, // impostos e taxas
  other, // demais casos
}

// ─── Model ────────────────────────────────────────────────────────────────────

class FinancialTransactionModel {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final TransactionOrigin origin;
  final TransactionCategory category;

  /// Data de vencimento (sempre obrigatória).
  final DateTime dueDate;

  /// Data em que o pagamento foi efetivado. Nulo enquanto não pago.
  final DateTime? paymentDate;

  // ── Rastreabilidade ──────────────────────────────────────────────────────

  /// Projeto ao qual esta transação pertence.
  /// Obrigatório para despesas de projeto; pode ser nulo para despesas
  /// administrativas que não pertencem a nenhum projeto específico.
  final String? projectId;

  /// Fornecedor vinculado (compras, serviços).
  final String? supplierId;

  /// ID do documento que originou esta transação.
  /// Ex: purchaseId quando origin == purchase,
  ///     dailyLogId quando origin == laborCost ou materialUsage.
  /// Permite navegar de volta à origem sem queries extras.
  final String? referenceId;

  // ── Metadata ────────────────────────────────────────────────────────────

  /// Usuário que criou ou que é responsável pela transação.
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Notas ou observações livres (recibo, NF, comentário).
  final String? notes;

  const FinancialTransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.status,
    required this.origin,
    required this.category,
    required this.dueDate,
    this.paymentDate,
    this.projectId,
    this.supplierId,
    this.referenceId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  // ── Computed ────────────────────────────────────────────────────────────

  /// Retorna true se a transação está atrasada e ainda não foi paga.
  bool get isOverdue =>
      status == TransactionStatus.pending && dueDate.isBefore(DateTime.now());

  /// Retorna true se pertence a um projeto específico.
  bool get hasProject => projectId != null && projectId!.isNotEmpty;

  // ── Serialização ────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'origin': origin.name,
      'category': category.name,
      'dueDate': DbValue.toPrimitive(dueDate),
      'paymentDate': DbValue.toPrimitive(paymentDate),
      'projectId': projectId,
      'supplierId': supplierId,
      'referenceId': referenceId,
      'createdBy': createdBy,
      'createdAt': DbValue.toPrimitive(createdAt),
      'updatedAt': DbValue.toPrimitive(updatedAt),
      'notes': notes,
    };
  }

  factory FinancialTransactionModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    return FinancialTransactionModel(
      id: docId,
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: _enumFromName(
        TransactionType.values,
        map['type'],
        TransactionType.expense,
      ),
      status: _enumFromName(
        TransactionStatus.values,
        map['status'],
        TransactionStatus.pending,
      ),
      origin: _enumFromName(
        TransactionOrigin.values,
        map['origin'],
        TransactionOrigin.manual,
      ),
      category: _enumFromName(
        TransactionCategory.values,
        map['category'],
        TransactionCategory.other,
      ),
      dueDate: DbValue.toDateTime(map['dueDate']) ?? DateTime.now(),
      paymentDate: DbValue.toDateTime(map['paymentDate']),
      projectId: map['projectId'],
      supplierId: map['supplierId'],
      referenceId: map['referenceId'],
      createdBy: map['createdBy'] ?? '',
      createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: DbValue.toDateTime(map['updatedAt']),
      notes: map['notes'],
    );
  }

  DateTime? get date => null;

  // ── copyWith ─────────────────────────────────────────────────────────────

  FinancialTransactionModel copyWith({
    String? id,
    String? description,
    double? amount,
    TransactionType? type,
    TransactionStatus? status,
    TransactionOrigin? origin,
    TransactionCategory? category,
    DateTime? dueDate,
    DateTime? paymentDate,
    String? projectId,
    String? supplierId,
    String? referenceId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return FinancialTransactionModel(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      paymentDate: paymentDate ?? this.paymentDate,
      projectId: projectId ?? this.projectId,
      supplierId: supplierId ?? this.supplierId,
      referenceId: referenceId ?? this.referenceId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  /// Marca a transação como paga agora.
  FinancialTransactionModel markAsPaid() {
    return copyWith(
      status: TransactionStatus.paid,
      paymentDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'FinancialTransactionModel(id: $id, type: ${type.name}, '
      'amount: $amount, origin: ${origin.name}, projectId: $projectId)';
}

// ─── Helper ───────────────────────────────────────────────────────────────────

/// Converte string persistida para enum com fallback seguro.
T _enumFromName<T extends Enum>(List<T> values, dynamic name, T fallback) {
  if (name == null) return fallback;
  return values.firstWhere(
    (e) => e.name == name.toString(),
    orElse: () => fallback,
  );
}
