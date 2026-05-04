import 'package:project_granith/core/data/db_value.dart';

class SalaryHistoryModel {
  final String id;
  final String employeeId;
  final double previousSalary;
  final double newSalary;
  final DateTime effectiveDate;
  final String reason; // "Reajuste anual", "Promoção", "Acordo coletivo"...
  final String updatedBy;
  final DateTime createdAt;

  SalaryHistoryModel({
    required this.id,
    required this.employeeId,
    required this.previousSalary,
    required this.newSalary,
    required this.effectiveDate,
    required this.reason,
    required this.updatedBy,
    required this.createdAt,
  });

  double get percentualAumento =>
      previousSalary > 0
          ? ((newSalary - previousSalary) / previousSalary * 100)
          : 0;

  Map<String, dynamic> toMap() => {
    'employeeId': employeeId,
    'previousSalary': previousSalary,
    'newSalary': newSalary,
    'effectiveDate': DbValue.toPrimitive(effectiveDate),
    'reason': reason,
    'updatedBy': updatedBy,
    'createdAt': DbValue.toPrimitive(createdAt),
  };

  factory SalaryHistoryModel.fromMap(Map<String, dynamic> map, String docId) =>
      SalaryHistoryModel(
        id: docId,
        employeeId: map['employeeId'] ?? '',
        previousSalary: (map['previousSalary'] ?? 0.0).toDouble(),
        newSalary: (map['newSalary'] ?? 0.0).toDouble(),
        effectiveDate:
            DbValue.toDateTime(map['effectiveDate']) ?? DateTime.now(),
        reason: map['reason'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
        createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      );
}
