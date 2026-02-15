import 'package:flutter/material.dart';
import 'package:project_granith/models/statistics_model.dart';

/// Gerencia o estado dos dados do Dashboard.
/// Preparado para integração futura com Firestore e Gemini.
class HomeController extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // No futuro, esses dados virão do Service
  List<dynamic> _mainStats = [];
  List<dynamic> get mainStats => _mainStats;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulando fetch de dados
      await Future.delayed(const Duration(milliseconds: 500));
      _mainStats = StatisticsModel.mainStats;
    } catch (e) {
      debugPrint("Erro ao carregar dashboard: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Placeholder para a futura integração com a IA Gemini
  Future<void> askAiInsight(String prompt) async {
    // Lógica da IA aqui
  }
}