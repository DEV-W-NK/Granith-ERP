import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/user_model.dart';

abstract class AuthServiceContract {
  dynamic get currentUser;
  Stream<dynamic> get authStateChanges;

  Future<UserModel?> fetchUserData(String uid);
  Future<void> signInWithGoogle();
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<void> sendMagicLink({
    required String email,
    bool shouldCreateUser = false,
  });
  Future<void> ensureCurrentUserProfile();
  Future<void> completeClientFirstAccess({
    required String password,
  });
  Future<List<ClientAccount>> getOwnedClientAccounts(String email);
  Future<void> signOut();
}
