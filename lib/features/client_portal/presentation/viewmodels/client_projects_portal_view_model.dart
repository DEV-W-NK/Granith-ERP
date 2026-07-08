import 'package:flutter/foundation.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/models/client_account_model.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'package:project_granith/models/project_measurement_model.dart';
import 'package:project_granith/models/project_model.dart';
import 'package:project_granith/services/daily_log_service.dart';
import 'package:project_granith/services/project_measurement_service.dart';
import 'package:project_granith/services/service_projetos.dart';

class ClientProjectsPortalViewModel extends ChangeNotifier {
  ClientProjectsPortalViewModel({
    ServiceProjetos? projectService,
    DailyLogService? dailyLogService,
    ProjectMeasurementService? measurementService,
  }) : _projectService = projectService ?? ServiceProjetos(),
       _dailyLogService = dailyLogService ?? DailyLogService(),
       _measurementService = measurementService ?? ProjectMeasurementService();

  final ServiceProjetos _projectService;
  final DailyLogService _dailyLogService;
  final ProjectMeasurementService _measurementService;

  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedAccountId;
  String _lastLoadSignature = '';
  List<ClientAccount> _accounts = <ClientAccount>[];
  List<Project> _projects = <Project>[];
  Map<String, List<DailyLogModel>> _signedLogsByProjectId =
      <String, List<DailyLogModel>>{};
  Map<String, List<ProjectMeasurement>> _approvedMeasurementsByProjectId =
      <String, List<ProjectMeasurement>>{};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ClientAccount> get accounts => _accounts;
  List<Project> get projects => _projects;
  String? get selectedAccountId => _selectedAccountId;
  Map<String, List<DailyLogModel>> get signedLogsByProjectId =>
      _signedLogsByProjectId;
  Map<String, List<ProjectMeasurement>> get approvedMeasurementsByProjectId =>
      _approvedMeasurementsByProjectId;

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
  int get totalSignedDailyLogs => _signedLogsByProjectId.values.fold<int>(
    0,
    (total, logs) => total + logs.length,
  );
  int get totalApprovedMeasurements => _approvedMeasurementsByProjectId.values
      .fold<int>(0, (total, measurements) => total + measurements.length);

  double get approvedMeasurementsAmount =>
      _approvedMeasurementsByProjectId.values.fold<double>(
        0,
        (total, measurements) =>
            total +
            measurements.fold<double>(
              0,
              (sum, measurement) => sum + measurement.netAmount,
            ),
      );

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
      _signedLogsByProjectId = <String, List<DailyLogModel>>{};
      _approvedMeasurementsByProjectId = <String, List<ProjectMeasurement>>{};
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
      await _loadSignedDailyLogs();
      await _loadApprovedMeasurements();
    } catch (error) {
      _projects = <Project>[];
      _signedLogsByProjectId = <String, List<DailyLogModel>>{};
      _approvedMeasurementsByProjectId = <String, List<ProjectMeasurement>>{};
      _errorMessage = 'Nao foi possivel carregar os projetos do cliente.';
      debugPrint('[ClientProjectsPortalViewModel] $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<DailyLogModel> signedLogsForProject(String projectId) {
    return _signedLogsByProjectId[projectId] ?? const <DailyLogModel>[];
  }

  List<ProjectMeasurement> approvedMeasurementsForProject(String projectId) {
    return _approvedMeasurementsByProjectId[projectId] ??
        const <ProjectMeasurement>[];
  }

  Future<void> _loadSignedDailyLogs() async {
    try {
      final logs = await _dailyLogService.getSignedLogsForProjects(
        _projects.map((project) => project.id),
        limit: 200,
      );
      final grouped = <String, List<DailyLogModel>>{};
      for (final log in logs) {
        grouped.putIfAbsent(log.projectId, () => <DailyLogModel>[]).add(log);
      }
      _signedLogsByProjectId = grouped;
    } catch (error) {
      _signedLogsByProjectId = <String, List<DailyLogModel>>{};
      debugPrint(
        '[ClientProjectsPortalViewModel] Falha ao carregar diarios assinados: $error',
      );
    }
  }

  Future<void> _loadApprovedMeasurements() async {
    final projectIds = _projects.map((project) => project.id).toSet();
    if (projectIds.isEmpty) {
      _approvedMeasurementsByProjectId = <String, List<ProjectMeasurement>>{};
      return;
    }

    try {
      final measurements = await _measurementService.getMeasurements();
      final grouped = <String, List<ProjectMeasurement>>{};
      for (final measurement in measurements) {
        if (!projectIds.contains(measurement.projectId)) {
          continue;
        }
        if (measurement.status != ProjectMeasurementStatus.approved &&
            measurement.status != ProjectMeasurementStatus.paid) {
          continue;
        }
        grouped
            .putIfAbsent(measurement.projectId, () => <ProjectMeasurement>[])
            .add(measurement);
      }

      for (final projectMeasurements in grouped.values) {
        projectMeasurements.sort((left, right) {
          final dateCompare = right.measurementDate.compareTo(
            left.measurementDate,
          );
          if (dateCompare != 0) return dateCompare;
          return right.sequence.compareTo(left.sequence);
        });
      }
      _approvedMeasurementsByProjectId = grouped;
    } catch (error) {
      _approvedMeasurementsByProjectId = <String, List<ProjectMeasurement>>{};
      debugPrint(
        '[ClientProjectsPortalViewModel] Falha ao carregar medicoes aprovadas: $error',
      );
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
