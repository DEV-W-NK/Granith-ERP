enum ClientPortalAccessStatus {
  pending,
  invited,
  active;

  String get value {
    switch (this) {
      case ClientPortalAccessStatus.pending:
        return 'pending';
      case ClientPortalAccessStatus.invited:
        return 'invited';
      case ClientPortalAccessStatus.active:
        return 'active';
    }
  }

  String get label {
    switch (this) {
      case ClientPortalAccessStatus.pending:
        return 'Sem acesso criado';
      case ClientPortalAccessStatus.invited:
        return 'Convite enviado';
      case ClientPortalAccessStatus.active:
        return 'Acesso ativo';
    }
  }

  static ClientPortalAccessStatus fromValue(String? value) {
    switch (value) {
      case 'invited':
        return ClientPortalAccessStatus.invited;
      case 'active':
        return ClientPortalAccessStatus.active;
      case 'pending':
      default:
        return ClientPortalAccessStatus.pending;
    }
  }
}

class ClientAccount {
  final String id;
  final String name;
  final String ownerEmail;
  final String contactEmail;
  final String contactPhone;
  final String status;
  final String notes;
  final ClientPortalAccessStatus portalAccessStatus;
  final String? portalAuthUserId;
  final DateTime? portalInvitedAt;
  final DateTime? portalLastAccessAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClientAccount({
    required this.id,
    required this.name,
    required this.ownerEmail,
    required this.contactEmail,
    required this.contactPhone,
    this.status = 'ativo',
    this.notes = '',
    this.portalAccessStatus = ClientPortalAccessStatus.pending,
    this.portalAuthUserId,
    this.portalInvitedAt,
    this.portalLastAccessAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasPortalAccess =>
      portalAccessStatus != ClientPortalAccessStatus.pending;

  factory ClientAccount.empty() {
    return const ClientAccount(
      id: '',
      name: '',
      ownerEmail: '',
      contactEmail: '',
      contactPhone: '',
    );
  }

  factory ClientAccount.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return ClientAccount(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      ownerEmail: (map['ownerEmail'] ?? map['owner_email'] ?? '').toString(),
      contactEmail:
          (map['contactEmail'] ?? map['contact_email'] ?? '').toString(),
      contactPhone:
          (map['contactPhone'] ?? map['contact_phone'] ?? '').toString(),
      status: (map['status'] ?? 'ativo').toString(),
      notes: (map['notes'] ?? '').toString(),
      portalAccessStatus: ClientPortalAccessStatus.fromValue(
        map['portalAccessStatus']?.toString() ??
            map['portal_access_status']?.toString(),
      ),
      portalAuthUserId:
          map['portalAuthUserId']?.toString() ??
          map['portal_auth_user_id']?.toString(),
      portalInvitedAt: parseDate(
        map['portalInvitedAt'] ?? map['portal_invited_at'],
      ),
      portalLastAccessAt: parseDate(
        map['portalLastAccessAt'] ?? map['portal_last_access_at'],
      ),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  ClientAccount copyWith({
    String? id,
    String? name,
    String? ownerEmail,
    String? contactEmail,
    String? contactPhone,
    String? status,
    String? notes,
    ClientPortalAccessStatus? portalAccessStatus,
    String? portalAuthUserId,
    DateTime? portalInvitedAt,
    DateTime? portalLastAccessAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      portalAccessStatus: portalAccessStatus ?? this.portalAccessStatus,
      portalAuthUserId: portalAuthUserId ?? this.portalAuthUserId,
      portalInvitedAt: portalInvitedAt ?? this.portalInvitedAt,
      portalLastAccessAt: portalLastAccessAt ?? this.portalLastAccessAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    final normalizedOwnerEmail = ownerEmail.trim().toLowerCase();
    final normalizedContactEmail = contactEmail.trim().toLowerCase();

    final map = <String, dynamic>{
      'name': name.trim(),
      'ownerEmail': normalizedOwnerEmail,
      'owner_email': normalizedOwnerEmail,
      'contactEmail': normalizedContactEmail,
      'contact_email': normalizedContactEmail,
      'contactPhone': contactPhone.trim(),
      'contact_phone': contactPhone.trim(),
      'status': status,
      'notes': notes.trim(),
      'portalAccessStatus': portalAccessStatus.value,
      'portal_access_status': portalAccessStatus.value,
      'portalAuthUserId': portalAuthUserId,
      'portal_auth_user_id': portalAuthUserId,
      'portalInvitedAt': portalInvitedAt,
      'portal_invited_at': portalInvitedAt,
      'portalLastAccessAt': portalLastAccessAt,
      'portal_last_access_at': portalLastAccessAt,
    };

    if (id.trim().isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }
}
