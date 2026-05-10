enum AiAssistantArea {
  operational,
  humanResources,
  commercial,
  supplies,
  administrative;

  String get value {
    switch (this) {
      case AiAssistantArea.operational:
        return 'operational';
      case AiAssistantArea.humanResources:
        return 'human_resources';
      case AiAssistantArea.commercial:
        return 'commercial';
      case AiAssistantArea.supplies:
        return 'supplies';
      case AiAssistantArea.administrative:
        return 'administrative';
    }
  }

  String get title {
    switch (this) {
      case AiAssistantArea.operational:
        return 'IA Operacional';
      case AiAssistantArea.humanResources:
        return 'IA Recursos Humanos';
      case AiAssistantArea.commercial:
        return 'IA Comercial';
      case AiAssistantArea.supplies:
        return 'IA Suprimentos';
      case AiAssistantArea.administrative:
        return 'IA Administrativa';
    }
  }

  String get scopeLabel {
    switch (this) {
      case AiAssistantArea.operational:
        return 'obras, medicoes, diarios, campo, frota e execucao';
      case AiAssistantArea.humanResources:
        return 'colaboradores, equipes, beneficios, cargos e rotina de RH';
      case AiAssistantArea.commercial:
        return 'orcamentos, propostas, clientes e obras fechadas';
      case AiAssistantArea.supplies:
        return 'requisicoes, compras, fornecedores, estoque e entregas';
      case AiAssistantArea.administrative:
        return 'configuracoes, acessos, uso da plataforma e governanca';
    }
  }

  String get openingPrompt {
    switch (this) {
      case AiAssistantArea.operational:
        return 'Pergunte sobre andamento de obras, diarios, medicoes ou gargalos de campo.';
      case AiAssistantArea.humanResources:
        return 'Pergunte sobre equipe, cargos, beneficios, pendencias e capacidade de pessoas.';
      case AiAssistantArea.commercial:
        return 'Pergunte sobre propostas, clientes, pipeline comercial e obras fechadas.';
      case AiAssistantArea.supplies:
        return 'Pergunte sobre requisicoes, compras, fornecedores, estoque e rotas.';
      case AiAssistantArea.administrative:
        return 'Pergunte sobre configuracoes, acessos, uso da plataforma e auditoria.';
    }
  }

  static AiAssistantArea fromValue(String? value) {
    for (final area in AiAssistantArea.values) {
      if (area.value == value) return area;
    }
    return AiAssistantArea.operational;
  }
}

enum AiMessageRole {
  user,
  model;

  String get value => this == AiMessageRole.user ? 'user' : 'model';

  static AiMessageRole fromValue(String? value) {
    return value == 'model' ? AiMessageRole.model : AiMessageRole.user;
  }
}

class AiConversation {
  final String id;
  final String userId;
  final String userEmail;
  final AiAssistantArea area;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AiConversation({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.area,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiConversation.fromMap(Map<String, dynamic> map) {
    return AiConversation(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      userEmail: (map['user_email'] ?? map['userEmail'] ?? '').toString(),
      area: AiAssistantArea.fromValue((map['area'] ?? '').toString()),
      title: (map['title'] ?? 'Nova conversa').toString(),
      createdAt: _date(map['created_at'] ?? map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updated_at'] ?? map['updatedAt']) ?? DateTime.now(),
    );
  }
}

class AiMessage {
  final String id;
  final String conversationId;
  final String userId;
  final AiAssistantArea area;
  final AiMessageRole role;
  final String content;
  final String model;
  final int promptTokens;
  final int outputTokens;
  final int totalTokens;
  final double estimatedCostUsd;
  final DateTime createdAt;

  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.area,
    required this.role,
    required this.content,
    required this.model,
    required this.promptTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.estimatedCostUsd,
    required this.createdAt,
  });

  factory AiMessage.fromMap(Map<String, dynamic> map) {
    return AiMessage(
      id: (map['id'] ?? '').toString(),
      conversationId:
          (map['conversation_id'] ?? map['conversationId'] ?? '').toString(),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString(),
      area: AiAssistantArea.fromValue((map['area'] ?? '').toString()),
      role: AiMessageRole.fromValue((map['role'] ?? '').toString()),
      content: (map['content'] ?? '').toString(),
      model: (map['model'] ?? '').toString(),
      promptTokens: _int(map['prompt_tokens'] ?? map['promptTokens']),
      outputTokens: _int(map['output_tokens'] ?? map['outputTokens']),
      totalTokens: _int(map['total_tokens'] ?? map['totalTokens']),
      estimatedCostUsd: _double(
        map['estimated_cost_usd'] ?? map['estimatedCostUsd'],
      ),
      createdAt: _date(map['created_at'] ?? map['createdAt']) ?? DateTime.now(),
    );
  }
}

class AiPricingConfig {
  final String id;
  final String model;
  final double inputPerMillionUsd;
  final double outputPerMillionUsd;
  final DateTime? updatedAt;

  const AiPricingConfig({
    required this.id,
    required this.model,
    required this.inputPerMillionUsd,
    required this.outputPerMillionUsd,
    this.updatedAt,
  });

  factory AiPricingConfig.fromMap(Map<String, dynamic> map) {
    return AiPricingConfig(
      id: (map['id'] ?? '').toString(),
      model: (map['model'] ?? '').toString(),
      inputPerMillionUsd: _double(
        map['input_per_million_usd'] ?? map['inputPerMillionUsd'],
      ),
      outputPerMillionUsd: _double(
        map['output_per_million_usd'] ?? map['outputPerMillionUsd'],
      ),
      updatedAt: _date(map['updated_at'] ?? map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({String? updatedBy}) {
    return {
      'id': id.isEmpty ? model : id,
      'model': model,
      'input_per_million_usd': inputPerMillionUsd,
      'output_per_million_usd': outputPerMillionUsd,
      if (updatedBy != null) 'updated_by': updatedBy,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

class AiUsageSummary {
  final int requests;
  final int promptTokens;
  final int outputTokens;
  final int totalTokens;
  final double estimatedCostUsd;
  final Map<AiAssistantArea, int> requestsByArea;

  const AiUsageSummary({
    required this.requests,
    required this.promptTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.estimatedCostUsd,
    required this.requestsByArea,
  });

  factory AiUsageSummary.empty() {
    return const AiUsageSummary(
      requests: 0,
      promptTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
      estimatedCostUsd: 0,
      requestsByArea: {},
    );
  }
}

class GeminiUsage {
  final String model;
  final String text;
  final int promptTokens;
  final int outputTokens;
  final int totalTokens;
  final Map<String, dynamic> rawUsage;

  const GeminiUsage({
    required this.model,
    required this.text,
    required this.promptTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.rawUsage,
  });
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
