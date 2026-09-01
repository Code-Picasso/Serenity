class Conversation {
  final String id;
  final bool isGroup;
  final String? name;
  final List<String> participantIds;
  final Message? lastMessage;
  final DateTime? updatedAt;

  const Conversation({
    required this.id,
    this.isGroup = false,
    this.name,
    this.participantIds = const [],
    this.lastMessage,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final participants = json['participants'] as List<dynamic>? ?? [];
    final last = json['lastMessage'];
    return Conversation(
      id: json['id'] as String? ?? '',
      isGroup: json['isGroup'] as bool? ?? false,
      name: json['name'] as String?,
      participantIds: participants
          .map((e) => (e as Map<String, dynamic>)['userId'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      lastMessage: last is Map<String, dynamic> ? Message.fromJson(last) : null,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String type;
  final String? content;
  final String? mediaUrl;
  final DateTime? createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.type = 'text',
    this.content,
    this.mediaUrl,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String? ?? '',
        conversationId: json['conversationId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        type: json['type'] as String? ?? 'text',
        content: json['content'] as String?,
        mediaUrl: json['mediaUrl'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  bool get isAudio => type == 'audio';
  bool get isImage => type == 'image';
}
