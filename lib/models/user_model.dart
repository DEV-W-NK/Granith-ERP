enum UserRole {
  admin,
  employee,
  client;

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.employee:
        return 'employee';
      case UserRole.client:
        return 'client';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.employee:
        return 'Funcionario';
      case UserRole.client:
        return 'Cliente';
    }
  }

  static UserRole fromValue(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'client':
        return UserRole.client;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }
}

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String status;
  final List<String> permissions;
  final UserRole role;
  final String? clientAccountId;
  final String? clientAccountName;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.status = 'ativo',
    this.permissions = const [],
    this.role = UserRole.employee,
    this.clientAccountId,
    this.clientAccountName,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isEmployee => role == UserRole.employee || role == UserRole.admin;
  bool get isClient => role == UserRole.client;

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: (map['email'] ?? '').toString(),
      displayName:
          map['displayName']?.toString() ?? map['display_name']?.toString(),
      photoUrl: map['photoUrl']?.toString() ?? map['photo_url']?.toString(),
      status: (map['status'] ?? 'ativo').toString(),
      permissions: List<String>.from(map['permissions'] ?? const <String>[]),
      role: UserRole.fromValue(map['role']?.toString()),
      clientAccountId:
          map['clientAccountId']?.toString() ??
          map['client_account_id']?.toString(),
      clientAccountName:
          map['clientAccountName']?.toString() ??
          map['client_account_name']?.toString(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? status,
    List<String>? permissions,
    UserRole? role,
    String? clientAccountId,
    String? clientAccountName,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      role: role ?? this.role,
      clientAccountId: clientAccountId ?? this.clientAccountId,
      clientAccountName: clientAccountName ?? this.clientAccountName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'status': status,
      'permissions': permissions,
      'role': role.value,
      'clientAccountId': clientAccountId,
      'client_account_id': clientAccountId,
      'clientAccountName': clientAccountName,
      'client_account_name': clientAccountName,
    };
  }
}
