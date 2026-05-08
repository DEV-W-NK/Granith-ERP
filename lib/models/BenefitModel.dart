import 'package:project_granith/core/data/db_value.dart';

enum BenefitType { vt, vr, health, dental, lifeInsurance, other }

enum BenefitValueMode { workedDay, reimbursement, fixedMonthly }

class BenefitModel {
  final String id;
  final String name; // "Vale Transporte", "Vale Refeição"...
  final BenefitType type;
  final String? categoryId;
  final String categoryName;
  final BenefitValueMode valueMode;
  final double dailyValue;
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
    this.valueMode = BenefitValueMode.workedDay,
    double? dailyValue,
    @Deprecated('Use dailyValue.') double? defaultValue,
    this.reimbursementLimit = 0,
    this.description = '',
    this.isActive = true,
    required this.createdAt,
  }) : dailyValue = dailyValue ?? defaultValue ?? 0;

  @Deprecated('Use dailyValue.')
  double get defaultValue => dailyValue;

  String get typeLabel => switch (type) {
    BenefitType.vt => 'Vale Transporte',
    BenefitType.vr => 'Vale Refeição',
    BenefitType.health => 'Plano de Saúde',
    BenefitType.dental => 'Plano Odontológico',
    BenefitType.lifeInsurance => 'Seguro de Vida',
    BenefitType.other => 'Outro',
  };

  String get valueModeLabel => switch (valueMode) {
    BenefitValueMode.workedDay => 'Por dia trabalhado',
    BenefitValueMode.reimbursement => 'Reembolso',
    BenefitValueMode.fixedMonthly => 'Por dia trabalhado',
  };

  double get suggestedAssignmentValue =>
      valueMode == BenefitValueMode.reimbursement
          ? reimbursementLimit
          : dailyValue;

  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type.name,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'valueMode':
        valueMode == BenefitValueMode.reimbursement
            ? BenefitValueMode.reimbursement.name
            : BenefitValueMode.workedDay.name,
    'dailyValue': dailyValue,
    'defaultValue': dailyValue,
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
        valueMode: _valueModeFromMap(map),
        dailyValue: _toDouble(map['dailyValue'] ?? map['defaultValue']),
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
    double? dailyValue,
    @Deprecated('Use dailyValue.') double? defaultValue,
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
    dailyValue: dailyValue ?? defaultValue ?? this.dailyValue,
    reimbursementLimit: reimbursementLimit ?? this.reimbursementLimit,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}

BenefitValueMode _valueModeFromMap(Map<String, dynamic> map) {
  final raw = map['valueMode']?.toString();
  if (raw == BenefitValueMode.reimbursement.name ||
      map['isReimbursable'] == true) {
    return BenefitValueMode.reimbursement;
  }
  return BenefitValueMode.workedDay;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
