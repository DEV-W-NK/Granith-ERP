import 'package:flutter/material.dart';
import 'package:project_granith/models/usage_stats_model.dart';
import 'package:project_granith/services/usage_service.dart';
import 'package:project_granith/services/auth_service.dart';

class SubscriptionController extends ChangeNotifier {
  final UsageService _usageService = UsageService();
  final AuthService _authService = AuthService();

  UsageStatsModel? _currentUsage;
  UsageStatsModel? get currentUsage => _currentUsage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadUsageData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Usa o UID como tenantId por enquanto
        _currentUsage = await _usageService.getCurrentUsage(user.id);
      }
    } catch (e) {
      debugPrint('Erro no controller de assinatura: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
