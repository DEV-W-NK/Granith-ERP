import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'fake_daily_log_service.dart';

class FakeDailyLogController extends DailyLogController {
  FakeDailyLogController() : super(service: FakeDailyLogService());

  bool loadLogsCalled = false;
  bool nextLoadingState = false;
  List<DailyLogModel> nextLogs = <DailyLogModel>[];

  @override
  bool get isLoading => nextLoadingState;

  @override
  List<DailyLogModel> get logs => nextLogs;

  @override
  Future<void> loadLogs() async {
    loadLogsCalled = true;
    notifyListeners();
  }

  void emit({bool? isLoading, List<DailyLogModel>? logs}) {
    if (isLoading != null) {
      nextLoadingState = isLoading;
    }
    if (logs != null) {
      nextLogs = logs;
    }
    notifyListeners();
  }
}
