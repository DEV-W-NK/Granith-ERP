import 'package:cloud_firestore/cloud_firestore.dart';

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
        'newValue':      newValue,
        'changedAt':     Timestamp.fromDate(changedAt),
        'changedBy':     changedBy,
        'reason':        reason,
      };

  factory BenefitHistoryEntry.fromMap(Map<String, dynamic> map) =>
      BenefitHistoryEntry(
        previousValue: (map['previousValue'] ?? 0.0).toDouble(),
        newValue:      (map['newValue'] ?? 0.0).toDouble(),
        changedAt:     (map['changedAt'] as Timestamp).toDate(),
        changedBy:     map['changedBy'] ?? '',
        reason:        map['reason'] ?? '',
      );
}

class EmployeeBenefitModel {
  final String id;
  final String employeeId;
  final String benefitId;
  final String benefitName; // desnormalizado para exibição rápida
  final double monthlyValue;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<BenefitHistoryEntry> history;

  EmployeeBenefitModel({
    required this.id,
    required this.employeeId,
    required this.benefitId,
    required this.benefitName,
    required this.monthlyValue,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.history = const [],
  });

  double get totalHistoricalCost {
    if (history.isEmpty) return 0;
    return history.fold(0, (sum, e) => sum + e.newValue);
  }

  Map<String, dynamic> toMap() => {
        'employeeId':   employeeId,
        'benefitId':    benefitId,
        'benefitName':  benefitName,
        'monthlyValue': monthlyValue,
        'startDate':    Timestamp.fromDate(startDate),
        'endDate':      endDate != null ? Timestamp.fromDate(endDate!) : null,
        'isActive':     isActive,
        'history':      history.map((e) => e.toMap()).toList(),
      };

  factory EmployeeBenefitModel.fromMap(Map<String, dynamic> map, String docId) =>
      EmployeeBenefitModel(
        id:           docId,
        employeeId:   map['employeeId'] ?? '',
        benefitId:    map['benefitId'] ?? '',
        benefitName:  map['benefitName'] ?? '',
        monthlyValue: (map['monthlyValue'] ?? 0.0).toDouble(),
        startDate:    (map['startDate'] as Timestamp).toDate(),
        endDate:      (map['endDate'] as Timestamp?)?.toDate(),
        isActive:     map['isActive'] ?? true,
        history:      (map['history'] as List<dynamic>? ?? [])
            .map((e) => BenefitHistoryEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  EmployeeBenefitModel copyWith({
    double? monthlyValue,
    DateTime? endDate,
    bool? isActive,
    List<BenefitHistoryEntry>? history,
  }) =>
      EmployeeBenefitModel(
        id:           id,
        employeeId:   employeeId,
        benefitId:    benefitId,
        benefitName:  benefitName,
        monthlyValue: monthlyValue ?? this.monthlyValue,
        startDate:    startDate,
        endDate:      endDate ?? this.endDate,
        isActive:     isActive ?? this.isActive,
        history:      history ?? this.history,
      );
}