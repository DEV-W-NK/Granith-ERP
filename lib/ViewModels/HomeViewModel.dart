import 'package:flutter/material.dart';
import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
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
  }) : _listLoader = listLoader,
       _projectsLoader = projectsLoader,
       _recentActivitiesLoader = recentActivitiesLoader,
       _nowProvider = nowProvider ?? DateTime.now;

  final HomeListLoader? _listLoader;
  final HomeProjectsLoader? _projectsLoader;
  final HomeRecentActivitiesLoader? _recentActivitiesLoader;
  final DateTime Function() _nowProvider;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _activeProjects = 0;
  double _overdueAmount = 0;
  int _overdueCount = 0;
  double _currentMonthMargin = 0;
  int _activeEmployees = 0;
  int _fieldToday = 0;
  int _pendingDailyLogs = 0;
  int _talentsPending = 0;
  int _openRequisitions = 0;

  int get activeEmployees => _activeEmployees;
  int get fieldToday => _fieldToday;

  List<ProjectProgress> _projects = [];
  List<ProjectProgress> get projects => _projects;

  List<HomeAlert> _alerts = [];
  List<HomeAlert> get alerts => _alerts;

  List<MonthlyMini> _monthlyMini = [];
  List<MonthlyMini> get monthlyMini => _monthlyMini;

  List<StatItem> _stats = [];
  List<StatItem> get stats => _stats;

  List<ActivityItem> _recentActivities = [];
  List<ActivityItem> get recentActivities => _recentActivities;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final failures = <String>[];

    await Future.wait([
      _runSection('projetos', _loadProjects, failures),
      _runSection('financeiro', _loadFinancial, failures),
      _runSection('rh', _loadHr, failures),
      _runSection('requisicoes', _loadRequisitions, failures),
      _runSection('talentos', _loadTalents, failures),
      _runSection('grafico_mensal', _loadMonthlyMini, failures),
      _runSection('atividades', _loadRecentActivities, failures),
    ]);

    _buildAlerts();
    _buildStats();
    if (_recentActivities.isEmpty) {
      _buildFallbackRecentActivities();
    }

    if (failures.isNotEmpty) {
      _error =
          'Alguns blocos do dashboard nao puderam ser carregados: ${failures.join(', ')}';
      debugPrint('[HomeViewModel] $_error');
    }

    _isLoading = false;
    notifyListeners();
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
    final monthExpense = _overdueAmount > 0 ? _overdueAmount : 61200.0;
    final monthIncome =
        _monthlyMini.isNotEmpty
            ? _monthlyMini.last.income
            : (_overdueAmount > 0 ? _overdueAmount * 4 : 84500.0);
    final balance = monthIncome - monthExpense;

    _stats = [
      StatItem(
        label: 'RECEITA DO MES',
        value: 'R\$ ${monthIncome.toStringAsFixed(0)}',
        delta: '+${_currentMonthMargin.toStringAsFixed(1)}%',
        deltaUp: _currentMonthMargin >= 0,
        accent: AppColors.green,
        icon: Icons.trending_up_rounded,
      ),
      StatItem(
        label: 'DESPESAS DO MES',
        value: 'R\$ ${monthExpense.toStringAsFixed(0)}',
        delta: _overdueCount > 0 ? '+$_overdueCount venc.' : '+4.1%',
        deltaUp: false,
        accent: AppColors.red,
        icon: Icons.trending_down_rounded,
      ),
      StatItem(
        label: 'SALDO ATUAL',
        value: 'R\$ ${balance.toStringAsFixed(0)}',
        delta: '${_currentMonthMargin.toStringAsFixed(1)}%',
        deltaUp: _currentMonthMargin >= 0,
        accent: AppColors.gold,
        icon: Icons.account_balance_wallet_rounded,
      ),
      StatItem(
        label: 'CLIENTES ATIVOS',
        value: _activeProjects.toString(),
        delta: '+${_openRequisitions.toString()}',
        deltaUp: true,
        accent: AppColors.blue,
        icon: Icons.people_outline_rounded,
      ),
    ];
  }

  void _buildFallbackRecentActivities() {
    _recentActivities = [
      ActivityItem(
        icon: Icons.arrow_downward_rounded,
        iconColor: AppColors.green,
        title: 'Pagamento recebido',
        subtitle: 'Sem movimentacoes recentes carregadas',
        value: '',
        time: 'Agora',
        isPositive: true,
      ),
    ];
  }

  Future<void> _loadProjects() async {
    final rows =
        _projectsLoader != null
            ? await _projectsLoader()
            : ((await AppSupabase.client
                        .from('projects')
                        .select()
                        .inFilter('status', ['inProgress', 'planning'])
                        .order('currentCost', ascending: false)
                        .limit(6))
                    as List)
                .map((row) => Map<String, dynamic>.from(row as Map))
                .toList();

    _activeProjects = rows.length;

    _projects =
        rows
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

  Future<void> _loadFinancial() async {
    final now = _nowProvider();
    final today = DateTime(now.year, now.month, now.day);

    final overdueRows = await _selectList('financial_transactions');

    final overdue =
        overdueRows.where((row) {
          final type = row['type']?.toString();
          final status = row['status']?.toString();
          final dueDate = DbValue.toDateTime(row['dueDate']);

          return type == 'expense' &&
              status == 'pending' &&
              dueDate != null &&
              !dueDate.isAfter(today);
        }).toList();

    _overdueCount = overdue.length;
    _overdueAmount = overdue.fold(
      0.0,
      (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
    );

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    double income = 0;
    double expense = 0;

    for (final row in overdueRows) {
      final status = row['status']?.toString();
      final dueDate = DbValue.toDateTime(row['dueDate']);
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;

      if (status != 'paid' || dueDate == null) {
        continue;
      }

      if (dueDate.isBefore(monthStart) || dueDate.isAfter(monthEnd)) {
        continue;
      }

      if (row['type'] == 'income') {
        income += amount;
      } else if (row['type'] == 'expense') {
        expense += amount;
      }
    }

    _currentMonthMargin = income > 0 ? ((income - expense) / income * 100) : 0;
  }

  Future<void> _loadHr() async {
    final now = _nowProvider();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(hours: 23, minutes: 59));

    final employeeRows = await _selectList('employees');
    _activeEmployees =
        employeeRows.where((row) {
          final status = row['status']?.toString().toLowerCase();
          return status == 'active' || status == 'ativo';
        }).length;

    final logRows = await _selectList('daily_logs');
    final todayLogs =
        logRows.where((row) {
          final date = DbValue.toDateTime(row['date']);
          return date != null &&
              !date.isBefore(todayStart) &&
              !date.isAfter(todayEnd);
        }).toList();

    _pendingDailyLogs = (_activeProjects - todayLogs.length).clamp(0, 99);

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
    final rows = await _selectList('material_requisitions');
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
      final rows = await _selectList('talent_candidates');
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

  Future<void> _loadMonthlyMini() async {
    final now = _nowProvider();
    final from = DateTime(now.year, now.month - 5, 1);
    final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final rows = await _selectList('financial_transactions');
    final grouped = <String, ({double income, double expense})>{};

    for (final row in rows) {
      if (row['status']?.toString() != 'paid') {
        continue;
      }

      final dueDate = DbValue.toDateTime(row['dueDate']);
      if (dueDate == null || dueDate.isBefore(from) || dueDate.isAfter(to)) {
        continue;
      }

      final key = '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}';
      final amount = (row['amount'] as num?)?.toDouble() ?? 0;
      final current = grouped[key] ?? (income: 0.0, expense: 0.0);

      if (row['type'] == 'income') {
        grouped[key] = (
          income: current.income + amount,
          expense: current.expense,
        );
      } else {
        grouped[key] = (
          income: current.income,
          expense: current.expense + amount,
        );
      }
    }

    _monthlyMini = List.generate(6, (i) {
      final month = DateTime(now.year, now.month - 5 + i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final entry = grouped[key] ?? (income: 0.0, expense: 0.0);

      return MonthlyMini(
        label: _monthName(month.month),
        income: entry.income,
        expense: entry.expense,
      );
    });
  }

  Future<void> _loadRecentActivities() async {
    try {
      final rows =
          _recentActivitiesLoader != null
              ? await _recentActivitiesLoader()
              : ((await AppSupabase.client
                          .from('financial_transactions')
                          .select()
                          .order('createdAt', ascending: false)
                          .limit(4))
                      as List)
                  .map((row) => Map<String, dynamic>.from(row as Map))
                  .toList();

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
    final type = row['type']?.toString() ?? 'expense';
    final status = row['status']?.toString() ?? '';
    final amount = (row['amount'] as num?)?.toDouble() ?? 0;
    final date =
        DbValue.toDateTime(row['paymentDate']) ??
        DbValue.toDateTime(row['dueDate']) ??
        DbValue.toDateTime(row['createdAt']);
    final isPositive = type == 'income';

    return ActivityItem(
      icon:
          isPositive
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
      iconColor: isPositive ? AppColors.green : AppColors.red,
      title: (row['description'] ?? 'Movimentacao financeira').toString(),
      subtitle: '${isPositive ? '+' : '-'} ${_compact(amount)}',
      value: status,
      time: _relativeLabel(date),
      isPositive: isPositive,
    );
  }

  void _buildAlerts() {
    _alerts = [];

    for (final p in _projects.where((p) => p.isOverBudget)) {
      final excesso = p.currentCost - p.budget;
      _alerts.add(
        HomeAlert(
          message: '${p.name} estourou orcamento em ${_compact(excesso)}',
          subtitle: 'Financeiro · Projetos',
          type: HomeAlertType.critical,
        ),
      );
    }

    if (_overdueCount > 0) {
      _alerts.add(
        HomeAlert(
          message:
              '$_overdueCount fatura${_overdueCount > 1 ? 's' : ''} vencida${_overdueCount > 1 ? 's' : ''} (${_compact(_overdueAmount)})',
          subtitle: 'Financeiro',
          type: HomeAlertType.critical,
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

    if (_talentsPending > 0) {
      _alerts.add(
        HomeAlert(
          message:
              '$_talentsPending curriculo${_talentsPending > 1 ? 's' : ''} aguardando triagem',
          subtitle: 'RH · Talentos',
          type: HomeAlertType.info,
        ),
      );
    }

    if (_currentMonthMargin > 0 && _currentMonthMargin < 28) {
      _alerts.add(
        HomeAlert(
          message:
              'Margem do mes ${_currentMonthMargin.toStringAsFixed(1)}% abaixo da meta de 28%',
          subtitle: 'Financeiro',
          type: HomeAlertType.warning,
        ),
      );
    }
  }

  static String _compact(double v) {
    if (v.abs() >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(0)}k';
    return 'R\$ ${v.toStringAsFixed(0)}';
  }

  static String _monthName(int m) {
    const n = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return n[m];
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
}
