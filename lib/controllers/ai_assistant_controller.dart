import 'package:flutter/foundation.dart';
import 'package:project_granith/models/ai_assistant_models.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/services/ai_assistant_service.dart';

class AiAssistantController extends ChangeNotifier {
  AiAssistantController({
    required AiAssistantArea area,
    AiAssistantService? service,
  }) : _area = area,
       _service = service ?? AiAssistantService();

  final AiAssistantService _service;
  final AiAssistantArea _area;

  AiAssistantArea get area => _area;

  AiConversation? _conversation;
  List<AiMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  AiConversation? get conversation => _conversation;
  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  Future<void> init(UserModel user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversation = await _service.getOrCreateConversation(
        area: _area,
        user: user,
      );
      _messages = await _service.loadMessages(_conversation!.id);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> send(UserModel user, String message) async {
    if (_conversation == null) {
      await init(user);
    }
    final currentConversation = _conversation;
    if (currentConversation == null) return false;

    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return false;

    _isSending = true;
    _error = null;
    notifyListeners();

    final optimistic = AiMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: currentConversation.id,
      userId: user.uid,
      area: _area,
      role: AiMessageRole.user,
      content: cleanMessage,
      model: '',
      promptTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
      estimatedCostUsd: 0,
      createdAt: DateTime.now(),
    );
    _messages = [..._messages, optimistic];
    notifyListeners();

    try {
      final answer = await _service.sendMessage(
        area: _area,
        user: user,
        conversation: currentConversation,
        history:
            _messages.where((item) => !item.id.startsWith('local-')).toList(),
        message: cleanMessage,
      );
      _messages = await _service.loadMessages(currentConversation.id);
      if (!_messages.any((item) => item.id == answer.id)) {
        _messages = [..._messages, answer];
      }
      return true;
    } catch (e) {
      _messages = _messages.where((item) => item.id != optimistic.id).toList();
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
