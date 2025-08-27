class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final String? replyToId;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
    this.replyToId,
    this.imageUrl,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      replyToId: json['replyToId'],
      imageUrl: json['imageUrl'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.toString().split('.').last,
      'replyToId': replyToId,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromFirebase(Map<String, dynamic> data, String key) {
    return ChatMessage(
      id: key,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'])
          : DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      replyToId: data['replyToId'],
      imageUrl: data['imageUrl'],
      metadata: data['metadata'],
    );
  }
}

enum MessageType { text, image, file, quiz, task }

class Conversation {
  final String id;
  final String title;
  final List<String> participantIds;
  final List<ChatMessage> messages;
  final DateTime lastActivity;
  final bool isGroupChat;
  final String? lastMessageId;
  final String? lastMessageText;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final String? lastSenderName;

  Conversation({
    required this.id,
    required this.title,
    required this.participantIds,
    this.messages = const [],
    DateTime? lastActivity,
    this.isGroupChat = false,
    this.lastMessageId,
    this.lastMessageText,
    this.lastMessageTime,
    this.lastSenderId,
    this.lastSenderName,
  }) : lastActivity = lastActivity ?? DateTime.now();

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      participantIds: List<String>.from(
        (json['participantIds'] as List<Object?>?) ?? [],
      ),
      messages:
          (json['messages'] as List<Object?>?)
              ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastActivity: json['lastActivity'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastActivity'])
          : DateTime.now(),
      isGroupChat: json['isGroupChat'] ?? false,
      lastMessageId: json['lastMessageId'],
      lastMessageText: json['lastMessageText'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime'])
          : null,
      lastSenderId: json['lastSenderId'],
      lastSenderName: json['lastSenderName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'participantIds': participantIds,
      'messages': messages.map((e) => e.toJson()).toList(),
      'lastActivity': lastActivity.millisecondsSinceEpoch,
      'isGroupChat': isGroupChat,
      'lastMessageId': lastMessageId,
      'lastMessageText': lastMessageText,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastSenderId': lastSenderId,
      'lastSenderName': lastSenderName,
    };
  }

  factory Conversation.fromFirebase(Map<String, dynamic> data, String key) {
    return Conversation(
      id: key,
      title: data['title'] ?? '',
      participantIds: List<String>.from(
        (data['participantIds'] as List<Object?>?) ?? [],
      ),
      messages: [], // Messages will be loaded separately
      lastActivity: data['lastActivity'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastActivity'])
          : DateTime.now(),
      isGroupChat: data['isGroupChat'] ?? false,
      lastMessageId: data['lastMessageId'],
      lastMessageText: data['lastMessageText'],
      lastMessageTime: data['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastMessageTime'])
          : null,
      lastSenderId: data['lastSenderId'],
      lastSenderName: data['lastSenderName'],
    );
  }

  String get displayLastMessage {
    if (lastMessageText != null && lastMessageText!.isNotEmpty) {
      return lastMessageText!;
    }
    if (messages.isEmpty) return 'No messages yet';
    final lastMessage = messages.last;
    switch (lastMessage.type) {
      case MessageType.text:
        return lastMessage.message;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 File';
      case MessageType.quiz:
        return '📝 Quiz shared';
      case MessageType.task:
        return '✅ Task shared';
    }
  }

  Conversation copyWith({
    String? id,
    String? title,
    List<String>? participantIds,
    List<ChatMessage>? messages,
    DateTime? lastActivity,
    bool? isGroupChat,
    String? lastMessageId,
    String? lastMessageText,
    DateTime? lastMessageTime,
    String? lastSenderId,
    String? lastSenderName,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      participantIds: participantIds ?? this.participantIds,
      messages: messages ?? this.messages,
      lastActivity: lastActivity ?? this.lastActivity,
      isGroupChat: isGroupChat ?? this.isGroupChat,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      lastSenderName: lastSenderName ?? this.lastSenderName,
    );
  }
}

class UserPresence {
  final String userId;
  final String userName;
  final bool isOnline;
  final DateTime lastSeen;
  final String? status;

  UserPresence({
    required this.userId,
    required this.userName,
    required this.isOnline,
    required this.lastSeen,
    this.status,
  });

  factory UserPresence.fromFirebase(Map<String, dynamic> data, String key) {
    return UserPresence(
      userId: key,
      userName: data['userName'] ?? 'Unknown User',
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'])
          : DateTime.now(),
      status: data['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'isOnline': isOnline,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'status': status,
    };
  }
}

class ChatRoom {
  final String id;
  final String title;
  final List<String> participantIds;
  final bool isGroupChat;
  final DateTime createdAt;
  final String createdBy;
  final Map<String, dynamic>? settings;

  ChatRoom({
    required this.id,
    required this.title,
    required this.participantIds,
    required this.isGroupChat,
    required this.createdAt,
    required this.createdBy,
    this.settings,
  });

  factory ChatRoom.fromFirebase(Map<String, dynamic> data, String key) {
    return ChatRoom(
      id: key,
      title: data['title'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      isGroupChat: data['isGroupChat'] ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
          : DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      settings: data['settings'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'participantIds': participantIds,
      'isGroupChat': isGroupChat,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'settings': settings,
    };
  }
}
