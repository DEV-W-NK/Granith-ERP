import 'package:project_granith/core/data/db_value.dart';

class BenefitHistoryEntry {
  final double previousValue;
  final double newValue;
  final DateTime changedAt;
  final String changedBy;
  final String reason;

  BenefitHistoryEntry({
    required this.previousValue,
    required this.newValue,
    required this.changedAt,
    required this.changedBy,
    this.reason = '',
  });

  Map<String, dynamic> toMap() => {
    'previousValue': previousValue,
    'newValue': newValue,
    'changedAt': DbValue.toPrimitive(changedAt),
    'changedBy': changedBy,
    'reason': reason,
  };

  factory BenefitHistoryEntry.fromMap(Map<String, dynamic> map) =>
      BenefitHistoryEntry(
        previousValue: (map['previousValue'] ?? 0.0).toDouble(),
        newValue: (map['newValue'] ?? 0.0).toDouble(),
        changedAt: DbValue.toDateTime(map['changedAt']) ?? DateTime.now(),
        changedBy: map['changedBy'] ?? '',
        reason: map['reason'] ?? '',
      );
}

class EmployeeBenefitModel {
  final String id;
  final String employeeId;
  final String benefitId;
  final String benefitName; // desnormalizado para exibição rápida
  final double dailyValue;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<BenefitHistoryEntry> history;

  EmployeeBenefitModel({
    required this.id,
    required this.employeeId,
    required this.benefitId,
    required this.benefitName,
    double? dailyValue,
    @Deprecated('Use dailyValue.') double? monthlyValue,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.history = const [],
  }) : dailyValue = dailyValue ?? monthlyValue ?? 0;

  @Deprecated('Use dailyValue.')
  double get monthlyValue => dailyValue;

  double get totalHistoricalCost {
    if (history.isEmpty) return 0;
    return history.fold(0, (sum, e) => sum + e.newValue);
  }

  double costForWorkedDays(int workedDays) {
    if (workedDays <= 0) return 0;
    return dailyValue * workedDays;
  }

  Map<String, dynamic> toMap() => {
    'employeeId': employeeId,
    'benefitId': benefitId,
    'benefitName': benefitName,
    'dailyValue': dailyValue,
    'monthlyValue': dailyValue,
    'startDate': DbValue.toPrimitive(startDate),
    'endDate': DbValue.toPrimitive(endDate),
    'isActive': isActive,
    'history': history.map((e) => e.toMap()).toList(),
  };

  factory EmployeeBenefitModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) => EmployeeBenefitModel(
    id: docId,
    employeeId: map['employeeId'] ?? '',
    benefitId: map['benefitId'] ?? '',
    benefitName: map['benefitName'] ?? '',
    dailyValue: _toDouble(map['dailyValue'] ?? map['monthlyValue']),
    startDate: DbValue.toDateTime(map['startDate']) ?? DateTime.now(),
    endDate: DbValue.toDateTime(map['endDate']),
    isActive: map['isActive'] ?? true,
    history:
        (map['history'] as List<dynamic>? ?? [])
            .map((e) => BenefitHistoryEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
  );

  EmployeeBenefitModel copyWith({
    String? employeeId,
    String? benefitId,
    String? benefitName,
    double? dailyValue,
    @Deprecated('Use dailyValue.') double? monthlyValue,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? isActive,
    List<BenefitHistoryEntry>? history,
  }) => EmployeeBenefitModel(
    id: id,
    employeeId: employeeId ?? this.employeeId,
    benefitId: benefitId ?? this.benefitId,
    benefitName: benefitName ?? this.benefitName,
    dailyValue: dailyValue ?? monthlyValue ?? this.dailyValue,
    startDate: startDate ?? this.startDate,
    endDate: clearEndDate ? null : endDate ?? this.endDate,
    isActive: isActive ?? this.isActive,
    history: history ?? this.history,
  );
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  return 0;
}
