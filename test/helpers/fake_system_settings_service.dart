import 'package:project_granith/models/system_settings_model.dart';
import 'package:project_granith/services/system_settings_service.dart';

class FakeSystemSettingsService extends SystemSettingsService {
  FakeSystemSettingsService({this.settings = const SystemSettings()});

  SystemSettings settings;
  Object? fetchError;
  Object? saveError;
  SystemSettings? lastSavedSettings;

  @override
  Future<SystemSettings> fetchSettings() async {
    if (fetchError != null) {
      throw fetchError!;
    }
    return settings;
  }

  @override
  Future<SystemSettings> saveSettings(SystemSettings settings) async {
    if (saveError != null) {
      throw saveError!;
    }
    lastSavedSettings = settings;
    this.settings = settings;
    return settings;
  }
}
