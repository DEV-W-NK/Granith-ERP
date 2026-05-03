import 'package:flutter/material.dart';
import 'package:project_granith/models/usage_stats_model.dart';
import 'package:project_granith/services/usage_service.dart';

class SubscriptionController extends ChangeNotifier {
  final UsageService _usageService = UsageService();

  UsageStatsModel? _currentUsage;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _feedbackMessage;

  UsageStatsModel? get currentUsage => _currentUsage;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get feedbackMessage => _feedbackMessage;

  Future<void> loadUsageData() async {
    _isLoading = true;
    _feedbackMessage = null;
    notifyListeners();

    try {
      _currentUsage = await _usageService.getCurrentUsage();
    } catch (e) {
      debugPrint('Erro no controller de assinatura: $e');
      _feedbackMessage = 'Nao foi possivel carregar o snapshot de uso.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> syncUsageData({
    String interval = '24h',
  }) async {
    _isSyncing = true;
    _feedbackMessage = null;
    notifyListeners();

    try {
      final response = await _usageService.syncCurrentUsage(interval: interval);
      _feedbackMessage =
          response['message']?.toString() ?? 'Uso sincronizado com sucesso.';
      _currentUsage = await _usageService.getCurrentUsage();
      return true;
    } catch (e) {
      debugPrint('Erro ao sincronizar uso do Supabase: $e');
      _feedbackMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
