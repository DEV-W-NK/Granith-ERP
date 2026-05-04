import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/system_settings_model.dart';

void main() {
  group('SystemSettings', () {
    test('fromMap aceita camelCase, snake_case e bools em formatos mistos', () {
      final settings = SystemSettings.fromMap({
        'id': 'default',
        'workspace_name': 'Granith Prime',
        'workspaceTagline': 'ERP Comercial',
        'dashboard_greeting_title': 'Ola, Time',
        'dashboardGreetingSubtitle': 'Panorama diario',
        'ai_assistant_preview_enabled': 'true',
        'compact_navigation': 1,
        'support_email': 'SUPORTE@EMPRESA.COM',
        'supportPhone': '11 99999-0000',
        'client_portal_welcome_message': 'Bem-vindo',
        'client_portal_show_budgets': true,
        'client_portal_show_budget_values': '1',
        'client_portal_show_current_costs': 0,
        'updated_at': '2026-05-03T12:00:00Z',
      });

      expect(settings.workspaceName, 'Granith Prime');
      expect(settings.workspaceTagline, 'ERP Comercial');
      expect(settings.aiAssistantPreviewEnabled, isTrue);
      expect(settings.compactNavigation, isTrue);
      expect(settings.clientPortalShowBudgetValues, isTrue);
      expect(settings.clientPortalShowCurrentCosts, isFalse);
      expect(settings.updatedAt, DateTime.parse('2026-05-03T12:00:00Z'));
    });

    test('toMap normaliza campos textuais principais', () {
      final settings = SystemSettings(
        workspaceName: '  Granith  ',
        workspaceTagline: '  Dusk  ',
        dashboardGreetingTitle: ' Ola ',
        dashboardGreetingSubtitle: ' Painel ',
        supportEmail: 'SUPORTE@EMPRESA.COM ',
        supportPhone: ' 11 99999-0000 ',
        clientPortalWelcomeMessage: ' Bem-vindo ',
      );

      final map = settings.toMap();

      expect(map['workspace_name'], 'Granith');
      expect(map['workspace_tagline'], 'Dusk');
      expect(map['support_email'], 'suporte@empresa.com');
      expect(map['support_phone'], '11 99999-0000');
      expect(map['client_portal_welcome_message'], 'Bem-vindo');
    });
  });
}
