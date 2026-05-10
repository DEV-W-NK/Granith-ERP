import 'package:flutter/material.dart';
import 'package:project_granith/models/ai_assistant_models.dart';
import 'package:project_granith/models/usage_stats_model.dart';
import 'package:project_granith/services/ai_assistant_service.dart';
import 'package:project_granith/services/usage_service.dart';

class SubscriptionController extends ChangeNotifier {
  final UsageService _usageService;
  final AiAssistantService _aiService;

  SubscriptionController({
    UsageService? usageService,
    AiAssistantService? aiService,
  }) : _usageService = usageService ?? UsageService(),
       _aiService = aiService ?? AiAssistantService();

  UsageStatsModel? _currentUsage;
  AiUsageSummary _aiUsageSummary = AiUsageSummary.empty();
  AiPricingConfig? _aiPricingConfig;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _feedbackMessage;

  UsageStatsModel? get currentUsage => _currentUsage;
  AiUsageSummary get aiUsageSummary => _aiUsageSummary;
  AiPricingConfig? get aiPricingConfig => _aiPricingConfig;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get feedbackMessage => _feedbackMessage;

  Future<void> loadUsageData() async {
    _isLoading = true;
    _feedbackMessage = null;
    notifyListeners();

    try {
      _currentUsage = await _usageService.getCurrentUsage();
      try {
        _aiUsageSummary = await _aiService.loadUsageSummary();
        _aiPricingConfig = await _aiService.getPricing('gemini-2.5-flash');
      } catch (aiError) {
        // O painel principal de uso nao deve falhar quando as tabelas de IA
        // ainda nao foram aplicadas no ambiente.
      }
    } catch (e) {
      debugPrint('Erro no controller de assinatura: $e');
      _feedbackMessage = 'Nao foi possivel carregar o snapshot de uso.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> syncUsageData({String interval = '24h'}) async {
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

  Future<bool> saveAiPricing({
    required String model,
    required double inputPerMillionUsd,
    required double outputPerMillionUsd,
    String? updatedBy,
  }) async {
    try {
      final pricing = AiPricingConfig(
        id: model,
        model: model,
        inputPerMillionUsd: inputPerMillionUsd,
        outputPerMillionUsd: outputPerMillionUsd,
      );
      await _aiService.savePricing(pricing, updatedBy: updatedBy);
      _aiPricingConfig = pricing;
      _feedbackMessage = 'Preco da IA atualizado.';
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar preco de IA: $e');
      _feedbackMessage = 'Nao foi possivel salvar o preco da IA.';
      notifyListeners();
      return false;
    }
  }
}
