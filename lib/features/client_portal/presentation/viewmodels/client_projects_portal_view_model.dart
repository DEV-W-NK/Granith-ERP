import 'package:flutter/foundation.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/service_projetos.dart';

class ClientProjectsPortalViewModel extends ChangeNotifier {
  ClientProjectsPortalViewModel({ServiceProjetos? projectService})
    : _projectService = projectService ?? ServiceProjetos();

  final ServiceProjetos _projectService;

  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedAccountId;
  String _lastLoadSignature = '';
  List<ClientAccount> _accounts = <ClientAccount>[];
  List<Project> _projects = <Project>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ClientAccount> get accounts => _accounts;
  List<Project> get projects => _projects;
  String? get selectedAccountId => _selectedAccountId;

  ClientAccount? get activeAccount {
    if (_accounts.isEmpty) {
      return null;
    }

    return _accounts.firstWhere(
      (account) => account.id == _selectedAccountId,
      orElse: () => _accounts.first,
    );
  }

  int get totalProjects => _projects.length;
  int get inProgressProjects =>
      _projects.where((project) => project.isInProgress).length;
  int get completedProjects =>
      _projects.where((project) => project.isCompleted).length;

  double get averageProgress {
    if (_projects.isEmpty) {
      return 0;
    }

    final total = _projects.fold<double>(
      0,
      (sum, project) => sum + project.progressPercentage,
    );
    return total / _projects.length;
  }

  Future<void> load(AuthViewModel auth, {bool force = false}) async {
    final ownedAccounts = auth.ownedClientAccounts;
    final nextSelectedAccountId =
        _selectedAccountId ??
        (ownedAccounts.isNotEmpty ? ownedAccounts.first.id : null);
    final signature =
        '${auth.user?.email ?? ''}|${ownedAccounts.map((item) => item.id).join(',')}|$nextSelectedAccountId';

    if (!force && signature == _lastLoadSignature && !_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _accounts = ownedAccounts;
    _selectedAccountId = nextSelectedAccountId;
    _lastLoadSignature = signature;
    notifyListeners();

    if (_selectedAccountId == null) {
      _projects = <Project>[];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final results = await _projectService.getProjectsByClientAccount(
        _selectedAccountId!,
      );
      _projects = List<Project>.from(results)..sort((left, right) {
        final statusWeight = _statusOrder(
          left.status,
        ).compareTo(_statusOrder(right.status));
        if (statusWeight != 0) {
          return statusWeight;
        }
        return right.startDate.compareTo(left.startDate);
      });
    } catch (error) {
      _projects = <Project>[];
      _errorMessage = 'Nao foi possivel carregar os projetos do cliente.';
      debugPrint('[ClientProjectsPortalViewModel] $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectAccount(String accountId, AuthViewModel auth) async {
    if (accountId == _selectedAccountId) {
      return;
    }

    _selectedAccountId = accountId;
    await load(auth, force: true);
  }

  int _statusOrder(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress:
        return 0;
      case ProjectStatus.planning:
        return 1;
      case ProjectStatus.completed:
        return 2;
    }
  }
}
