class SystemSettings {
  final String id;
  final String workspaceName;
  final String workspaceTagline;
  final String dashboardGreetingTitle;
  final String dashboardGreetingSubtitle;
  final bool aiAssistantPreviewEnabled;
  final bool compactNavigation;
  final String supportEmail;
  final String supportPhone;
  final String clientPortalWelcomeMessage;
  final bool clientPortalShowBudgets;
  final bool clientPortalShowBudgetValues;
  final bool clientPortalShowCurrentCosts;
  final DateTime? updatedAt;

  const SystemSettings({
    this.id = 'default',
    this.workspaceName = 'GRANITH',
    this.workspaceTagline = 'ERP Dusk Console',
    this.dashboardGreetingTitle = 'Ola, Gestor',
    this.dashboardGreetingSubtitle =
        'Aqui esta o panorama atual das suas obras.',
    this.aiAssistantPreviewEnabled = true,
    this.compactNavigation = false,
    this.supportEmail = '',
    this.supportPhone = '',
    this.clientPortalWelcomeMessage =
        'Acompanhe projetos, propostas e visao executiva relacionados a sua conta.',
    this.clientPortalShowBudgets = true,
    this.clientPortalShowBudgetValues = true,
    this.clientPortalShowCurrentCosts = true,
    this.updatedAt,
  });

  factory SystemSettings.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    bool readBool(String key, {bool fallback = false}) {
      final value = map[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return fallback;
    }

    return SystemSettings(
      id: (map['id'] ?? 'default').toString(),
      workspaceName:
          (map['workspace_name'] ?? map['workspaceName'] ?? 'GRANITH')
              .toString(),
      workspaceTagline:
          (map['workspace_tagline'] ??
                  map['workspaceTagline'] ??
                  'ERP Dusk Console')
              .toString(),
      dashboardGreetingTitle:
          (map['dashboard_greeting_title'] ??
                  map['dashboardGreetingTitle'] ??
                  'Ola, Gestor')
              .toString(),
      dashboardGreetingSubtitle:
          (map['dashboard_greeting_subtitle'] ??
                  map['dashboardGreetingSubtitle'] ??
                  'Aqui esta o panorama atual das suas obras.')
              .toString(),
      aiAssistantPreviewEnabled: readBool(
        'ai_assistant_preview_enabled',
        fallback: true,
      ),
      compactNavigation: readBool('compact_navigation'),
      supportEmail:
          (map['support_email'] ?? map['supportEmail'] ?? '').toString(),
      supportPhone:
          (map['support_phone'] ?? map['supportPhone'] ?? '').toString(),
      clientPortalWelcomeMessage:
          (map['client_portal_welcome_message'] ??
                  map['clientPortalWelcomeMessage'] ??
                  'Acompanhe projetos, propostas e visao executiva relacionados a sua conta.')
              .toString(),
      clientPortalShowBudgets: readBool(
        'client_portal_show_budgets',
        fallback: true,
      ),
      clientPortalShowBudgetValues: readBool(
        'client_portal_show_budget_values',
        fallback: true,
      ),
      clientPortalShowCurrentCosts: readBool(
        'client_portal_show_current_costs',
        fallback: true,
      ),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  SystemSettings copyWith({
    String? id,
    String? workspaceName,
    String? workspaceTagline,
    String? dashboardGreetingTitle,
    String? dashboardGreetingSubtitle,
    bool? aiAssistantPreviewEnabled,
    bool? compactNavigation,
    String? supportEmail,
    String? supportPhone,
    String? clientPortalWelcomeMessage,
    bool? clientPortalShowBudgets,
    bool? clientPortalShowBudgetValues,
    bool? clientPortalShowCurrentCosts,
    DateTime? updatedAt,
  }) {
    return SystemSettings(
      id: id ?? this.id,
      workspaceName: workspaceName ?? this.workspaceName,
      workspaceTagline: workspaceTagline ?? this.workspaceTagline,
      dashboardGreetingTitle:
          dashboardGreetingTitle ?? this.dashboardGreetingTitle,
      dashboardGreetingSubtitle:
          dashboardGreetingSubtitle ?? this.dashboardGreetingSubtitle,
      aiAssistantPreviewEnabled:
          aiAssistantPreviewEnabled ?? this.aiAssistantPreviewEnabled,
      compactNavigation: compactNavigation ?? this.compactNavigation,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      clientPortalWelcomeMessage:
          clientPortalWelcomeMessage ?? this.clientPortalWelcomeMessage,
      clientPortalShowBudgets:
          clientPortalShowBudgets ?? this.clientPortalShowBudgets,
      clientPortalShowBudgetValues:
          clientPortalShowBudgetValues ?? this.clientPortalShowBudgetValues,
      clientPortalShowCurrentCosts:
          clientPortalShowCurrentCosts ?? this.clientPortalShowCurrentCosts,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workspace_name': workspaceName.trim(),
      'workspace_tagline': workspaceTagline.trim(),
      'dashboard_greeting_title': dashboardGreetingTitle.trim(),
      'dashboard_greeting_subtitle': dashboardGreetingSubtitle.trim(),
      'ai_assistant_preview_enabled': aiAssistantPreviewEnabled,
      'compact_navigation': compactNavigation,
      'support_email': supportEmail.trim().toLowerCase(),
      'support_phone': supportPhone.trim(),
      'client_portal_welcome_message': clientPortalWelcomeMessage.trim(),
      'client_portal_show_budgets': clientPortalShowBudgets,
      'client_portal_show_budget_values': clientPortalShowBudgetValues,
      'client_portal_show_current_costs': clientPortalShowCurrentCosts,
    };
  }
}
