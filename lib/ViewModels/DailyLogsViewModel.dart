import 'package:flutter/material.dart';
import 'package:project_granith/controllers/daily_log_controller.dart';
import 'package:project_granith/models/diario_obra_model.dart';

class DailyLogsViewModel extends ChangeNotifier {
  final DailyLogController _controller;
  bool _hasLoaded = false;

  DailyLogsViewModel(this._controller) {
    _init();
  }

  void _init() {
    _controller.addListener(notifyListeners);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasLoaded) return;
      _hasLoaded = true;
      _controller.loadLogs();
    });
  }

  bool get isLoading => _controller.isLoading;
  List<DailyLogModel> get logs => _controller.logs;

  void refreshLogs() => _controller.loadLogs();

  Future<void> signLog(DailyLogModel log) => _controller.signLog(log);

  String getAiInsight() {
    return 'Analise de IA: o clima chuvoso impactou 20% da produtividade esta semana.';
  }

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    super.dispose();
  }
}
