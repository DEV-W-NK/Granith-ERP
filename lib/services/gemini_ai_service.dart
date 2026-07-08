import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project_granith/models/ai_assistant_models.dart';

class GeminiAiService {
  GeminiAiService({http.Client? httpClient, String? apiKey, String? model})
    : _httpClient = httpClient ?? http.Client(),
      _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
      _model =
          model ??
          const String.fromEnvironment(
            'GEMINI_MODEL',
            defaultValue: 'gemini-2.5-flash',
          );

  final http.Client _httpClient;
  final String _apiKey;
  final String _model;

  String get model => _model;

  Future<GeminiUsage> generate({
    required String systemInstruction,
    required List<AiMessage> history,
    required String message,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw Exception(
        'GEMINI_API_KEY nao configurada. Informe a chave via --dart-define.',
      );
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
      {'key': _apiKey},
    );

    final contents = <Map<String, dynamic>>[
      ...history
          .take(12)
          .map(
            (item) => {
              'role': item.role == AiMessageRole.user ? 'user' : 'model',
              'parts': [
                {'text': item.content},
              ],
            },
          ),
      {
        'role': 'user',
        'parts': [
          {'text': message},
        ],
      },
    ];

    final response = await _httpClient.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.2,
          'topP': 0.8,
          'maxOutputTokens': 1200,
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Falha no Gemini (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta inesperada do Gemini.');
    }

    final text = _extractText(decoded);
    final usage = Map<String, dynamic>.from(
      (decoded['usageMetadata'] as Map?) ?? const {},
    );

    return GeminiUsage(
      model: _model,
      text:
          text.trim().isEmpty
              ? 'Nao encontrei uma resposta segura com o contexto disponivel.'
              : text.trim(),
      promptTokens: _readInt(usage['promptTokenCount']),
      outputTokens: _readInt(usage['candidatesTokenCount']),
      totalTokens: _readInt(usage['totalTokenCount']),
      rawUsage: usage,
    );
  }

  Future<int> countTokens({
    required String systemInstruction,
    required String message,
  }) async {
    if (_apiKey.trim().isEmpty) return 0;

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:countTokens',
      {'key': _apiKey},
    );

    final response = await _httpClient.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': '$systemInstruction\n\n$message'},
            ],
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) return 0;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return 0;
    return _readInt(decoded['totalTokens']);
  }

  String _extractText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final content = (candidates.first as Map?)?['content'];
    final parts = (content as Map?)?['parts'];
    if (parts is! List) return '';

    return parts
        .map((part) {
          if (part is Map && part['text'] != null) {
            return part['text'].toString();
          }
          return '';
        })
        .where((text) => text.trim().isNotEmpty)
        .join('\n');
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
