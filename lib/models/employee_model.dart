import 'package:project_granith/core/data/db_value.dart';

enum EmployeeRole { funcionario, supervisor, coordenador, gerente }

extension EmployeeRoleHierarchy on EmployeeRole {
  int get level => switch (this) {
    EmployeeRole.funcionario => 1,
    EmployeeRole.supervisor => 2,
    EmployeeRole.coordenador => 3,
    EmployeeRole.gerente => 4,
  };

  String get label => switch (this) {
    EmployeeRole.funcionario => 'Colaborador',
    EmployeeRole.supervisor => 'Supervisao',
    EmployeeRole.coordenador => 'Coordenacao',
    EmployeeRole.gerente => 'Gerencia',
  };

  bool get isSupervisorOrAbove => level >= EmployeeRole.supervisor.level;
  bool get isManager => this == EmployeeRole.gerente;
}

enum EmployeeStatus { ativo, ferias, afastado, desligado }

class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;

  // Dados contratuais
  final String jobTitle; // título do cargo (texto livre)
  final String?
  jobRoleId; // ref para job_roles (opcional, para vincular ao catálogo)
  final String sector;
  final EmployeeRole role;
  final EmployeeStatus status;
  final DateTime admissionDate;
  final DateTime? dismissalDate;

  // Documentos
  final String cpf;
  final String ctps; // número da carteira de trabalho

  // Remuneração — salário pertence ao funcionário, não ao cargo
  final double baseSalary;
  // histórico de reajustes fica em subcoleção salary_history/{employeeId}

  // Educação
  final String educationLevel;
  final String courses;

  final DateTime createdAt;
  final DateTime updatedAt;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photoUrl = '',
    required this.jobTitle,
    this.jobRoleId,
    required this.sector,
    required this.role,
    this.status = EmployeeStatus.ativo,
    required this.admissionDate,
    this.dismissalDate,
    this.cpf = '',
    this.ctps = '',
    required this.baseSalary,
    required this.educationLevel,
    this.courses = '',
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Getters úteis ──────────────────────────────────────────────────────────
  bool get isActive => status == EmployeeStatus.ativo;
  bool get isDismissed => status == EmployeeStatus.desligado;
  bool get isOnLeave =>
      status == EmployeeStatus.ferias || status == EmployeeStatus.afastado;

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  // ── Serialização ──────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'jobTitle': jobTitle,
    'jobRoleId': jobRoleId,
    'sector': sector,
    'role': role.name,
    'status': status.name,
    'admissionDate': DbValue.toPrimitive(admissionDate),
    'dismissalDate':
        dismissalDate != null ? DbValue.toPrimitive(dismissalDate!) : null,
    'cpf': cpf,
    'ctps': ctps,
    'baseSalary': baseSalary,
    'educationLevel': educationLevel,
    'courses': courses,
    'createdAt': DbValue.toPrimitive(createdAt),
    'updatedAt': DbValue.toPrimitive(updatedAt),
  };

  factory EmployeeModel.fromMap(Map<String, dynamic> map, String docId) =>
      EmployeeModel(
        id: docId,
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        photoUrl: map['photoUrl'] ?? '',
        jobTitle: map['jobTitle'] ?? '',
        jobRoleId: map['jobRoleId'] as String?,
        sector: map['sector'] ?? 'Geral',
        role: EmployeeRole.values.firstWhere(
          (e) => e.name == map['role'],
          orElse: () => EmployeeRole.funcionario,
        ),
        status: EmployeeStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => EmployeeStatus.ativo,
        ),
        admissionDate:
            DbValue.toDateTime(map['admissionDate']) ?? DateTime.now(),
        dismissalDate: DbValue.toDateTime(map['dismissalDate']),
        cpf: map['cpf'] ?? '',
        ctps: map['ctps'] ?? '',
        // retrocompatibilidade: aceita 'salary' antigo ou novo 'baseSalary'
        baseSalary: _toDouble(map['baseSalary'] ?? map['salary']),
        educationLevel: map['educationLevel'] ?? '',
        courses: map['courses'] ?? '',
        createdAt: DbValue.toDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: DbValue.toDateTime(map['updatedAt']) ?? DateTime.now(),
      );

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  EmployeeModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? jobTitle,
    String? jobRoleId,
    String? sector,
    EmployeeRole? role,
    EmployeeStatus? status,
    DateTime? admissionDate,
    DateTime? dismissalDate,
    String? cpf,
    String? ctps,
    double? baseSalary,
    String? educationLevel,
    String? courses,
    DateTime? updatedAt,
  }) => EmployeeModel(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    photoUrl: photoUrl ?? this.photoUrl,
    jobTitle: jobTitle ?? this.jobTitle,
    jobRoleId: jobRoleId ?? this.jobRoleId,
    sector: sector ?? this.sector,
    role: role ?? this.role,
    status: status ?? this.status,
    admissionDate: admissionDate ?? this.admissionDate,
    dismissalDate: dismissalDate ?? this.dismissalDate,
    cpf: cpf ?? this.cpf,
    ctps: ctps ?? this.ctps,
    baseSalary: baseSalary ?? this.baseSalary,
    educationLevel: educationLevel ?? this.educationLevel,
    courses: courses ?? this.courses,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );
}
