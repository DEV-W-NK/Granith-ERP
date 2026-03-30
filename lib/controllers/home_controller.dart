import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/models/statistics_model.dart';
import 'package:project_granith/services/financial_service.dart';
import 'package:project_granith/themes/app_theme.dart';

// =============================================================================
// HOME CONTROLLER
// Agrega dados de múltiplos serviços para o dashboard da HomePage.
// Dados reais do Firestore — sem mocks.
//
// PROVIDERS NECESSÁRIOS em main.dart:
//   ChangeNotifierProvider(create: (_) => HomeController()..loadDashboardData()),
// =============================================================================

// Modelo de alerta para o painel de notificações da home
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

// Snapshot de projeto para as barras de progresso
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
    this.dueDate,
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

// Dados mensais para o mini chart (receita vs despesa)
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

// =============================================================================

class HomeController extends ChangeNotifier {
  final FirebaseFirestore _db;
  final FinancialService _financialService;

  HomeController({
    FirebaseFirestore? firestore,
    FinancialService? financialService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _financialService =
            financialService ?? FinancialService(firestore: firestore);

  // ── Estado ───────────────────────────────────────────────────────────────────
  bool _loading = true;
  bool get isLoading => _loading;

  String? _error;
  String? get error => _error;

  // ── KPIs topo ───────────────────────────────────────────────────────────────
  int    _activeProjects     = 0;
  double _overdueAmount      = 0;
  int    _overdueCount       = 0;
  double _currentMonthMargin = 0;
  int    _activeEmployees    = 0;
  int    _fieldToday         = 0;
  int    _pendingDailyLogs   = 0;
  int    _talentsPending     = 0;
  int    _openRequisitions   = 0;

  int    get activeProjects     => _activeProjects;
  double get overdueAmount      => _overdueAmount;
  int    get overdueCount       => _overdueCount;
  double get currentMonthMargin => _currentMonthMargin;
  int    get activeEmployees    => _activeEmployees;
  int    get fieldToday         => _fieldToday;
  int    get pendingDailyLogs   => _pendingDailyLogs;
  int    get talentsPending     => _talentsPending;
  int    get openRequisitions   => _openRequisitions;

  // ── Projetos ─────────────────────────────────────────────────────────────────
  List<ProjectProgress> _projects = [];
  List<ProjectProgress> get projects => _projects;

  // ── Alertas ─────────────────────────────────────────────────────────────────
  List<HomeAlert> _alerts = [];
  List<HomeAlert> get alerts => _alerts;
  int get alertCount => _alerts.where(
    (a) => a.type == HomeAlertType.critical || a.type == HomeAlertType.warning,
  ).length;

  // ── Mini chart ───────────────────────────────────────────────────────────────
  List<MonthlyMini> _monthlyMini = [];
  List<MonthlyMini> get monthlyMini => _monthlyMini;

  // ── Load ─────────────────────────────────────────────────────────────────────
  Future<void> loadDashboardData() async {
    _loading = true;
    _error   = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadProjects(),
        _loadFinancial(),
        _loadHr(),
        _loadRequisitions(),
        _loadTalents(),
        _loadMonthlyMini(),
      ]);

      _buildAlerts();
    } catch (e) {
      _error = 'Erro ao carregar dashboard: $e';
      debugPrint('[HomeController] $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Projetos ─────────────────────────────────────────────────────────────────
  Future<void> _loadProjects() async {
    final snap = await _db
        .collection('projects')
        .where('status', whereIn: ['inProgress', 'planning'])
        .orderBy('currentCost', descending: true)
        .limit(6)
        .get();

    _activeProjects = snap.size;

    _projects = snap.docs.map((doc) {
      final d = doc.data();
      return ProjectProgress(
        id:          doc.id,
        name:        d['name'] ?? 'Sem nome',
        status:      d['status'] ?? '',
        budget:      (d['budget'] as num?)?.toDouble() ?? 0,
        currentCost: (d['currentCost'] as num?)?.toDouble() ?? 0,
        dueDate:     (d['endDate'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  // ── Financeiro ───────────────────────────────────────────────────────────────
  Future<void> _loadFinancial() async {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Vencidos hoje ou antes, ainda pendentes
    final overdueSnap = await _db
        .collection('financial_transactions')
        .where('type',   isEqualTo: 'expense')
        .where('status', isEqualTo: 'pending')
        .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(today))
        .get();

    _overdueCount  = overdueSnap.size;
    _overdueAmount = overdueSnap.docs.fold(0.0, (sum, doc) {
      return sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0);
    });

    // Margem do mês atual
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd   = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final monthSnap = await _db
        .collection('financial_transactions')
        .where('status', isEqualTo: 'paid')
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('dueDate', isLessThanOrEqualTo:    Timestamp.fromDate(monthEnd))
        .get();

    double income = 0, expense = 0;
    for (final doc in monthSnap.docs) {
      final d = doc.data();
      final amount = (d['amount'] as num?)?.toDouble() ?? 0;
      if (d['type'] == 'income')  income  += amount;
      if (d['type'] == 'expense') expense += amount;
    }

    _currentMonthMargin = income > 0
        ? ((income - expense) / income * 100)
        : 0;
  }

  // ── RH ───────────────────────────────────────────────────────────────────────
  Future<void> _loadHr() async {
    final now       = DateTime.now();
    final todayStr  = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    // Funcionários ativos
    final empSnap = await _db
        .collection('employees')
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    _activeEmployees = empSnap.count ?? 0;

    // Diários de obra lançados hoje
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd   = todayStart.add(const Duration(hours: 23, minutes: 59));

    final logsSnap = await _db
        .collection('daily_logs')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('date', isLessThanOrEqualTo:    Timestamp.fromDate(todayEnd))
        .get();

    // Projetos que deveriam ter diário hoje mas não têm
    _pendingDailyLogs = (_activeProjects - logsSnap.size).clamp(0, 99);

    // Campo hoje — soma de manpower dos diários do dia
    _fieldToday = logsSnap.docs.fold(0, (sum, doc) {
      final mp = doc.data()['manpower'] as Map<String, dynamic>? ?? {};
      return sum + mp.values.fold(0, (s, v) => s + (v as int? ?? 0));
    });
  }

  // ── Requisições ───────────────────────────────────────────────────────────────
  Future<void> _loadRequisitions() async {
    final snap = await _db
        .collection('material_requisitions')
        .where('status', whereIn: ['pending', 'approved'])
        .count()
        .get();
    _openRequisitions = snap.count ?? 0;
  }

  // ── Talentos ─────────────────────────────────────────────────────────────────
  Future<void> _loadTalents() async {
    final snap = await _db
        .collection('talent_candidates')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    _talentsPending = snap.count ?? 0;
  }

  // ── Mini chart (últimos 6 meses) ─────────────────────────────────────────────
  Future<void> _loadMonthlyMini() async {
    final now    = DateTime.now();
    final from   = DateTime(now.year, now.month - 5, 1);
    final to     = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final snap = await _db
        .collection('financial_transactions')
        .where('status', isEqualTo: 'paid')
        .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('dueDate', isLessThanOrEqualTo:    Timestamp.fromDate(to))
        .get();

    final map = <String, ({double income, double expense})>{};

    for (final doc in snap.docs) {
      final d      = doc.data();
      final date   = (d['dueDate'] as Timestamp).toDate();
      final key    = '${date.year}-${date.month.toString().padLeft(2,'0')}';
      final amount = (d['amount'] as num?)?.toDouble() ?? 0;
      final cur    = map[key] ?? (income: 0.0, expense: 0.0);

      if (d['type'] == 'income') {
        map[key] = (income: cur.income + amount, expense: cur.expense);
      } else {
        map[key] = (income: cur.income, expense: cur.expense + amount);
      }
    }

    _monthlyMini = List.generate(6, (i) {
      final month = DateTime(now.year, now.month - 5 + i, 1);
      final key   = '${month.year}-${month.month.toString().padLeft(2,'0')}';
      final entry = map[key] ?? (income: 0.0, expense: 0.0);
      return MonthlyMini(
        label:   _monthName(month.month),
        income:  entry.income,
        expense: entry.expense,
      );
    });
  }

  // ── Getter para o StatsGrid ──────────────────────────────────────────────────
  List<StatItem> get mainStats {
    return [
      StatItem(
        title: 'Obras Ativas',
        value: '$_activeProjects',
        subtitle: '$_pendingDailyLogs diários pendentes',
        icon: Icons.construction,
        color: AppColors.accentGold,
        // Lógica simples de tendência (pode customizar como quiser)
        trend: _activeProjects > 0 ? TrendType.up : TrendType.neutral,
        trendValue: '+2', // Exemplo estático, você pode calcular a diferença real depois
      ),
      StatItem(
        title: 'Funcionários',
        value: '$_activeEmployees',
        subtitle: '$_fieldToday em campo hoje',
        icon: Icons.engineering,
        color: AppColors.accentBlue,
        trend: TrendType.neutral,
        trendValue: '0',
      ),
      StatItem(
        title: 'Financeiro (Mês)',
        // Usando o seu helper para formatar a margem ou despesas
        value: '${_currentMonthMargin.toStringAsFixed(1)}%', 
        subtitle: 'Margem atual',
        icon: Icons.attach_money,
        // Se a margem for menor que 28% (sua meta), mostra tendência ruim
        color: _currentMonthMargin >= 28 ? AppColors.accentGreen : AppColors.accentRed,
        trend: _currentMonthMargin >= 28 ? TrendType.up : TrendType.down,
        trendValue: '${(_currentMonthMargin - 28).toStringAsFixed(1)}%',
      ),
      StatItem(
        title: 'Requisições',
        value: '$_openRequisitions',
        subtitle: 'Aguardando aprovação',
        icon: Icons.inventory_2,
        color: _openRequisitions > 0 ? AppColors.accentRed : AppColors.accentGreen,
        trend: _openRequisitions > 0 ? TrendType.down : TrendType.neutral,
        trendValue: '$_openRequisitions',
      ),
    ];
  }

  // ── Alertas automáticos ───────────────────────────────────────────────────────
  void _buildAlerts() {
    _alerts = [];

    // Projetos estourados
    for (final p in _projects.where((p) => p.isOverBudget)) {
      final excesso = p.currentCost - p.budget;
      _alerts.add(HomeAlert(
        message:  '${p.name} estourou orçamento em ${_compact(excesso)}',
        subtitle: 'Financeiro · Projetos',
        type:     HomeAlertType.critical,
      ));
    }

    // Faturas vencidas
    if (_overdueCount > 0) {
      _alerts.add(HomeAlert(
        message:  '$_overdueCount fatura${_overdueCount > 1 ? 's' : ''} vencida${_overdueCount > 1 ? 's' : ''} (${_compact(_overdueAmount)})',
        subtitle: 'Financeiro',
        type:     HomeAlertType.critical,
      ));
    }

    // Requisições abertas
    if (_openRequisitions > 0) {
      _alerts.add(HomeAlert(
        message:  '$_openRequisitions requisiç${_openRequisitions > 1 ? 'ões' : 'ão'} aguardando aprovação',
        subtitle: 'Compras',
        type:     HomeAlertType.warning,
      ));
    }

    // Diários pendentes
    if (_pendingDailyLogs > 0) {
      _alerts.add(HomeAlert(
        message:  '$_pendingDailyLogs diário${_pendingDailyLogs > 1 ? 's' : ''} de obra sem lançamento hoje',
        subtitle: 'Obras',
        type:     HomeAlertType.warning,
      ));
    }

    // Talentos sem triagem
    if (_talentsPending > 0) {
      _alerts.add(HomeAlert(
        message:  '$_talentsPending currículo${_talentsPending > 1 ? 's' : ''} aguardando triagem',
        subtitle: 'RH · Talentos',
        type:     HomeAlertType.info,
      ));
    }

    // Margem abaixo da meta
    if (_currentMonthMargin > 0 && _currentMonthMargin < 28) {
      _alerts.add(HomeAlert(
        message:  'Margem do mês ${_currentMonthMargin.toStringAsFixed(1)}% — abaixo da meta de 28%',
        subtitle: 'Financeiro',
        type:     HomeAlertType.warning,
      ));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static String _compact(double v) {
    if (v.abs() >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000)    return 'R\$ ${(v / 1000).toStringAsFixed(0)}k';
    return 'R\$ ${v.toStringAsFixed(0)}';
  }

  static String _monthName(int m) {
    const n = ['','Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return n[m];
  }

  /// Placeholder para futura integração com Gemini
  Future<String?> askAiInsight(String prompt) async {
    // TODO: integrar com GeminiService quando implementado
    return null;
  }
}