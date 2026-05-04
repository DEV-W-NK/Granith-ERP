import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/ViewModels/SystemSettingsViewModel.dart';
import 'package:project_granith/models/system_settings_model.dart';
import '../helpers/fake_system_settings_service.dart';

void main() {
  group('SystemSettingsViewModel', () {
    test('loadSettings carrega configuracoes e limpa erro', () async {
      final service = FakeSystemSettingsService(
        settings: const SystemSettings(workspaceName: 'Granith Prime'),
      );
      final viewModel = SystemSettingsViewModel(
        service: service,
        bootstrapOnInit: false,
      );

      await viewModel.loadSettings();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.settings.workspaceName, 'Granith Prime');
    });

    test('loadSettings expoe mensagem amigavel quando falha', () async {
      final service =
          FakeSystemSettingsService()..fetchError = Exception('offline');
      final viewModel = SystemSettingsViewModel(
        service: service,
        bootstrapOnInit: false,
      );

      await viewModel.loadSettings();

      expect(viewModel.isLoading, isFalse);
      expect(
        viewModel.errorMessage,
        'Nao foi possivel carregar as configuracoes.',
      );
    });

    test('save atualiza estado local quando persiste com sucesso', () async {
      final service = FakeSystemSettingsService();
      final viewModel = SystemSettingsViewModel(
        service: service,
        bootstrapOnInit: false,
      );
      const next = SystemSettings(
        workspaceName: 'Granith Executive',
        compactNavigation: true,
      );

      final result = await viewModel.save(next);

      expect(result, isTrue);
      expect(viewModel.isSaving, isFalse);
      expect(viewModel.settings.workspaceName, 'Granith Executive');
      expect(service.lastSavedSettings?.compactNavigation, isTrue);
    });

    test('save retorna false e mensagem amigavel quando falha', () async {
      final service =
          FakeSystemSettingsService()..saveError = Exception('db error');
      final viewModel = SystemSettingsViewModel(
        service: service,
        bootstrapOnInit: false,
      );

      final result = await viewModel.save(
        const SystemSettings(workspaceName: 'Falha'),
      );

      expect(result, isFalse);
      expect(viewModel.isSaving, isFalse);
      expect(
        viewModel.errorMessage,
        'Nao foi possivel salvar as configuracoes.',
      );
    });
  });
}
