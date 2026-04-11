import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _service = AuthService();
  StreamSubscription? _subscription;

  UserModel? _currentUserModel;
  List<ClientAccount> _ownedClientAccounts = [];
  bool _isInitialized = false;

  UserModel? get user => _currentUserModel;
  bool get isInitialized => _isInitialized;
  List<ClientAccount> get ownedClientAccounts => _ownedClientAccounts;

  AuthViewModel() {
    _listenToAuthChanges();
  }

  bool get isAuthenticated => _currentUserModel != null;
  bool get isClientUser => _currentUserModel?.isClient ?? false;
  bool get isEmployeeUser => _currentUserModel?.isEmployee ?? false;
  bool get isAdminUser => _currentUserModel?.isAdmin ?? false;

  bool hasPermission(String permission) {
    return _currentUserModel?.permissions.contains(permission) ?? false;
  }

  void _listenToAuthChanges() {
    _subscription?.cancel();
    _subscription = _service.authStateChanges.listen((authUser) async {
      if (authUser != null) {
        await _service.ensureCurrentUserProfile();
        final profile = await _service.fetchUserData(authUser.id);
        final linkedAccounts =
            await _service.getOwnedClientAccounts(authUser.email ?? '');

        _ownedClientAccounts = linkedAccounts;
        _currentUserModel = _resolveUserProfile(profile, authUser.email, linkedAccounts);
      } else {
        _currentUserModel = null;
        _ownedClientAccounts = [];
      }

      _isInitialized = true;
      notifyListeners();
    });
  }

  UserModel _resolveUserProfile(
    UserModel? profile,
    String? email,
    List<ClientAccount> linkedAccounts,
  ) {
    if (profile != null) {
      if (profile.role == UserRole.employee || profile.role == UserRole.admin) {
        return profile;
      }

      if (profile.role == UserRole.client) {
        final primaryAccount = linkedAccounts.isNotEmpty ? linkedAccounts.first : null;
        return profile.copyWith(
          clientAccountId: profile.clientAccountId ?? primaryAccount?.id,
          clientAccountName:
              profile.clientAccountName ?? primaryAccount?.name,
        );
      }
    }

    if (linkedAccounts.isNotEmpty) {
      final primaryAccount = linkedAccounts.first;
      return UserModel(
        uid: profile?.uid ?? '',
        email: profile?.email ?? email ?? '',
        displayName: profile?.displayName ?? primaryAccount.name,
        photoUrl: profile?.photoUrl,
        status: profile?.status ?? 'ativo',
        permissions: profile?.permissions ?? const [],
        role: UserRole.client,
        clientAccountId: primaryAccount.id,
        clientAccountName: primaryAccount.name,
      );
    }

    return profile ??
        UserModel(
          uid: '',
          email: email ?? '',
          role: UserRole.employee,
        );
  }

  Future<void> logout() async {
    await _service.signOut();
    _currentUserModel = null;
    _ownedClientAccounts = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
