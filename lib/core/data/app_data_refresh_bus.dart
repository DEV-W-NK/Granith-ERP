import 'dart:async';

class AppDataRefreshEvent {
  const AppDataRefreshEvent({
    required this.scopes,
    required this.source,
    required this.occurredAt,
  });

  final Set<String> scopes;
  final String source;
  final DateTime occurredAt;

  bool matches(Iterable<String> watchedScopes) {
    if (scopes.contains(AppDataRefreshBus.all)) return true;
    return watchedScopes.any(scopes.contains);
  }
}

class AppDataRefreshBus {
  AppDataRefreshBus._();

  static final AppDataRefreshBus instance = AppDataRefreshBus._();

  static const all = 'all';
  static const access = 'access';
  static const benefits = 'benefits';
  static const benefitCategories = 'benefit_categories';
  static const budgets = 'budgets';
  static const budgetTypes = 'budget_types';
  static const clientAccounts = 'client_accounts';
  static const dailyLogs = 'daily_logs';
  static const employees = 'employees';
  static const employeeBenefits = 'employee_benefits';
  static const financialTransactions = 'financial_transactions';
  static const geofences = 'geofences';
  static const inventory = 'inventory';
  static const inventoryMovements = 'inventory_movements';
  static const items = 'items';
  static const jobRoles = 'job_roles';
  static const materialRequisitions = 'material_requisitions';
  static const projectMeasurements = 'project_measurements';
  static const projects = 'projects';
  static const purchases = 'purchases';
  static const purchaseDeliveryRoutes = 'purchase_delivery_routes';
  static const purchaseDeliveryRouteStops = 'purchase_delivery_route_stops';
  static const requisitionQuotes = 'requisition_quotes';
  static const settings = 'settings';
  static const sectors = 'sectors';
  static const salaryHistory = 'salary_history';
  static const suppliers = 'suppliers';
  static const teams = 'teams';
  static const vehicles = 'vehicles';
  static const vehicleFuelLogs = 'vehicle_fuel_logs';

  final StreamController<AppDataRefreshEvent> _controller =
      StreamController<AppDataRefreshEvent>.broadcast();

  Stream<AppDataRefreshEvent> get stream => _controller.stream;

  void notify({required Iterable<String> scopes, String source = ''}) {
    final normalizedScopes = scopes
        .map((scope) => scope.trim())
        .where((scope) => scope.isNotEmpty);
    final scopeSet = Set<String>.unmodifiable(normalizedScopes);
    if (scopeSet.isEmpty || _controller.isClosed) return;

    _controller.add(
      AppDataRefreshEvent(
        scopes: scopeSet,
        source: source.trim(),
        occurredAt: DateTime.now(),
      ),
    );
  }

  StreamSubscription<AppDataRefreshEvent> listen(
    Iterable<String> scopes,
    FutureOr<void> Function(AppDataRefreshEvent event) onRefresh,
  ) {
    final watchedScopes = Set<String>.unmodifiable(
      scopes.map((scope) => scope.trim()).where((scope) => scope.isNotEmpty),
    );

    return stream.where((event) => event.matches(watchedScopes)).listen((
      event,
    ) {
      final result = onRefresh(event);
      if (result is Future<void>) {
        unawaited(result);
      }
    });
  }
}
