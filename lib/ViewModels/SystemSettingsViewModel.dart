import 'package:flutter/material.dart';
import 'package:project_granith/models/system_settings_model.dart';
import 'package:project_granith/services/system_settings_service.dart';

class SystemSettingsViewModel extends ChangeNotifier {
  final SystemSettingsService _service = SystemSettingsService();

  SystemSettings _settings = const SystemSettings();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  SystemSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  SystemSettingsViewModel() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _service.fetchSettings();
    } catch (error) {
      _errorMessage = 'Nao foi possivel carregar as configuracoes.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(SystemSettings next) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _service.saveSettings(next);
      return true;
    } catch (error) {
      _errorMessage = 'Nao foi possivel salvar as configuracoes.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
