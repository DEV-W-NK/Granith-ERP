import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/access_management_service.dart';

class FakeAccessManagementService extends AccessManagementService {
  FakeAccessManagementService({List<UserModel>? users})
    : _users = List<UserModel>.from(users ?? const <UserModel>[]);

  final List<UserModel> _users;
  Object? getUsersError;
  UserModel? lastUpdatedUser;
  UserModel? lastCreatedInternalUser;
  UserModel? lastPasswordResetUser;

  @override
  Future<List<UserModel>> getUsers() async {
    if (getUsersError != null) {
      throw getUsersError!;
    }
    return List<UserModel>.from(_users);
  }

  @override
  Future<void> updateUserAccess(UserModel user) async {
    lastUpdatedUser = user;
    final index = _users.indexWhere((item) => item.uid == user.uid);
    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
  }

  @override
  Future<UserModel> createInternalUser({
    required String username,
    required String password,
    required String displayName,
    required UserRole role,
    required List<String> permissions,
    String? employeeId,
    String? employeeName,
  }) async {
    final user = UserModel(
      uid: 'internal-$username',
      email: '$username@internal.granith.local',
      displayName: displayName,
      role: role,
      permissions: permissions,
      username: username,
      internalLoginEmail: '$username@internal.granith.local',
      authProvider: 'internal',
      employeeId: employeeId,
      employeeName: employeeName,
    );
    lastCreatedInternalUser = user;
    _users.add(user);
    return user;
  }

  @override
  Future<void> resetInternalUserPassword({
    required UserModel user,
    required String password,
  }) async {
    lastPasswordResetUser = user;
  }
}
