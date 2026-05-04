import 'package:project_granith/models/budget_type.dart';
import 'package:project_granith/services/budget_type_service.dart';

class FakeBudgetTypeService extends BudgetTypeService {
  FakeBudgetTypeService({List<BudgetType>? activeTypes})
    : _activeTypes = List<BudgetType>.from(activeTypes ?? const <BudgetType>[]);

  final List<BudgetType> _activeTypes;
  Object? getActiveError;

  @override
  Future<List<BudgetType>> getActiveBudgetTypes() async {
    if (getActiveError != null) {
      throw getActiveError!;
    }
    return List<BudgetType>.from(_activeTypes);
  }
}
