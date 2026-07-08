import 'dart:async';

import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/core/supabase/supabase_selects.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/auth_service.dart';
import 'package:project_granith/services/mobile_push_dispatch_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InternalUserProvisionException implements Exception {
  final String message;

  const InternalUserProvisionException(this.message);

  @override
  String toString() => message;
}

class EmployeeAccessBinding {
  final String id;
  final String name;
  final String email;
  final String status;

  const EmployeeAccessBinding({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });

  String get displayLabel {
    final emailSuffix = email.trim().isEmpty ? '' : ' - $email';
    return '$name$emailSuffix';
  }
}

class AccessManagementService {
  static const String _table = 'users';

  Future<List<UserModel>> getUsers() async {
    final response = await AppSupabase.client
        .from(_table)
        .select(SupabaseSelects.userProfile)
        .order('displayName', ascending: true);

    return (response as List).map((row) {
      final data = Map<String, dynamic>.from(row);
      return UserModel.fromMap(data, (data['id'] ?? '').toString());
    }).toList();
  }

  Future<void> updateUserAccess(UserModel user) async {
    final payload = DbValue.normalizeMap({
      ...user.toMap(),
      'id': user.uid,
      'updated_at': DateTime.now().toUtc(),
    });

    await AppSupabase.client.from(_table).upsert(payload);
    _notifyAccessChanged();
    unawaited(MobilePushDispatchService.dispatchPending(limit: 50));
  }

  Future<UserModel> createInternalUser({
    required String username,
    required String password,
    required String displayName,
    required UserRole role,
    required List<String> permissions,
    String? employeeId,
    String? employeeName,
  }) async {
    final normalizedUsername = normalizeInternalUsername(username);
    final validationError = validateInternalUsername(normalizedUsername);
    if (validationError != null) {
      throw InternalUserProvisionException(validationError);
    }
    if (password.trim().length < 8) {
      throw const InternalUserProvisionException(
        'A senha precisa ter pelo menos 8 caracteres.',
      );
    }

    final data = await _invokeInternalUserFunction({
      'action': 'create',
      'username': normalizedUsername,
      'password': password,
      'displayName':
          displayName.trim().isEmpty ? normalizedUsername : displayName.trim(),
      'role': role.value,
      'permissions': permissions,
      'employeeId': employeeId?.trim(),
      'employeeName': employeeName?.trim(),
    });

    final createdUser = _userFromFunctionData(data);
    _notifyAccessChanged();
    unawaited(MobilePushDispatchService.dispatchPending(limit: 50));
    return createdUser;
  }

  Future<List<EmployeeAccessBinding>> getActiveEmployeeBindings() async {
    final response = await AppSupabase.client
        .from('employees')
        .select('id,name,email,status')
        .neq('status', 'desligado')
        .order('name');

    return (response as List)
        .map((row) {
          final map = Map<String, dynamic>.from(row as Map);
          return EmployeeAccessBinding(
            id: (map['id'] ?? '').toString(),
            name: (map['name'] ?? '').toString(),
            email: (map['email'] ?? '').toString(),
            status: (map['status'] ?? '').toString(),
          );
        })
        .where((employee) {
          return employee.id.trim().isNotEmpty &&
              employee.name.trim().isNotEmpty;
        })
        .toList();
  }

  Future<void> resetInternalUserPassword({
    required UserModel user,
    required String password,
  }) async {
    if (!user.isInternalCredential) {
      throw const InternalUserProvisionException(
        'Apenas usuarios internos podem ter senha redefinida aqui.',
      );
    }
    if (password.trim().length < 8) {
      throw const InternalUserProvisionException(
        'A senha precisa ter pelo menos 8 caracteres.',
      );
    }

    await _invokeInternalUserFunction({
      'action': 'reset_password',
      'userId': user.uid,
      'password': password,
    });
    _notifyAccessChanged();
    unawaited(MobilePushDispatchService.dispatchPending(limit: 50));
  }

  Future<Map<String, dynamic>> _invokeInternalUserFunction(
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await AppSupabase.client.functions.invoke(
        'manage_internal_user',
        body: body,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const InternalUserProvisionException(
        'Resposta inesperada ao gerenciar usuario interno.',
      );
    } on FunctionException catch (error) {
      final details = error.details;
      if (details is Map && details['message'] != null) {
        throw InternalUserProvisionException(details['message'].toString());
      }
      throw InternalUserProvisionException(
        error.reasonPhrase ?? 'Nao foi possivel gerenciar o usuario interno.',
      );
    }
  }

  UserModel _userFromFunctionData(Map<String, dynamic> data) {
    final userData = data['user'];
    if (userData is Map) {
      final map = Map<String, dynamic>.from(userData);
      return UserModel.fromMap(map, (map['id'] ?? '').toString());
    }

    throw const InternalUserProvisionException(
      'Resposta sem dados do usuario interno criado.',
    );
  }

  void _notifyAccessChanged() {
    AppDataRefreshBus.instance.notify(
      scopes: const [AppDataRefreshBus.access],
      source: 'AccessManagementService',
    );
  }
}
