import 'dart:async';

import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/auth_service.dart';
import 'package:project_granith/services/auth_service_contract.dart';

class FakeAuthUser {
  final String id;
  final String? email;

  const FakeAuthUser(this.id, this.email);
}

class FakeAuthService implements AuthServiceContract {
  FakeAuthService({
    this.currentUserValue,
    this.profile,
    List<ClientAccount>? ownedAccounts,
  }) : _ownedAccounts = ownedAccounts ?? <ClientAccount>[];

  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();

  dynamic currentUserValue;
  UserModel? profile;
  final List<ClientAccount> _ownedAccounts;

  String? lastEmail;
  String? lastUsername;
  String? lastPassword;
  bool googleSignInCalled = false;
  bool magicLinkCalled = false;
  bool signOutCalled = false;

  AppAuthException? emailPasswordError;
  AppAuthException? googleError;
  AppAuthException? magicLinkError;
  AppAuthException? firstAccessError;

  @override
  dynamic get currentUser => currentUserValue;

  @override
  Stream<dynamic> get authStateChanges => _controller.stream;

  void emitAuthUser(dynamic authUser) {
    currentUserValue = authUser;
    _controller.add(authUser);
  }

  @override
  Future<void> ensureCurrentUserProfile() async {}

  @override
  Future<UserModel?> fetchUserData(String uid) async => profile;

  @override
  Future<List<ClientAccount>> getOwnedClientAccounts(String email) async =>
      List<ClientAccount>.from(_ownedAccounts);

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    if (emailPasswordError != null) {
      throw emailPasswordError!;
    }
  }

  @override
  Future<void> signInWithUsernamePassword({
    required String username,
    required String password,
  }) async {
    lastUsername = username;
    lastPassword = password;
    if (emailPasswordError != null) {
      throw emailPasswordError!;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    googleSignInCalled = true;
    if (googleError != null) {
      throw googleError!;
    }
  }

  @override
  Future<void> sendMagicLink({
    required String email,
    bool shouldCreateUser = false,
  }) async {
    magicLinkCalled = true;
    lastEmail = email;
    if (magicLinkError != null) {
      throw magicLinkError!;
    }
  }

  @override
  Future<void> completeClientFirstAccess({required String password}) async {
    lastPassword = password;
    if (firstAccessError != null) {
      throw firstAccessError!;
    }
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
