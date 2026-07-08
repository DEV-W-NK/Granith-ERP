import 'package:flutter/material.dart';
import 'package:project_granith/ViewModels/AuthViewModel.dart';
import 'package:project_granith/controllers/ai_assistant_controller.dart';
import 'package:project_granith/models/ai_assistant_models.dart';
import 'package:project_granith/models/user_model.dart';
import 'package:project_granith/themes/app_theme.dart';
import 'package:provider/provider.dart';

class AiAssistantPage extends StatelessWidget {
  final AiAssistantArea area;

  const AiAssistantPage({super.key, required this.area});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey('ai-controller-${area.value}'),
      create: (_) => AiAssistantController(area: area),
      child: _AiAssistantView(
        key: ValueKey('ai-view-${area.value}'),
        area: area,
      ),
    );
  }
}

class _AiAssistantView extends StatefulWidget {
  final AiAssistantArea area;

  const _AiAssistantView({super.key, required this.area});

  @override
  State<_AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<_AiAssistantView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _bootstrapped = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;
    final controller = context.watch<AiAssistantController>();

    if (!_bootstrapped && user != null) {
      _bootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final aiController = context.read<AiAssistantController>();
        aiController.init(user).then((_) {
          if (!mounted) return;
          _scrollToBottom();
        });
      });
    }

    if (user == null) {
      return const Center(
        child: Text(
          'Entre no sistema para usar a IA.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _AiHeader(area: widget.area),
              const SizedBox(height: 14),
              Expanded(child: _buildBody(controller)),
              const SizedBox(height: 12),
              _AiComposer(
                controller: _messageController,
                isSending: controller.isSending,
                onSend: () => _send(user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AiAssistantController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentBlue),
      );
    }

    final messages = controller.messages;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          if (controller.error != null) _ErrorStrip(message: controller.error!),
          Expanded(
            child:
                messages.isEmpty
                    ? _EmptyAiState(area: widget.area)
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _MessageBubble(message: messages[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(UserModel user) async {
    final text = _messageController.text;
    _messageController.clear();
    final success = await context.read<AiAssistantController>().send(
      user,
      text,
    );
    if (!mounted || !success) return;

    await Future<void>.delayed(const Duration(milliseconds: 80));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

class _AiHeader extends StatelessWidget {
  final AiAssistantArea area;

  const _AiHeader({required this.area});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Consulta read-only: ${area.scopeLabel}.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const _ReadOnlyPill(),
        ],
      ),
    );
  }
}

class _ReadOnlyPill extends StatelessWidget {
  const _ReadOnlyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.25),
        ),
      ),
      child: const Text(
        'somente leitura',
        style: TextStyle(
          color: AppColors.accentGreen,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyAiState extends StatelessWidget {
  final AiAssistantArea area;

  const _EmptyAiState({required this.area});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              area.openingPrompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AiMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiMessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              isUser
                  ? AppColors.accentBlue.withValues(alpha: 0.16)
                  : AppColors.backgroundDark.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isUser
                    ? AppColors.accentBlue.withValues(alpha: 0.22)
                    : AppColors.borderColor.withValues(alpha: 0.50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.42,
              ),
            ),
            if (!isUser && message.totalTokens > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${message.totalTokens} tokens usados',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AiComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _AiComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            enabled: !isSending,
            decoration: const InputDecoration(
              labelText: 'Pergunte dentro do escopo deste modulo',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            onSubmitted: (_) => onSend(),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          tooltip: 'Enviar',
          onPressed: isSending ? null : onSend,
          icon:
              isSending
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.send_rounded),
        ),
      ],
    );
  }
}

class _ErrorStrip extends StatelessWidget {
  final String message;

  const _ErrorStrip({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}
