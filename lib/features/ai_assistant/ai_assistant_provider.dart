import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_message.dart';
import 'openai_client.dart';

final openAiClientProvider = Provider<OpenAiClient>((ref) => OpenAiClient());

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  final client = ref.read(openAiClientProvider);
  return AiAssistantNotifier(client);
});

class AiAssistantState {
  final List<AiMessage> messages;
  final bool isLoading;
  final String? error;

  const AiAssistantState({
    required this.messages,
    required this.isLoading,
    required this.error,
  });

  factory AiAssistantState.initial() => AiAssistantState(
        messages: const [],
        isLoading: false,
        error: null,
      );

  AiAssistantState copyWith({
    List<AiMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final OpenAiClient _client;

  AiAssistantNotifier(this._client) : super(AiAssistantState.initial()) {
    // system prompt: ograniczamy temat do nauki EN
    final sys = AiMessage(
      id: 'sys',
      role: 'system',
      text: '''
Jesteś asystentem do nauki języka angielskiego (PL↔EN).
Pomagasz w: gramatyce, słownictwie, tłumaczeniach, ćwiczeniach, poprawie zdań.
Jeśli użytkownik pyta o coś niezwiązanego z angielskim, uprzejmie odmów i przekieruj rozmowę do nauki angielskiego.
Odpowiadaj krótko i konkretnie, często podawaj przykłady.
'''.trim(),
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [sys]);
  }

  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMsg = AiMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: 'user',
      text: trimmed,
      createdAt: DateTime.now(),
    );

    final updated = [...state.messages, userMsg];
    state = state.copyWith(messages: updated, isLoading: true, error: null);

    try {
      final payload = updated
          .where((m) => m.role == 'system' || m.role == 'user' || m.role == 'assistant')
          .map((m) => {'role': m.role, 'content': m.text})
          .toList();

      final reply = await _client.chat(messages: payload);

      final aiMsg = AiMessage(
        id: (DateTime.now().microsecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        text: reply,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearChat() {
    final sys = state.messages.isNotEmpty ? state.messages.first : null;
    state = AiAssistantState.initial();
    if (sys != null && sys.role == 'system') {
      state = state.copyWith(messages: [sys]);
    }
  }
}
