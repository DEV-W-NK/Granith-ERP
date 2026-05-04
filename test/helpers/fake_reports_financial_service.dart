import 'package:project_granith/models/financial_transaction_model.dart';
import 'package:project_granith/services/financial_service.dart';

class FakeReportsFinancialService extends FinancialService {
  FakeReportsFinancialService({Map<String, double>? categorySums})
    : _categorySums = categorySums ?? const <String, double>{},
      super();

  final Map<String, double> _categorySums;

  TransactionType? lastType;
  DateTime? lastFrom;
  DateTime? lastTo;
  String? lastProjectId;

  @override
  Future<Map<String, double>> getSumByCategory({
    required TransactionType type,
    DateTime? from,
    DateTime? to,
    String? projectId,
  }) async {
    lastType = type;
    lastFrom = from;
    lastTo = to;
    lastProjectId = projectId;
    return Map<String, double>.from(_categorySums);
  }
}
