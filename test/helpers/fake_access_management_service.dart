import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/access_management_service.dart';

class FakeAccessManagementService extends AccessManagementService {
  FakeAccessManagementService({List<UserModel>? users})
    : _users = List<UserModel>.from(users ?? const <UserModel>[]);

  final List<UserModel> _users;
  Object? getUsersError;
  UserModel? lastUpdatedUser;

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
}
