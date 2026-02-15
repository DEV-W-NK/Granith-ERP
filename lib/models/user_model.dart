import 'package:cloud_firestore/cloud_firestore.dart';

/// TIPO: Model
/// CAMADA: Domain / Data
/// FUNÇÃO: Representa o usuário no ecossistema Granith.
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String status;
  final List<String> permissions;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.status = 'ativo',
    this.permissions = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      status: map['status'] ?? 'ativo',
      permissions: List<String>.from(map['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'status': status,
      'permissions': permissions,
    };
  }
}