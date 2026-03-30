import 'package:cloud_firestore/cloud_firestore.dart';

enum EmployeeRole   { funcionario, supervisor, coordenador }
enum EmployeeStatus { ativo, ferias, afastado, desligado }

class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;

  // Dados contratuais
  final String jobTitle;       // título do cargo (texto livre)
  final String? jobRoleId;     // ref para job_roles (opcional, para vincular ao catálogo)
  final String sector;
  final EmployeeRole role;
  final EmployeeStatus status;
  final DateTime admissionDate;
  final DateTime? dismissalDate;

  // Documentos
  final String cpf;
  final String ctps;           // número da carteira de trabalho

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
  bool get isActive    => status == EmployeeStatus.ativo;
  bool get isDismissed => status == EmployeeStatus.desligado;
  bool get isOnLeave   => status == EmployeeStatus.ferias || status == EmployeeStatus.afastado;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ── Serialização ──────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'name':           name,
        'email':          email,
        'phone':          phone,
        'photoUrl':       photoUrl,
        'jobTitle':       jobTitle,
        'jobRoleId':      jobRoleId,
        'sector':         sector,
        'role':           role.name,
        'status':         status.name,
        'admissionDate':  Timestamp.fromDate(admissionDate),
        'dismissalDate':  dismissalDate != null ? Timestamp.fromDate(dismissalDate!) : null,
        'cpf':            cpf,
        'ctps':           ctps,
        'baseSalary':     baseSalary,
        'educationLevel': educationLevel,
        'courses':        courses,
        'createdAt':      Timestamp.fromDate(createdAt),
        'updatedAt':      Timestamp.fromDate(updatedAt),
      };

  factory EmployeeModel.fromMap(Map<String, dynamic> map, String docId) =>
      EmployeeModel(
        id:             docId,
        name:           map['name'] ?? '',
        email:          map['email'] ?? '',
        phone:          map['phone'] ?? '',
        photoUrl:       map['photoUrl'] ?? '',
        jobTitle:       map['jobTitle'] ?? '',
        jobRoleId:      map['jobRoleId'] as String?,
        sector:         map['sector'] ?? 'Geral',
        role:           EmployeeRole.values.firstWhere(
          (e) => e.name == map['role'],
          orElse: () => EmployeeRole.funcionario,
        ),
        status:         EmployeeStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => EmployeeStatus.ativo,
        ),
        admissionDate:  (map['admissionDate'] as Timestamp).toDate(),
        dismissalDate:  (map['dismissalDate'] as Timestamp?)?.toDate(),
        cpf:            map['cpf'] ?? '',
        ctps:           map['ctps'] ?? '',
        // retrocompatibilidade: aceita 'salary' antigo ou novo 'baseSalary'
        baseSalary:     (map['baseSalary'] ?? map['salary'] ?? 0.0).toDouble(),
        educationLevel: map['educationLevel'] ?? '',
        courses:        map['courses'] ?? '',
        createdAt:      (map['createdAt'] as Timestamp).toDate(),
        updatedAt:      (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

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
  }) =>
      EmployeeModel(
        id:             id,
        name:           name ?? this.name,
        email:          email ?? this.email,
        phone:          phone ?? this.phone,
        photoUrl:       photoUrl ?? this.photoUrl,
        jobTitle:       jobTitle ?? this.jobTitle,
        jobRoleId:      jobRoleId ?? this.jobRoleId,
        sector:         sector ?? this.sector,
        role:           role ?? this.role,
        status:         status ?? this.status,
        admissionDate:  admissionDate ?? this.admissionDate,
        dismissalDate:  dismissalDate ?? this.dismissalDate,
        cpf:            cpf ?? this.cpf,
        ctps:           ctps ?? this.ctps,
        baseSalary:     baseSalary ?? this.baseSalary,
        educationLevel: educationLevel ?? this.educationLevel,
        courses:        courses ?? this.courses,
        createdAt:      createdAt,
        updatedAt:      updatedAt ?? DateTime.now(),
      );
}