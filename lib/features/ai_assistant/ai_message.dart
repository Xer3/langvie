class AiMessage {
  final String id;
  final String role; // 'user' | 'assistant' | 'system'
  final String text;
  final DateTime createdAt;

  const AiMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });
}
