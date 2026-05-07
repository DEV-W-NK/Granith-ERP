import 'package:project_granith/core/data/db_value.dart';

enum BenefitType { vt, vr, health, dental, lifeInsurance, other }

enum BenefitValueMode { fixedMonthly, reimbursement }

class BenefitModel {
  final String id;
  final String name; // "Vale Transporte", "Vale Refeição"...
  final BenefitType type;
  final String? categoryId;
  final String categoryName;
  final BenefitValueMode valueMode;
  final double defaultValue;
  final double reimbursementLimit;
  final String description;
  final bool isActive;
  final DateTime createdAt;

  BenefitModel({
    required this.id,
    required this.name,
    required this.type,
    this.categoryId,
    this.categoryName = '',
    this.valueMode = BenefitValueMode.fixedMonthly,
    this.defaultValue = 0,
    this.reimbursementLimit = 0,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
  });

  String get typeLabel => switch (type) {
    BenefitType.vt => 'Vale Transporte',
    BenefitType.vr => 'Vale Refeição',
    BenefitType.health => 'Plano de Saúde',
    BenefitType.dental => 'Plano Odontológico',
    BenefitType.lifeInsurance => 'Seguro de Vida',
    BenefitType.other => 'Outro',
  };

  String get valueModeLabel => switch (valueMode) {
    BenefitValueMode.fixedMonthly => 'Valor mensal fixo',
    BenefitValueMode.reimbursement => 'Reembolso',
  };

  double get suggestedAssignmentValue =>
      valueMode == BenefitValueMode.reimbursement
          ? reimbursementLimit
          : defaultValue;

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type.name,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'valueMode': valueMode.name,
    'defaultValue': defaultValue,
    'reimbursementLimit': reimbursementLimit,
    'description': description,
    'isActive': isActive,
    'createdAt': DbValue.toPrimitive(createdAt),
  };

  factory BenefitModel.fromMap(Map<String, dynamic> map, String docId) =>
      BenefitModel(
        id: docId,
        name: map['name'] ?? '',
        type: BenefitType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => BenefitType.other,
        ),
        categoryId: map['categoryId'] as String?,
        categoryName: map['categoryName'] ?? map['category'] ?? '',
        valueMode: BenefitValueMode.values.firstWhere(
          (e) => e.name == map['valueMode'],
          orElse:
              () =>
                  map['isReimbursable'] == true
                      ? BenefitValueMode.reimbursement
                      : BenefitValueMode.fixedMonthly,
        ),
        defaultValue: _toDouble(map['defaultValue']),
        reimbursementLimit: _toDouble(map['reimbursementLimit']),
        description: map['description'] ?? '',
        isActive: map['isActive'] ?? true,
        createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      );

  BenefitModel copyWith({
    String? name,
    BenefitType? type,
    String? categoryId,
    String? categoryName,
    bool clearCategory = false,
    BenefitValueMode? valueMode,
    double? defaultValue,
    double? reimbursementLimit,
    String? description,
    bool? isActive,
  }) => BenefitModel(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    categoryName: clearCategory ? '' : categoryName ?? this.categoryName,
    valueMode: valueMode ?? this.valueMode,
    defaultValue: defaultValue ?? this.defaultValue,
    reimbursementLimit: reimbursementLimit ?? this.reimbursementLimit,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
