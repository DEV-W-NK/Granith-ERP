import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/models/diario_obra_model.dart';
import 'fake_daily_log_service.dart';

class FakeDailyLogController extends DailyLogController {
  FakeDailyLogController() : super(service: FakeDailyLogService());

  bool loadLogsCalled = false;
  bool signLogCalled = false;
  bool nextLoadingState = false;
  List<DailyLogModel> nextLogs = <DailyLogModel>[];
  Object? signLogError;

  @override
  bool get isLoading => nextLoadingState;

  @override
  List<DailyLogModel> get logs => nextLogs;

  @override
  Future<void> loadLogs() async {
    loadLogsCalled = true;
    notifyListeners();
  }

  @override
  Future<void> signLog(DailyLogModel log) async {
    signLogCalled = true;
    if (signLogError != null) {
      throw signLogError!;
    }
    nextLogs =
        nextLogs
            .map(
              (item) =>
                  item.id == log.id
                      ? log.copyWith(status: LogStatus.signed)
                      : item,
            )
            .toList();
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
