import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_granith/core/data/app_data_refresh_bus.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/core/supabase/supabase_selects.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef HomeListLoader =
    Future<List<Map<String, dynamic>>> Function(String table, {String columns});
typedef HomeProjectsLoader = Future<List<Map<String, dynamic>>> Function();
typedef HomeRecentActivitiesLoader =
    Future<List<Map<String, dynamic>>> Function();

class StatItem {
  final String label;
  final String value;
  final String delta;
  final bool deltaUp;
  final Color accent;
  final IconData icon;

  StatItem({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaUp,
    required this.accent,
    required this.icon,
  });
}

class ActivityItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final String time;
  final bool isPositive;

  ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.time,
    required this.isPositive,
  });
}

class HomeAlert {
  final String message;
  final String subtitle;
  final HomeAlertType type;

  const HomeAlert({
    required this.message,
    required this.subtitle,
    required this.type,
  });
}

enum HomeAlertType { critical, warning, info, hint }

class ProjectProgress {
  final String id;
  final String name;
  final String status;
  final double budget;
  final double currentCost;
  final DateTime? dueDate;

  const ProjectProgress({
    required this.id,
    required this.name,
    required this.status,
    required this.budget,
    required this.currentCost,
    required this.dueDate,
  });

  double get progressPct =>
      budget > 0 ? (currentCost / budget).clamp(0.0, 1.2) : 0.0;
  bool get isOverBudget => currentCost > budget && budget > 0;

  String get dueDateLabel {
    if (dueDate == null) return '';
    final diff = dueDate!.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Atrasado ${diff.abs()}d';
    if (diff == 0) return 'Entrega hoje';
    return 'Entrega: ${diff}d';
  }
}

class MonthlyMini {
  final String label;
  final double income;
  final double expense;

  const MonthlyMini({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    HomeListLoader? listLoader,
    HomeProjectsLoader? projectsLoader,
    HomeRecentActivitiesLoader? recentActivitiesLoader,
    DateTime Function()? nowProvider,
    AppDataRefreshBus? refreshBus,
    bool autoRefresh = true,
  }) : _listLoader = listLoader,
       _projectsLoader = projectsLoader,
       _recentActivitiesLoader = recentActivitiesLoader,
       _nowProvider = nowProvider ?? DateTime.now,
       _refreshBus = refreshBus ?? AppDataRefreshBus.instance {
    if (autoRefresh) {
      _refreshSubscription = _refreshBus.listen(const [
        AppDataRefreshBus.budgets,
        AppDataRefreshBus.dailyLogs,
        AppDataRefreshBus.employees,
        AppDataRefreshBus.employeeBenefits,
        AppDataRefreshBus.financialTransactions,
        AppDataRefreshBus.inventory,
        AppDataRefreshBus.inventoryMovements,
        AppDataRefreshBus.materialRequisitions,
        AppDataRefreshBus.projectMeasurements,
        AppDataRefreshBus.projects,
        AppDataRefreshBus.purchases,
        AppDataRefreshBus.teams,
      ], (_) => _scheduleDashboardRefresh());
    }
  }

  final HomeListLoader? _listLoader;
  final HomeProjectsLoader? _projectsLoader;
  final HomeRecentActivitiesLoader? _recentActivitiesLoader;
  final DateTime Function() _nowProvider;
  final AppDataRefreshBus _refreshBus;
  StreamSubscription<AppDataRefreshEvent>? _refreshSubscription;
  Timer? _refreshDebounce;
  bool _isDisposed = false;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _activeProjects = 0;
  int _activeEmployees = 0;
  int _fieldToday = 0;
  int _pendingDailyLogs = 0;
  int _talentsPending = 0;
  int _openRequisitions = 0;
  String _latestHireName = '';
  DateTime? _latestHireDate;
  String _latestClosedProjectName = '';
  DateTime? _latestClosedProjectDate;
  String _latestSignedDailyLogProject = '';
  DateTime? _latestSignedDailyLogDate;
  int _signedDailyLogs = 0;

  int get activeEmployees => _activeEmployees;
  int get fieldToday => _fieldToday;

  List<ProjectProgress> _projects = [];
  List<ProjectProgress> get projects => _projects;

  List<HomeAlert> _alerts = [];
  List<HomeAlert> get alerts => _alerts;

  List<MonthlyMini> get monthlyMini => const <MonthlyMini>[];

  List<StatItem> _stats = [];
  List<StatItem> get stats => _stats;

  List<ActivityItem> _recentActivities = [];
  List<ActivityItem> get recentActivities => _recentActivities;

  Future<void> loadDashboardData() {
    return _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool showLoader = true}) async {
    if (!showLoader && _isLoading) return;
    if (showLoader) {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    final failures = <String>[];

    await Future.wait([
      _runSection('projetos', _loadProjects, failures),
      _runSection('rh', _loadHr, failures),
      _runSection('requisicoes', _loadRequisitions, failures),
      _runSection('talentos', _loadTalents, failures),
      _runSection('atividades', _loadRecentActivities, failures),
    ]);

    _buildAlerts();
    _buildStats();
    if (_recentActivities.isEmpty) {
      _buildMilestoneRecentActivities();
    }
    if (_recentActivities.isEmpty) {
      _buildFallbackRecentActivities();
    }

    if (failures.isNotEmpty) {
      _error =
          'Alguns blocos do dashboard nao puderam ser carregados: ${failures.join(', ')}';
      debugPrint('[HomeViewModel] $_error');
    }

    if (showLoader) {
      _isLoading = false;
    }
    notifyListeners();
  }

  void _scheduleDashboardRefresh() {
    if (_isDisposed) return;
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_isDisposed) return;
      unawaited(_loadDashboardData(showLoader: false));
    });
  }

  Future<void> _runSection(
    String label,
    Future<void> Function() action,
    List<String> failures,
  ) async {
    try {
      await action();
    } catch (e) {
      failures.add(label);
      debugPrint('[HomeViewModel] Falha em $label: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _selectList(
    String table, {
    String columns = '*',
  }) async {
    if (_listLoader != null) {
      return _listLoader(table, columns: columns);
    }

    final response = await AppSupabase.client.from(table).select(columns);
    return (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  bool _isAuthOrMissingTableError(Object error) {
    if (error is PostgrestException) {
      return error.code == 'PGRST301' || error.code == '42P01';
    }
    final message = error.toString();
    return message.contains('PGRST301') ||
        message.contains('42P01') ||
        message.contains('relation') ||
        message.contains('does not exist');
  }

  void _buildStats() {
    _stats = [
      StatItem(
        label: 'ULTIMO CONTRATADO',
        value: _latestHireName.isNotEmpty ? _latestHireName : 'Equipe estavel',
        delta:
            _latestHireDate == null
                ? 'Sem admissoes recentes'
                : 'Entrou ${_relativeLabel(_latestHireDate).toLowerCase()}',
        deltaUp: true,
        accent: AppColors.accentGreen,
        icon: Icons.person_add_alt_1_rounded,
      ),
      StatItem(
        label: 'ULTIMA OBRA FECHADA',
        value:
            _latestClosedProjectName.isNotEmpty
                ? _latestClosedProjectName
                : 'Em andamento',
        delta:
            _latestClosedProjectDate == null
                ? 'Proximas entregas em execucao'
                : 'Concluida ${_relativeLabel(_latestClosedProjectDate).toLowerCase()}',
        deltaUp: true,
        accent: AppColors.accentGold,
        icon: Icons.task_alt_rounded,
      ),
      StatItem(
        label: 'EQUIPE EM CAMPO HOJE',
        value:
            _fieldToday > 0
                ? '$_fieldToday pessoa${_fieldToday == 1 ? '' : 's'}'
                : 'Aguardando diario',
        delta:
            _pendingDailyLogs > 0
                ? '$_pendingDailyLogs diario${_pendingDailyLogs == 1 ? '' : 's'} para completar'
                : 'Diarios do dia em ordem',
        deltaUp: true,
        accent: AppColors.accentBlue,
        icon: Icons.engineering_rounded,
      ),
      StatItem(
        label: 'RELATORIOS LIBERADOS',
        value:
            _signedDailyLogs > 0
                ? '$_signedDailyLogs assinado${_signedDailyLogs == 1 ? '' : 's'}'
                : 'Nenhum ainda',
        delta:
            _latestSignedDailyLogDate == null
                ? 'Aguardando assinaturas'
                : 'Ultimo ${_relativeLabel(_latestSignedDailyLogDate).toLowerCase()}',
        deltaUp: true,
        accent: AppColors.auraCyan,
        icon: Icons.verified_rounded,
      ),
    ];
  }

  void _buildFallbackRecentActivities() {
    _recentActivities = [
      ActivityItem(
        icon: Icons.auto_awesome_rounded,
        iconColor: AppColors.accentGold,
        title: 'Dia pronto para bons avancos',
        subtitle: 'Sem marcos recentes carregados agora',
        value: '',
        time: 'Agora',
        isPositive: true,
      ),
    ];
  }

  void _buildMilestoneRecentActivities() {
    final items = <ActivityItem>[];

    if (_latestHireName.isNotEmpty) {
      items.add(
        ActivityItem(
          icon: Icons.person_add_alt_1_rounded,
          iconColor: AppColors.accentGreen,
          title: 'Novo colaborador no time',
          subtitle: _latestHireName,
          value: _relativeLabel(_latestHireDate),
          time: _relativeLabel(_latestHireDate),
          isPositive: true,
        ),
      );
    }

    if (_latestClosedProjectName.isNotEmpty) {
      items.add(
        ActivityItem(
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.accentGold,
          title: 'Obra fechada com sucesso',
          subtitle: _latestClosedProjectName,
          value: _relativeLabel(_latestClosedProjectDate),
          time: _relativeLabel(_latestClosedProjectDate),
          isPositive: true,
        ),
      );
    }

    if (_latestSignedDailyLogProject.isNotEmpty) {
      items.add(
        ActivityItem(
          icon: Icons.verified_rounded,
          iconColor: AppColors.auraCyan,
          title: 'Relatorio liberado ao cliente',
          subtitle: _latestSignedDailyLogProject,
          value: _relativeLabel(_latestSignedDailyLogDate),
          time: _relativeLabel(_latestSignedDailyLogDate),
          isPositive: true,
        ),
      );
    }

    if (_openRequisitions > 0) {
      items.add(
        ActivityItem(
          icon: Icons.inventory_2_rounded,
          iconColor: AppColors.accentBlue,
          title: 'Suprimentos em movimento',
          subtitle:
              '$_openRequisitions requisic${_openRequisitions == 1 ? 'ao' : 'oes'} em andamento',
          value: 'Compras',
          time: 'Agora',
          isPositive: true,
        ),
      );
    }

    _recentActivities = items.take(4).toList();
  }

  Future<void> _loadProjects() async {
    final rows =
        _projectsLoader != null
            ? await _projectsLoader()
            : ((await AppSupabase.client
                        .from('projects')
                        .select(SupabaseSelects.projectDashboard)
                        .inFilter('status', [
                          'inProgress',
                          'planning',
                          'completed',
                        ])
                        .order('endDate', ascending: false)
                        .limit(10))
                    as List)
                .map((row) => Map<String, dynamic>.from(row as Map))
                .toList();

    final activeRows =
        rows.where((row) {
          final status = row['status']?.toString();
          return status == 'inProgress' || status == 'planning';
        }).toList();
    final completedRows =
        rows.where((row) => row['status']?.toString() == 'completed').toList()
          ..sort((a, b) {
            final aDate =
                DbValue.toDateTime(a['endDate']) ??
                DbValue.toDateTime(a['startDate']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                DbValue.toDateTime(b['endDate']) ??
                DbValue.toDateTime(b['startDate']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

    _activeProjects = activeRows.length;
    if (completedRows.isNotEmpty) {
      final latest = completedRows.first;
      _latestClosedProjectName = (latest['name'] ?? '').toString();
      _latestClosedProjectDate =
          DbValue.toDateTime(latest['endDate']) ??
          DbValue.toDateTime(latest['startDate']);
    } else {
      _latestClosedProjectName = '';
      _latestClosedProjectDate = null;
    }

    _projects =
        activeRows
            .map(
              (d) => ProjectProgress(
                id: (d['id'] ?? '').toString(),
                name: (d['name'] ?? 'Sem nome').toString(),
                status: (d['status'] ?? '').toString(),
                budget: (d['budget'] as num?)?.toDouble() ?? 0,
                currentCost: (d['currentCost'] as num?)?.toDouble() ?? 0,
                dueDate: DbValue.toDateTime(d['endDate']),
              ),
            )
            .toList();
  }

  Future<void> _loadHr() async {
    final now = _nowProvider();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(hours: 23, minutes: 59));

    final employeeRows = await _selectList(
      'employees',
      columns: 'id,name,status,admissionDate,createdAt',
    );
    final activeEmployees =
        employeeRows.where((row) {
            final status = row['status']?.toString().toLowerCase();
            return status == 'active' || status == 'ativo';
          }).toList()
          ..sort((a, b) {
            final aDate =
                DbValue.toDateTime(a['admissionDate']) ??
                DbValue.toDateTime(a['createdAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                DbValue.toDateTime(b['admissionDate']) ??
                DbValue.toDateTime(b['createdAt']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
    _activeEmployees = activeEmployees.length;
    if (activeEmployees.isNotEmpty) {
      final latest = activeEmployees.first;
      _latestHireName = (latest['name'] ?? '').toString().trim();
      _latestHireDate =
          DbValue.toDateTime(latest['admissionDate']) ??
          DbValue.toDateTime(latest['createdAt']);
    } else {
      _latestHireName = '';
      _latestHireDate = null;
    }

    final logRows = await _selectList(
      'daily_logs',
      columns: 'id,date,manpower,status,signedAt,projectName',
    );
    final todayLogs =
        logRows.where((row) {
          final date = DbValue.toDateTime(row['date']);
          return date != null &&
              !date.isBefore(todayStart) &&
              !date.isAfter(todayEnd);
        }).toList();

    _pendingDailyLogs = (_activeProjects - todayLogs.length).clamp(0, 99);
    final signedLogs =
        logRows.where((row) {
            final status = row['status']?.toString();
            final signedAt = DbValue.toDateTime(row['signedAt']);
            return status == 'signed' || signedAt != null;
          }).toList()
          ..sort((a, b) {
            final aDate =
                DbValue.toDateTime(a['signedAt']) ??
                DbValue.toDateTime(a['date']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                DbValue.toDateTime(b['signedAt']) ??
                DbValue.toDateTime(b['date']) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

    _signedDailyLogs = signedLogs.length;
    if (signedLogs.isNotEmpty) {
      final latest = signedLogs.first;
      _latestSignedDailyLogProject =
          (latest['projectName'] ?? 'Diario de obra').toString();
      _latestSignedDailyLogDate =
          DbValue.toDateTime(latest['signedAt']) ??
          DbValue.toDateTime(latest['date']);
    } else {
      _latestSignedDailyLogProject = '';
      _latestSignedDailyLogDate = null;
    }

    _fieldToday = todayLogs.fold(0, (sum, row) {
      final manpower = row['manpower'];
      if (manpower is! Map) {
        return sum;
      }

      final mp = Map<String, dynamic>.from(manpower);
      final rowCount = mp.values.fold<int>(0, (subtotal, value) {
        if (value is int) return subtotal + value;
        if (value is num) return subtotal + value.toInt();
        return subtotal;
      });

      return sum + rowCount;
    });
  }

  Future<void> _loadRequisitions() async {
    final rows = await _selectList(
      'material_requisitions',
      columns: 'id,status',
    );
    _openRequisitions =
        rows
            .where(
              (row) =>
                  row['status'] == 'pending' || row['status'] == 'approved',
            )
            .length;
  }

  Future<void> _loadTalents() async {
    try {
      final rows = await _selectList('talent_candidates', columns: 'id,status');
      _talentsPending =
          rows.where((row) => row['status']?.toString() == 'pending').length;
    } catch (e) {
      if (_isAuthOrMissingTableError(e)) {
        _talentsPending = 0;
        return;
      }
      rethrow;
    }
  }

  Future<void> _loadRecentActivities() async {
    if (_recentActivitiesLoader == null) {
      _recentActivities = [];
      return;
    }

    try {
      final rows = await _recentActivitiesLoader();

      _recentActivities =
          rows
              .map((row) => Map<String, dynamic>.from(row as Map))
              .map(_mapRecentActivity)
              .toList();
    } catch (e) {
      if (_isAuthOrMissingTableError(e)) {
        _recentActivities = [];
        return;
      }
      rethrow;
    }
  }

  ActivityItem _mapRecentActivity(Map<String, dynamic> row) {
    final type = row['type']?.toString() ?? 'milestone';
    final status = row['status']?.toString() ?? '';
    final date =
        DbValue.toDateTime(row['paymentDate']) ??
        DbValue.toDateTime(row['dueDate']) ??
        DbValue.toDateTime(row['createdAt']);
    final isPositive = type != 'issue';

    return ActivityItem(
      icon:
          type == 'employee'
              ? Icons.person_add_alt_1_rounded
              : type == 'project'
              ? Icons.task_alt_rounded
              : type == 'daily_log'
              ? Icons.verified_rounded
              : Icons.auto_awesome_rounded,
      iconColor: isPositive ? AppColors.accentGreen : AppColors.accentRed,
      title: (row['description'] ?? 'Marco registrado').toString(),
      subtitle:
          (row['subtitle'] ?? row['projectName'] ?? 'Atualizacao do time')
              .toString(),
      value: status.isEmpty ? _relativeLabel(date) : status,
      time: _relativeLabel(date),
      isPositive: isPositive,
    );
  }

  void _buildAlerts() {
    _alerts = [];

    if (_latestClosedProjectName.isNotEmpty) {
      _alerts.add(
        HomeAlert(
          message: 'Ultima obra fechada: $_latestClosedProjectName',
          subtitle: 'Comercial / Operacional',
          type: HomeAlertType.hint,
        ),
      );
    }

    if (_openRequisitions > 0) {
      _alerts.add(
        HomeAlert(
          message:
              '$_openRequisitions requisic${_openRequisitions > 1 ? 'oes' : 'ao'} aguardando aprovacao',
          subtitle: 'Compras',
          type: HomeAlertType.warning,
        ),
      );
    }

    if (_pendingDailyLogs > 0) {
      _alerts.add(
        HomeAlert(
          message:
              '$_pendingDailyLogs diario${_pendingDailyLogs > 1 ? 's' : ''} de obra sem lancamento hoje',
          subtitle: 'Obras',
          type: HomeAlertType.warning,
        ),
      );
    }

    if (_signedDailyLogs > 0) {
      _alerts.add(
        HomeAlert(
          message:
              '$_signedDailyLogs relatorio${_signedDailyLogs > 1 ? 's' : ''} liberado${_signedDailyLogs > 1 ? 's' : ''} ao cliente',
          subtitle: 'Diario de Obras',
          type: HomeAlertType.info,
        ),
      );
    }

    if (_talentsPending > 0) {
      _alerts.add(
        HomeAlert(
          message:
              '$_talentsPending curriculo${_talentsPending > 1 ? 's' : ''} aguardando triagem',
          subtitle: 'RH / Talentos',
          type: HomeAlertType.info,
        ),
      );
    }
  }

  static String _relativeLabel(DateTime? date) {
    if (date == null) return 'Sem data';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays <= 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return '${diff.inDays}d atras';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshDebounce?.cancel();
    _refreshSubscription?.cancel();
    super.dispose();
  }
}
