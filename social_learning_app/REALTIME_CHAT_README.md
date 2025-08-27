# Real-Time Group Chat Implementation

This document describes the implementation of a production-level real-time group chat system using Firebase Realtime Database with online/offline status tracking.

## Features

### ✅ Core Chat Features

- **Real-time messaging** using Firebase Realtime Database
- **Group chat support** with multiple participants
- **Direct messaging** between users
- **Message persistence** and real-time synchronization
- **Message types**: Text, Images (bonus feature)

### ✅ Online/Offline Status

- **Real-time presence tracking** for all users
- **Automatic online/offline detection** using Firebase connection state
- **Last seen timestamps** for offline users
- **Visual indicators** showing who's currently online
- **Online user count** display

### ✅ Production-Level Features

- **Efficient data structure** optimized for real-time updates
- **Automatic cleanup** of disconnected users
- **Error handling** and graceful degradation
- **Resource management** with proper disposal
- **Scalable architecture** supporting multiple chat rooms

## Architecture

### Database Structure

```
firebase-realtime-database/
├── chatRooms/
│   ├── {chatRoomId}/
│   │   ├── title: "Chat Room Name"
│   │   ├── participantIds: ["user1", "user2", "user3"]
│   │   ├── isGroupChat: true
│   │   ├── createdAt: timestamp
│   │   ├── createdBy: "userId"
│   │   ├── lastActivity: timestamp
│   │   ├── lastMessageId: "messageId"
│   │   ├── lastMessageText: "Last message content"
│   │   ├── lastMessageTime: timestamp
│   │   ├── lastSenderId: "userId"
│   │   ├── lastSenderName: "User Name"
│   │   └── participants/
│   │       ├── {userId}/
│   │       │   ├── joinedAt: timestamp
│   │       │   ├── isActive: true
│   │       │   └── lastSeen: timestamp
├── messages/
│   ├── {chatRoomId}/
│   │   ├── {messageId}/
│   │   │   ├── id: "messageId"
│   │   │   ├── senderId: "userId"
│   │   │   ├── senderName: "User Name"
│   │   │   ├── message: "Message content"
│   │   │   ├── timestamp: timestamp
│   │   │   ├── type: "text"
│   │   │   ├── replyToId: "messageId" (optional)
│   │   │   ├── imageUrl: "url" (optional)
│   │   │   ├── metadata: {} (optional)
│   │   │   └── readBy/
│   │   │       ├── {userId}: timestamp
└── userPresence/
    ├── {userId}/
    │   ├── userId: "userId"
    │   ├── userName: "User Name"
    │   ├── isOnline: true
    │   ├── lastSeen: timestamp
    │   └── status: "Online"
```

### Key Components

1. **ChatService** (`lib/services/chat_service.dart`)

   - Handles all Firebase Realtime Database operations
   - Manages real-time streams and listeners
   - Implements presence tracking and online/offline status

2. **ChatProvider** (`lib/providers/chat_provider.dart`)

   - State management using Provider pattern
   - Coordinates between UI and service layer
   - Manages chat rooms, messages, and user presence

3. **RealTimeChatScreen** (`lib/screens/real_time_chat_screen.dart`)

   - Main chat interface with modern UI
   - Real-time message display
   - Online/offline status indicators

4. **Models** (`lib/models/chat.dart`)
   - Data models for chat rooms, messages, and user presence
   - Firebase serialization/deserialization
   - Type-safe message handling

## Implementation Details

### Real-Time Updates

The system uses Firebase Realtime Database's `onValue` listeners to provide real-time updates:

```dart
// Listen to chat rooms
_chatRoomsRef
    .orderByChild('lastActivity')
    .onValue
    .map((event) => /* process data */);

// Listen to messages
_messagesRef
    .child(chatRoomId)
    .orderByChild('timestamp')
    .onValue
    .listen((event) => /* process messages */);

// Listen to user presence
_userPresenceRef
    .child(userId)
    .onValue
    .listen((event) => /* process presence */);
```

### Presence Tracking

Online/offline status is automatically managed:

```dart
// Set up presence monitoring
_database.ref('.info/connected').onValue.listen((event) {
  if (event.snapshot.value == true) {
    // App is connected
    userPresenceRef.onDisconnect().update({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });
    _setUserOnline(userId);
  }
});
```

### Message Handling

Messages are sent and received in real-time:

```dart
// Send message
Future<void> sendMessage({
  required String chatRoomId,
  required String message,
  MessageType type = MessageType.text,
}) async {
  final messageRef = _messagesRef.child(chatRoomId).push();
  await messageRef.set({
    'id': messageRef.key,
    'senderId': currentUserId,
    'senderName': currentUserName,
    'message': message,
    'timestamp': ServerValue.timestamp,
    'type': type.toString().split('.').last,
  });

  // Update chat room last message info
  await _chatRoomsRef.child(chatRoomId).update({
    'lastActivity': ServerValue.timestamp,
    'lastMessageId': messageRef.key,
    'lastMessageText': message,
    'lastMessageTime': ServerValue.timestamp,
    'lastSenderId': currentUserId,
    'lastSenderName': currentUserName,
  });
}
```

## Usage

### Creating a Chat Room

```dart
final chatProvider = context.read<ChatProvider>();
final chatRoomId = await chatProvider.createChatRoom(
  title: 'Study Group',
  participantIds: ['user1', 'user2', 'user3'],
  isGroupChat: true,
);
```

### Sending Messages

```dart
await chatProvider.sendMessage(
  message: 'Hello everyone!',
  type: MessageType.text,
);
```

### Monitoring Online Status

```dart
Consumer<ChatProvider>(
  builder: (context, chatProvider, child) {
    return Text('${chatProvider.onlineUsersCount} online');
  },
)
```

## Security Rules

For production use, implement proper Firebase Security Rules:

```json
{
  "rules": {
    "chatRooms": {
      "$chatRoomId": {
        ".read": "data.child('participantIds').hasChild(auth.uid)",
        ".write": "data.child('participantIds').hasChild(auth.uid)"
      }
    },
    "messages": {
      "$chatRoomId": {
        ".read": "root.child('chatRooms').child($chatRoomId).child('participantIds').hasChild(auth.uid)",
        ".write": "root.child('chatRooms').child($chatRoomId).child('participantIds').hasChild(auth.uid)"
      }
    },
    "userPresence": {
      "$userId": {
        ".read": "auth.uid == $userId",
        ".write": "auth.uid == $userId"
      }
    }
  }
}
```

## Performance Considerations

1. **Efficient Queries**: Use `orderByChild` and `limitToLast` for large message lists
2. **Pagination**: Implement message pagination for very active chats
3. **Offline Support**: Enable persistence for offline message viewing
4. **Memory Management**: Properly dispose of listeners and controllers

## Testing

### Manual Testing

1. Create multiple chat rooms
2. Send messages between different users
3. Test online/offline status changes
4. Verify real-time updates across devices

### Automated Testing

```dart
test('should create chat room successfully', () async {
  final chatService = ChatService();
  final chatRoomId = await chatService.createChatRoom(
    title: 'Test Room',
    participantIds: ['user1'],
    isGroupChat: false,
  );
  expect(chatRoomId, isNotNull);
});
```

## Future Enhancements

1. **Push Notifications**: Implement FCM for message notifications
2. **File Sharing**: Support for documents, videos, and other file types
3. **Message Reactions**: Like, heart, and other reaction emojis
4. **Message Search**: Full-text search across chat history
5. **Voice Messages**: Audio recording and playback
6. **Video Calls**: Integration with WebRTC or similar technology

## Troubleshooting

### Common Issues

1. **Messages not appearing**: Check Firebase connection and security rules
2. **Online status not updating**: Verify presence monitoring setup
3. **Performance issues**: Implement pagination and limit message loading
4. **Memory leaks**: Ensure proper disposal of listeners and controllers

### Debug Mode

Enable Firebase logging for debugging:

```dart
FirebaseDatabase.instance.setLoggingEnabled(true);
```

## Conclusion

This implementation provides a robust, scalable real-time chat system suitable for production use. The architecture ensures efficient real-time updates while maintaining good performance and user experience. The online/offline status tracking provides users with immediate feedback about who's available for conversation.
