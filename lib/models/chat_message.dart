class ChatMessage {
  String content;
  final String role;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.content, required this.timestamp});

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: j['role'],
        content: j['content'],
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}
