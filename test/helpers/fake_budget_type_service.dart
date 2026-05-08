import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/services/budget_type_service.dart';

class FakeBudgetTypeService extends BudgetTypeService {
  FakeBudgetTypeService({List<BudgetType>? activeTypes})
    : _budgetTypes = List<BudgetType>.from(activeTypes ?? const <BudgetType>[]);

  final List<BudgetType> _budgetTypes;
  Object? getActiveError;
  Object? getTypesError;

  @override
  Future<List<BudgetType>> getActiveBudgetTypes() async {
    if (getActiveError != null) {
      throw getActiveError!;
    }
    return _budgetTypes.where((type) => type.isActive).toList();
  }

  @override
  Future<List<BudgetType>> getBudgetTypes() async {
    if (getTypesError != null) {
      throw getTypesError!;
    }
    return List<BudgetType>.from(_budgetTypes);
  }

  @override
  Future<String> createBudgetType(BudgetType budgetType) async {
    final id =
        budgetType.id.isEmpty
            ? 'type-${_budgetTypes.length + 1}'
            : budgetType.id;
    _budgetTypes.add(budgetType.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateBudgetType(BudgetType budgetType) async {
    final index = _budgetTypes.indexWhere((type) => type.id == budgetType.id);
    if (index >= 0) {
      _budgetTypes[index] = budgetType;
    }
  }

  @override
  Future<void> deleteBudgetType(String id) async {
    _budgetTypes.removeWhere((type) => type.id == id);
  }

  @override
  Future<bool> budgetTypeNameExists(String name, {String? excludeId}) async {
    return _budgetTypes.any(
      (type) =>
          type.name.toLowerCase() == name.toLowerCase() && type.id != excludeId,
    );
  }

  @override
  Future<void> toggleBudgetTypeStatus(String id, bool isActive) async {
    final index = _budgetTypes.indexWhere((type) => type.id == id);
    if (index >= 0) {
      _budgetTypes[index] = _budgetTypes[index].copyWith(isActive: isActive);
    }
  }
}
