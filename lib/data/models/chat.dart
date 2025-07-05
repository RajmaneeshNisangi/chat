class Chat {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime timestamp;
  final List<String> participants;
  final bool isGroupChat;

  Chat({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.timestamp,
    required this.participants,
    this.isGroupChat = false,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    String chatName = 'Unknown Chat';
    if (json['participants'] != null && json['participants'] is List) {
      final participantsList = json['participants'] as List;
      if (participantsList.isNotEmpty) {
        final otherParticipants =
            participantsList
                .where(
                  (p) =>
                      p['_id'] != '673d80bc2330e08c323f4393',
                )
                .toList();

        if (otherParticipants.isNotEmpty) {
          chatName = otherParticipants.first['name'] ?? 'Unknown';
        } else if (participantsList.isNotEmpty) {
          chatName = participantsList.first['name'] ?? 'Unknown';
        }
      }
    }

    String lastMessageContent = 'No messages yet';
    if (json['lastMessage'] != null && json['lastMessage']['content'] != null) {
      lastMessageContent = json['lastMessage']['content'];
    }

    DateTime messageTimestamp = DateTime.now();
    if (json['lastMessage'] != null &&
        json['lastMessage']['createdAt'] != null) {
      messageTimestamp = DateTime.parse(json['lastMessage']['createdAt']);
    } else if (json['updatedAt'] != null) {
      messageTimestamp = DateTime.parse(json['updatedAt']);
    }

    List<String> participantIds = [];
    if (json['participants'] != null && json['participants'] is List) {
      participantIds =
          (json['participants'] as List)
              .map((p) => p['_id'] as String)
              .toList();
    }

    return Chat(
      id: json['_id'] ?? '',
      name: chatName,
      lastMessage: lastMessageContent,
      timestamp: messageTimestamp,
      participants: participantIds,
      isGroupChat: json['isGroupChat'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'lastMessage': lastMessage,
      'updatedAt': timestamp.toIso8601String(),
      'participants': participants,
      'isGroupChat': isGroupChat,
    };
  }
}
