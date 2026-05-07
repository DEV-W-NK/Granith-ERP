import 'package:project_granith/core/data/db_value.dart';
import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/BenefitCategoryModel.dart';
import 'package:project_granith/models/BenefitModel.dart';
import 'package:project_granith/models/EmployeeBenefitModel.dart';
import 'package:project_granith/models/SalaryHistoryModel.dart';
import 'package:project_granith/models/employee_model.dart';

class HrService {
  static const _employeesTable = 'employees';
  static const _benefitCategoriesTable = 'benefit_categories';
  static const _benefitsTable = 'benefits';
  static const _salaryHistoryTable = 'salary_history';
  static const _employeeBenefitsTable = 'employee_benefits';
  static const _teamsTable = 'teams';

  HrService();

  Stream<List<EmployeeModel>> watchEmployees() {
    return AppSupabase.client
        .from(_employeesTable)
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(_employeeFromRow).toList());
  }

  Future<EmployeeModel?> getEmployee(String id) async {
    final row =
        await AppSupabase.client
            .from(_employeesTable)
            .select()
            .eq('id', id)
            .maybeSingle();

    if (row == null) return null;
    return _employeeFromRow(Map<String, dynamic>.from(row));
  }

  Future<String> addEmployee(EmployeeModel employee) async {
    final row =
        await AppSupabase.client
            .from(_employeesTable)
            .insert(DbValue.normalizeMap(employee.toMap()))
            .select('id')
            .single();

    return row['id'] as String;
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    await AppSupabase.client
        .from(_employeesTable)
        .update(
          DbValue.normalizeMap(
            employee.copyWith(updatedAt: DateTime.now()).toMap(),
          ),
        )
        .eq('id', employee.id);
  }

  Future<void> dismissEmployee(String employeeId, {String? updatedBy}) async {
    final now = DateTime.now();
    final nowValue = DbValue.toPrimitive(now);

    await AppSupabase.client
        .from(_employeesTable)
        .update({
          'status': EmployeeStatus.desligado.name,
          'dismissalDate': nowValue,
          'updatedAt': nowValue,
        })
        .eq('id', employeeId);

    final teams = await AppSupabase.client
        .from(_teamsTable)
        .select('id, memberIds, leaderId')
        .contains('memberIds', [employeeId]);

    for (final row in teams as List) {
      final data = Map<String, dynamic>.from(row as Map);
      final memberIds = List<String>.from(data['memberIds'] ?? const []);
      memberIds.remove(employeeId);

      await AppSupabase.client
          .from(_teamsTable)
          .update({
            'memberIds': memberIds,
            if (data['leaderId'] == employeeId) 'leaderId': null,
          })
          .eq('id', data['id'] as String);
    }

    final benefits = await AppSupabase.client
        .from(_employeeBenefitsTable)
        .select('id')
        .eq('employeeId', employeeId)
        .eq('isActive', true);

    for (final row in benefits as List) {
      final id = (row as Map)['id'] as String;
      await AppSupabase.client
          .from(_employeeBenefitsTable)
          .update({'isActive': false, 'endDate': nowValue})
          .eq('id', id);
    }
  }

  Stream<List<SalaryHistoryModel>> watchSalaryHistory(String employeeId) {
    return AppSupabase.client
        .from(_salaryHistoryTable)
        .stream(primaryKey: ['id'])
        .order('effectiveDate', ascending: false)
        .map((rows) => rows.map(_salaryHistoryFromRow).toList())
        .map(
          (rows) =>
              rows
                  .where((history) => history.employeeId == employeeId)
                  .toList(),
        );
  }

  Future<void> applyRaise({
    required String employeeId,
    required double currentSalary,
    required double newSalary,
    required String reason,
    required String updatedBy,
    DateTime? effectiveDate,
  }) async {
    final now = DateTime.now();
    final history = SalaryHistoryModel(
      id: '',
      employeeId: employeeId,
      previousSalary: currentSalary,
      newSalary: newSalary,
      effectiveDate: effectiveDate ?? now,
      reason: reason,
      updatedBy: updatedBy,
      createdAt: now,
    );

    await AppSupabase.client
        .from(_salaryHistoryTable)
        .insert(DbValue.normalizeMap(history.toMap()));

    await AppSupabase.client
        .from(_employeesTable)
        .update({
          'baseSalary': newSalary,
          'updatedAt': DbValue.toPrimitive(now),
        })
        .eq('id', employeeId);
  }

  Stream<List<BenefitModel>> watchBenefits({bool onlyActive = false}) {
    return AppSupabase.client
        .from(_benefitsTable)
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => (rows as List).map(_benefitFromRow).toList())
        .map(
          (rows) =>
              onlyActive
                  ? rows.where((benefit) => benefit.isActive).toList()
                  : rows,
        );
  }

  Stream<List<BenefitCategoryModel>> watchBenefitCategories({
    bool onlyActive = false,
  }) {
    return AppSupabase.client
        .from(_benefitCategoriesTable)
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(_benefitCategoryFromRow).toList())
        .map(
          (rows) =>
              onlyActive
                  ? rows.where((category) => category.isActive).toList()
                  : rows,
        );
  }

  Future<String> addBenefitCategory(BenefitCategoryModel category) async {
    final row =
        await AppSupabase.client
            .from(_benefitCategoriesTable)
            .insert(DbValue.normalizeMap(category.toMap()))
            .select('id')
            .single();

    return row['id'] as String;
  }

  Future<void> updateBenefitCategory(BenefitCategoryModel category) async {
    await AppSupabase.client
        .from(_benefitCategoriesTable)
        .update(
          DbValue.normalizeMap(
            category.copyWith(updatedAt: DateTime.now()).toMap(),
          ),
        )
        .eq('id', category.id);
  }

  Future<void> toggleBenefitCategory(String id, bool isActive) async {
    await AppSupabase.client
        .from(_benefitCategoriesTable)
        .update({
          'isActive': isActive,
          'updatedAt': DbValue.toPrimitive(DateTime.now()),
        })
        .eq('id', id);
  }

  Future<String> addBenefit(BenefitModel benefit) async {
    final row =
        await AppSupabase.client
            .from(_benefitsTable)
            .insert(DbValue.normalizeMap(benefit.toMap()))
            .select('id')
            .single();

    return row['id'] as String;
  }

  Future<void> updateBenefit(BenefitModel benefit) async {
    await AppSupabase.client
        .from(_benefitsTable)
        .update(DbValue.normalizeMap(benefit.toMap()))
        .eq('id', benefit.id);
  }

  Future<void> toggleBenefit(String id, bool isActive) async {
    await AppSupabase.client
        .from(_benefitsTable)
        .update({'isActive': isActive})
        .eq('id', id);
  }

  Stream<List<EmployeeBenefitModel>> watchEmployeeBenefits(String employeeId) {
    return AppSupabase.client
        .from(_employeeBenefitsTable)
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(_employeeBenefitFromRow).toList())
        .map(
          (rows) =>
              rows
                  .where(
                    (benefit) =>
                        benefit.employeeId == employeeId && benefit.isActive,
                  )
                  .toList(),
        );
  }

  Stream<List<EmployeeBenefitModel>> watchAllEmployeeBenefits({
    bool onlyActive = false,
  }) {
    return AppSupabase.client
        .from(_employeeBenefitsTable)
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(_employeeBenefitFromRow).toList())
        .map(
          (rows) =>
              onlyActive
                  ? rows.where((benefit) => benefit.isActive).toList()
                  : rows,
        );
  }

  Future<String> assignBenefit(EmployeeBenefitModel empBenefit) async {
    final row =
        await AppSupabase.client
            .from(_employeeBenefitsTable)
            .insert(DbValue.normalizeMap(empBenefit.toMap()))
            .select('id')
            .single();

    return row['id'] as String;
  }

  Future<void> updateEmployeeBenefit(EmployeeBenefitModel empBenefit) async {
    await AppSupabase.client
        .from(_employeeBenefitsTable)
        .update(DbValue.normalizeMap(empBenefit.toMap()))
        .eq('id', empBenefit.id);
  }

  Future<void> updateBenefitValue({
    required String empBenefitId,
    required double currentValue,
    required double newValue,
    required String changedBy,
    String reason = '',
  }) async {
    final row =
        await AppSupabase.client
            .from(_employeeBenefitsTable)
            .select('history')
            .eq('id', empBenefitId)
            .maybeSingle();

    final history =
        row == null
            ? <Map<String, dynamic>>[]
            : List<Map<String, dynamic>>.from(
              ((row['history'] as List?) ?? const []).map(
                (entry) => Map<String, dynamic>.from(entry as Map),
              ),
            );

    history.add(
      BenefitHistoryEntry(
        previousValue: currentValue,
        newValue: newValue,
        changedAt: DateTime.now(),
        changedBy: changedBy,
        reason: reason,
      ).toMap(),
    );

    await AppSupabase.client
        .from(_employeeBenefitsTable)
        .update(
          DbValue.normalizeMap({'monthlyValue': newValue, 'history': history}),
        )
        .eq('id', empBenefitId);
  }

  Future<void> removeBenefitFromEmployee(String empBenefitId) async {
    await AppSupabase.client
        .from(_employeeBenefitsTable)
        .update({
          'isActive': false,
          'endDate': DbValue.toPrimitive(DateTime.now()),
        })
        .eq('id', empBenefitId);
  }

  Future<double> getTotalBenefitCost(String employeeId) async {
    final response = await AppSupabase.client
        .from(_employeeBenefitsTable)
        .select('monthlyValue')
        .eq('employeeId', employeeId)
        .eq('isActive', true);

    return (response as List).fold<double>(0, (total, row) {
      final data = Map<String, dynamic>.from(row as Map);
      return total + (data['monthlyValue'] as num? ?? 0).toDouble();
    });
  }

  EmployeeModel _employeeFromRow(Map<dynamic, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    return EmployeeModel.fromMap(data, data['id'] as String? ?? '');
  }

  SalaryHistoryModel _salaryHistoryFromRow(Map<dynamic, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    return SalaryHistoryModel.fromMap(data, data['id'] as String? ?? '');
  }

  BenefitModel _benefitFromRow(dynamic row) {
    final data = Map<String, dynamic>.from(row as Map);
    return BenefitModel.fromMap(data, data['id'] as String? ?? '');
  }

  BenefitCategoryModel _benefitCategoryFromRow(Map<dynamic, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    return BenefitCategoryModel.fromMap(data, data['id'] as String? ?? '');
  }

  EmployeeBenefitModel _employeeBenefitFromRow(Map<dynamic, dynamic> row) {
    final data = Map<String, dynamic>.from(row);
    return EmployeeBenefitModel.fromMap(data, data['id'] as String? ?? '');
  }
}
