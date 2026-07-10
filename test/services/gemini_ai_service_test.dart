import 'package:flutter_test/flutter_test.dart';
import 'package:project_granith/models/ai_assistant_models.dart';
import 'package:project_granith/services/gemini_ai_service.dart';

void main() {
  AiMessage message({required AiMessageRole role, required String content}) {
    return AiMessage(
      id: role.value,
      conversationId: 'conversation-1',
      userId: 'user-1',
      area: AiAssistantArea.operational,
      role: role,
      content: content,
      model: 'gemini-2.5-flash',
      promptTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
      estimatedCostUsd: 0,
      createdAt: DateTime(2026),
    );
  }

  test('generate usa Edge Function em vez de API key no cliente', () async {
    late String functionName;
    late Map<String, dynamic> body;
    final service = GeminiAiService(
      functionInvoker: (name, requestBody) async {
        functionName = name;
        body = requestBody;
        return {
          'model': 'gemini-2.5-flash',
          'text': 'Resposta segura',
          'usageMetadata': {
            'promptTokenCount': 11,
            'candidatesTokenCount': 7,
            'totalTokenCount': 18,
          },
        };
      },
    );

    final result = await service.generate(
      systemInstruction: 'Use apenas o contexto permitido.',
      history: [
        message(role: AiMessageRole.user, content: 'Pergunta anterior'),
        message(role: AiMessageRole.model, content: 'Resposta anterior'),
      ],
      message: 'Como esta a obra?',
    );

    expect(functionName, 'gemini_generate');
    expect(body['action'], 'generate');
    expect(body.containsKey('apiKey'), isFalse);
    expect(body['systemInstruction'], 'Use apenas o contexto permitido.');
    expect(body['message'], 'Como esta a obra?');
    expect(body['history'], hasLength(2));
    expect(result.text, 'Resposta segura');
    expect(result.promptTokens, 11);
    expect(result.outputTokens, 7);
    expect(result.totalTokens, 18);
  });

  test('countTokens tambem passa pela Edge Function', () async {
    final service = GeminiAiService(
      functionInvoker: (name, body) async {
        expect(name, 'gemini_generate');
        expect(body['action'], 'countTokens');
        expect(body.containsKey('apiKey'), isFalse);
        return {'totalTokens': 42};
      },
    );

    final total = await service.countTokens(
      systemInstruction: 'Contexto',
      message: 'Pergunta',
    );

    expect(total, 42);
  });
}
