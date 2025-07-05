class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String chatId;
  final String messageType;
  final String fileUrl;
  final String status;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.chatId,
    this.messageType = 'text',
    this.fileUrl = '',
    this.status = 'sent',
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? json['senderUsername'] ?? 'Unknown User',
      content: json['content'] ?? '',
      timestamp: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : (json['sentAt'] != null 
              ? DateTime.parse(json['sentAt'])
              : DateTime.now()),
      chatId: json['chatId'] ?? '',
      messageType: json['messageType'] ?? 'text',
      fileUrl: json['fileUrl'] ?? '',
      status: json['status'] ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'createdAt': timestamp.toIso8601String(),
      'chatId': chatId,
      'messageType': messageType,
      'fileUrl': fileUrl,
      'status': status,
    };
  }
}