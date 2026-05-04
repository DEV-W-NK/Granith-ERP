import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';

enum ProjectMeasurementStatus { pending, approved, paid }

extension ProjectMeasurementStatusExtension on ProjectMeasurementStatus {
  String get displayName {
    switch (this) {
      case ProjectMeasurementStatus.pending:
        return 'Pendente';
      case ProjectMeasurementStatus.approved:
        return 'Aprovada';
      case ProjectMeasurementStatus.paid:
        return 'Paga';
    }
  }

  Color get color {
    switch (this) {
      case ProjectMeasurementStatus.pending:
        return Colors.orangeAccent;
      case ProjectMeasurementStatus.approved:
        return Colors.lightBlueAccent;
      case ProjectMeasurementStatus.paid:
        return Colors.greenAccent;
    }
  }
}

class ProjectMeasurement {
  final String id;
  final String projectId;
  final String projectName;
  final String projectClient;
  final String title;
  final int sequence;
  final ProjectMeasurementStatus status;
  final DateTime measurementDate;
  final double grossAmount;
  final double discountAmount;
  final double netAmount;
  final double accumulatedGrossAmount;
  final double measurementPercentage;
  final double accumulatedPercentage;
  final double contractBalance;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProjectMeasurement({
    this.id = '',
    required this.projectId,
    required this.projectName,
    required this.projectClient,
    required this.title,
    required this.sequence,
    required this.status,
    required this.measurementDate,
    required this.grossAmount,
    required this.discountAmount,
    required this.netAmount,
    required this.accumulatedGrossAmount,
    required this.measurementPercentage,
    required this.accumulatedPercentage,
    required this.contractBalance,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  double get clampedAccumulatedPercentage =>
      accumulatedPercentage.clamp(0, 100).toDouble();

  double get clampedMeasurementPercentage =>
      measurementPercentage.clamp(0, 100).toDouble();

  bool get isValid =>
      projectId.trim().isNotEmpty &&
      grossAmount >= 0 &&
      discountAmount >= 0 &&
      discountAmount <= grossAmount;

  ProjectMeasurement copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? projectClient,
    String? title,
    int? sequence,
    ProjectMeasurementStatus? status,
    DateTime? measurementDate,
    double? grossAmount,
    double? discountAmount,
    double? netAmount,
    double? accumulatedGrossAmount,
    double? measurementPercentage,
    double? accumulatedPercentage,
    double? contractBalance,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectMeasurement(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      projectClient: projectClient ?? this.projectClient,
      title: title ?? this.title,
      sequence: sequence ?? this.sequence,
      status: status ?? this.status,
      measurementDate: measurementDate ?? this.measurementDate,
      grossAmount: grossAmount ?? this.grossAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      netAmount: netAmount ?? this.netAmount,
      accumulatedGrossAmount:
          accumulatedGrossAmount ?? this.accumulatedGrossAmount,
      measurementPercentage:
          measurementPercentage ?? this.measurementPercentage,
      accumulatedPercentage:
          accumulatedPercentage ?? this.accumulatedPercentage,
      contractBalance: contractBalance ?? this.contractBalance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProjectMeasurement.empty() {
    return ProjectMeasurement(
      projectId: '',
      projectName: '',
      projectClient: '',
      title: '',
      sequence: 1,
      status: ProjectMeasurementStatus.pending,
      measurementDate: DateTime.now(),
      grossAmount: 0,
      discountAmount: 0,
      netAmount: 0,
      accumulatedGrossAmount: 0,
      measurementPercentage: 0,
      accumulatedPercentage: 0,
      contractBalance: 0,
      notes: '',
    );
  }

  factory ProjectMeasurement.fromMap(String id, Map<String, dynamic> data) {
    final gross =
        ((data['grossAmount'] ?? data['gross_amount']) as num?)?.toDouble() ??
        0;
    final discount =
        ((data['discountAmount'] ?? data['discount_amount']) as num?)
            ?.toDouble() ??
        0;

    return ProjectMeasurement(
      id: id.isNotEmpty ? id : (data['id'] ?? '').toString(),
      projectId: (data['projectId'] ?? data['project_id'] ?? '').toString(),
      projectName:
          (data['projectName'] ?? data['project_name'] ?? '').toString(),
      projectClient:
          (data['projectClient'] ?? data['project_client'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      sequence: ((data['sequence'] ?? 1) as num).toInt(),
      status: ProjectMeasurementStatus.values.firstWhere(
        (item) => item.name == (data['status'] ?? 'pending'),
        orElse: () => ProjectMeasurementStatus.pending,
      ),
      measurementDate:
          DbValue.toDateTime(
            data['measurementDate'] ?? data['measurement_date'],
          ) ??
          DateTime.now(),
      grossAmount: gross,
      discountAmount: discount,
      netAmount:
          ((data['netAmount'] ?? data['net_amount']) as num?)?.toDouble() ??
          (gross - discount).clamp(0, double.infinity).toDouble(),
      accumulatedGrossAmount:
          ((data['accumulatedGrossAmount'] ?? data['accumulated_gross_amount'])
                  as num?)
              ?.toDouble() ??
          0,
      measurementPercentage:
          ((data['measurementPercentage'] ?? data['measurement_percentage'])
                  as num?)
              ?.toDouble() ??
          0,
      accumulatedPercentage:
          ((data['accumulatedPercentage'] ?? data['accumulated_percentage'])
                  as num?)
              ?.toDouble() ??
          0,
      contractBalance:
          ((data['contractBalance'] ?? data['contract_balance']) as num?)
              ?.toDouble() ??
          0,
      notes: (data['notes'] ?? '').toString(),
      createdAt: DbValue.toDateTime(data['createdAt'] ?? data['created_at']),
      updatedAt: DbValue.toDateTime(data['updatedAt'] ?? data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return DbValue.normalizeMap({
      if (id.trim().isNotEmpty) 'id': id,
      'projectId': projectId,
      'project_id': projectId,
      'projectName': projectName,
      'project_name': projectName,
      'projectClient': projectClient,
      'project_client': projectClient,
      'title': title.trim(),
      'sequence': sequence,
      'status': status.name,
      'measurementDate': measurementDate,
      'measurement_date': measurementDate,
      'grossAmount': grossAmount,
      'gross_amount': grossAmount,
      'discountAmount': discountAmount,
      'discount_amount': discountAmount,
      'netAmount': netAmount,
      'net_amount': netAmount,
      'accumulatedGrossAmount': accumulatedGrossAmount,
      'accumulated_gross_amount': accumulatedGrossAmount,
      'measurementPercentage': measurementPercentage,
      'measurement_percentage': measurementPercentage,
      'accumulatedPercentage': accumulatedPercentage,
      'accumulated_percentage': accumulatedPercentage,
      'contractBalance': contractBalance,
      'contract_balance': contractBalance,
      'notes': notes.trim(),
      'createdAt': createdAt,
      'created_at': createdAt,
      'updatedAt': updatedAt,
      'updated_at': updatedAt,
    });
  }
}
