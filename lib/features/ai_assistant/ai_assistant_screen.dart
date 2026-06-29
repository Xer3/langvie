import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/back_app_bar.dart';
import 'ai_assistant_provider.dart';
import 'ai_message.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;

      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(AiAssistantNotifier notifier) async {
    final text = _ctrl.text.trim();

    if (text.isEmpty) return;

    _ctrl.clear();

    await notifier.sendUserMessage(text);

    _scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);
    final notifier = ref.read(aiAssistantProvider.notifier);

    final messages = state.messages.where((m) => m.role != 'system').toList();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: BackAppBar(context: context, title: 'Asystent AI'),
        body: Column(
          children: [
            if (state.error != null)
              MaterialBanner(
                content: Text('Błąd: ${state.error}'),
                actions: [
                  TextButton(
                    onPressed: () => notifier.clearChat(),
                    child: const Text('Wyczyść czat'),
                  ),
                ],
              ),

            Expanded(
              child: messages.isEmpty && !state.isLoading
                  ? const _EmptyChatInfo()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (state.isLoading ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (state.isLoading && i == messages.length) {
                          return const _TypingBubble();
                        }

                        final m = messages[i];
                        final isUser = m.role == 'user';

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Card(
                              color: isUser
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: isUser
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.text,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _fmtTime(m),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.18),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted:
                            state.isLoading ? null : (_) => _send(notifier),
                        decoration: const InputDecoration(
                          hintText: 'Napisz wiadomość',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed:
                            state.isLoading ? null : () => _send(notifier),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Icon(Icons.send, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtTime(AiMessage m) {
    final h = m.createdAt.hour.toString().padLeft(2, '0');
    final min = m.createdAt.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }
}

class _EmptyChatInfo extends StatelessWidget {
  const _EmptyChatInfo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Napisz pytanie do asystenta AI.\nMożesz zapytać o tłumaczenie, gramatykę albo słownictwo.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Asystent pisze…'),
            ],
          ),
        ),
      ),
    );
  }
}