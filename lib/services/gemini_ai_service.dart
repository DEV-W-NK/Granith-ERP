import 'package:project_granith/core/supabase/app_supabase.dart';
import 'package:project_granith/models/ai_assistant_models.dart';

typedef GeminiFunctionInvoker =
    Future<dynamic> Function(String functionName, Map<String, dynamic> body);

class GeminiAiService {
  GeminiAiService({GeminiFunctionInvoker? functionInvoker, String? model})
    : _functionInvoker = functionInvoker ?? _defaultFunctionInvoker,
      _model =
          model ??
          const String.fromEnvironment(
            'GEMINI_MODEL',
            defaultValue: 'gemini-2.5-flash',
          );

  final GeminiFunctionInvoker _functionInvoker;
  final String _model;

  String get model => _model;

  Future<GeminiUsage> generate({
    required String systemInstruction,
    required List<AiMessage> history,
    required String message,
  }) async {
    final data = await _invoke({
      'action': 'generate',
      'model': _model,
      'systemInstruction': systemInstruction,
      'history': history
          .take(12)
          .map(
            (item) => {
              'role': item.role == AiMessageRole.user ? 'user' : 'model',
              'content': item.content,
            },
          )
          .toList(growable: false),
      'message': message,
    });

    final usage = Map<String, dynamic>.from(
      (data['usageMetadata'] as Map?) ?? const {},
    );
    final text = (data['text'] ?? '').toString().trim();

    return GeminiUsage(
      model: (data['model'] ?? _model).toString(),
      text:
          text.isEmpty
              ? 'Nao encontrei uma resposta segura com o contexto disponivel.'
              : text,
      promptTokens: _readInt(data['promptTokens'] ?? usage['promptTokenCount']),
      outputTokens: _readInt(
        data['outputTokens'] ?? usage['candidatesTokenCount'],
      ),
      totalTokens: _readInt(data['totalTokens'] ?? usage['totalTokenCount']),
      rawUsage: usage,
    );
  }

  Future<int> countTokens({
    required String systemInstruction,
    required String message,
  }) async {
    final data = await _invoke({
      'action': 'countTokens',
      'model': _model,
      'systemInstruction': systemInstruction,
      'message': message,
    });
    return _readInt(data['totalTokens']);
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    final result = await _functionInvoker('gemini_generate', body);
    if (result is Map<String, dynamic>) {
      return result;
    }
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    throw const FormatException('Resposta inesperada da function Gemini.');
  }

  static Future<dynamic> _defaultFunctionInvoker(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    final response = await AppSupabase.client.functions.invoke(
      functionName,
      body: body,
    );
    return response.data;
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
