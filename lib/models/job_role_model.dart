import 'package:project_granith/core/data/db_value.dart';

class JobRoleModel {
  final String id;
  final String title;
  final String sector;
  final String description;

  // Usado para calculo de custo de mao de obra em obras.
  // Salario fixo pertence ao funcionario, nao ao cargo.
  final double hourlyRate;

  final List<String> requirements;
  final bool isActive;
  final DateTime createdAt;

  JobRoleModel({
    required this.id,
    required this.title,
    required this.sector,
    this.description = '',
    required this.hourlyRate,
    this.requirements = const [],
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'sector': sector,
    'description': description,
    'hourlyRate': hourlyRate,
    'requirements': requirements,
    'isActive': isActive,
    'createdAt': DbValue.toPrimitive(createdAt),
  };

  factory JobRoleModel.fromMap(Map<String, dynamic> map, String docId) =>
      JobRoleModel(
        id: docId,
        title: map['title'] ?? '',
        sector: map['sector'] ?? '',
        description: map['description'] ?? '',
        hourlyRate: _toDouble(map['hourlyRate']),
        requirements: List<String>.from(map['requirements'] ?? []),
        isActive: map['isActive'] ?? true,
        createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
      );

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  JobRoleModel copyWith({
    String? title,
    String? sector,
    String? description,
    double? hourlyRate,
    List<String>? requirements,
    bool? isActive,
  }) => JobRoleModel(
    id: id,
    title: title ?? this.title,
    sector: sector ?? this.sector,
    description: description ?? this.description,
    hourlyRate: hourlyRate ?? this.hourlyRate,
    requirements: requirements ?? this.requirements,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}
