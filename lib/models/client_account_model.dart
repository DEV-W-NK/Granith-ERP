class ClientAccount {
  final String id;
  final String name;
  final String ownerEmail;
  final String contactEmail;
  final String contactPhone;
  final String status;
  final String notes;
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
    this.createdAt,
    this.updatedAt,
  });

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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'ownerEmail': ownerEmail.trim().toLowerCase(),
      'owner_email': ownerEmail.trim().toLowerCase(),
      'contactEmail': contactEmail.trim().toLowerCase(),
      'contact_email': contactEmail.trim().toLowerCase(),
      'contactPhone': contactPhone.trim(),
      'contact_phone': contactPhone.trim(),
      'status': status,
      'notes': notes.trim(),
    };
  }
}
