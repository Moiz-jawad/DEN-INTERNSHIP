// ignore_for_file: avoid_print

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:async';
import '../models/chat.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Database references
  late DatabaseReference _chatRoomsRef;
  late DatabaseReference _messagesRef;
  late DatabaseReference _userPresenceRef;
  late DatabaseReference _presenceRef;

  // Stream controllers for real-time updates
  final Map<String, StreamController<List<ChatRoom>>> _chatRoomsControllers =
      {};
  final Map<String, StreamController<List<ChatMessage>>> _messagesControllers =
      {};
  final Map<String, StreamController<List<UserPresence>>> _presenceControllers =
      {};
  final Map<String, StreamController<int>> _onlineUsersCountControllers = {};

  // Current user info
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName =>
      _auth.currentUser?.displayName ?? 'Unknown User';

  // Initialize the service
  void initialize() {
    _chatRoomsRef = _database.ref('chatRooms');
    _messagesRef = _database.ref('messages');
    _presenceRef = _database.ref('presence');
    _userPresenceRef = _database.ref('userPresence');

    // Wait for authentication to be ready before setting up presence
    _waitForAuthAndSetupPresence();
  }

  // Wait for authentication to be ready
  void _waitForAuthAndSetupPresence() {
    if (_auth.currentUser != null) {
      _setupPresenceMonitoring();
    } else {
      // Listen for auth state changes
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          _setupPresenceMonitoring();
        }
      });
    }
  }

  // Set up presence monitoring for the current user
  void _setupPresenceMonitoring() {
    final userId = currentUserId;
    if (userId == null) return;

    final userPresenceRef = _userPresenceRef.child(userId);

    // Set up presence state changes
    _database.ref('.info/connected').onValue.listen((event) {
      if (event.snapshot.value == true) {
        // App is connected to Firebase
        userPresenceRef.onDisconnect().update({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });
        _setUserOnline(userId);
      }
    });
  }

  // Set user as online
  Future<void> _setUserOnline(String userId) async {
    try {
      // Ensure user is authenticated
      if (_auth.currentUser == null) {
        print('User not authenticated, cannot set online status');
        return;
      }

      await _userPresenceRef.child(userId).set({
        'userId': userId,
        'userName': currentUserName ?? 'Unknown User',
        'isOnline': true,
        'lastSeen': ServerValue.timestamp,
        'status': 'Online',
      });
    } catch (e) {
      print('Error setting user online: $e');
      // Try alternative approach
      if (e.toString().contains('permission-denied')) {
        print('Permission denied, trying alternative approach...');
        await _tryAlternativePresenceSetup(userId);
      }
    }
  }

  // Alternative approach for setting presence
  Future<void> _tryAlternativePresenceSetup(String userId) async {
    try {
      // Try to update instead of set
      await _userPresenceRef.child(userId).update({
        'isOnline': true,
        'lastSeen': ServerValue.timestamp,
        'status': 'Online',
      });
      print('Alternative presence setup successful for: $userId');
    } catch (e) {
      print('Alternative presence setup also failed: $e');
    }
  }

  // Set user as offline
  Future<void> setUserOffline() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _userPresenceRef.child(userId).update({
        'isOnline': false,
        'lastSeen': ServerValue.timestamp,
        'status': 'Offline',
      });
    } catch (e) {
      print('Error setting user offline: $e');
    }
  }

  // Create a new chat room
  Future<String> createChatRoom({
    required String title,
    required List<String> participantIds,
    required bool isGroupChat,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Ensure current user is in participants
      if (!participantIds.contains(userId)) {
        participantIds.add(userId);
      }

      final chatRoomRef = _chatRoomsRef.push();
      final chatRoomId = chatRoomRef.key!;

      final chatRoomData = {
        'id': chatRoomId,
        'title': title,
        'participantIds': participantIds,
        'isGroupChat': isGroupChat,
        'createdAt': ServerValue.timestamp,
        'createdBy': userId,
        'lastActivity': ServerValue.timestamp,
        'lastMessageId': null,
        'lastMessageText': null,
        'lastMessageTime': null,
        'lastSenderId': null,
        'lastSenderName': null,
      };

      await chatRoomRef.set(chatRoomData);

      // Add participants to presence tracking
      for (final participantId in participantIds) {
        await _addParticipantToChat(chatRoomId, participantId);
      }

      return chatRoomId;
    } catch (e) {
      print('Error creating chat room: $e');
      rethrow;
    }
  }

  // Add participant to chat room
  Future<void> _addParticipantToChat(
    String chatRoomId,
    String participantId,
  ) async {
    try {
      await _chatRoomsRef
          .child(chatRoomId)
          .child('participants')
          .child(participantId)
          .set({'joinedAt': ServerValue.timestamp, 'isActive': true});
    } catch (e) {
      print('Error adding participant to chat: $e');
    }
  }

  // Get chat rooms for current user
  Stream<List<ChatRoom>> getChatRooms() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    if (!_chatRoomsControllers.containsKey(userId)) {
      _chatRoomsControllers[userId] =
          StreamController<List<ChatRoom>>.broadcast();
    }

    // Listen for chat rooms where user is a participant
    _chatRoomsRef.onValue.listen((event) async {
      if (event.snapshot.value == null) {
        _chatRoomsControllers[userId]?.add([]);
        return;
      }

      final List<ChatRoom> chatRooms = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        final chatRoomData = entry.value as Map<dynamic, dynamic>;
        final participantIds = List<String>.from(
          chatRoomData['participantIds'] ?? [],
        );

        if (participantIds.contains(userId)) {
          try {
            final chatRoom = ChatRoom.fromFirebase(
              Map<String, dynamic>.from(chatRoomData),
              entry.key,
            );
            chatRooms.add(chatRoom);
          } catch (e) {
            print('Error parsing chat room: $e');
          }
        }
      }

      // Sort by last activity (most recent first)
      chatRooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _chatRoomsControllers[userId]?.add(chatRooms);
    });

    return _chatRoomsControllers[userId]!.stream;
  }

  // Get messages for a chat room
  Stream<List<ChatMessage>> getMessages(String chatRoomId) {
    if (!_messagesControllers.containsKey(chatRoomId)) {
      _messagesControllers[chatRoomId] =
          StreamController<List<ChatMessage>>.broadcast();
    }

    _messagesRef.child(chatRoomId).onValue.listen((event) {
      if (event.snapshot.value == null) {
        _messagesControllers[chatRoomId]?.add([]);
        return;
      }

      final List<ChatMessage> messages = [];
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      for (final entry in data.entries) {
        try {
          final message = ChatMessage.fromFirebase(
            Map<String, dynamic>.from(entry.value),
            entry.key,
          );
          messages.add(message);
        } catch (e) {
          print('Error parsing message: $e');
        }
      }

      // Sort by timestamp (oldest first)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      _messagesControllers[chatRoomId]?.add(messages);
    });

    return _messagesControllers[chatRoomId]!.stream;
  }

  // Send a message
  Future<void> sendMessage({
    required String chatRoomId,
    required String message,
    MessageType type = MessageType.text,
    String? replyToId,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = currentUserId;
      final userName = currentUserName;

      if (userId == null || userName == null) {
        throw Exception('User not authenticated');
      }

      final messageRef = _messagesRef.child(chatRoomId).push();
      final messageId = messageRef.key!;

      final messageData = {
        'id': messageId,
        'senderId': userId,
        'senderName': userName,
        'message': message,
        'timestamp': ServerValue.timestamp,
        'type': type.toString().split('.').last,
        'replyToId': replyToId,
        'imageUrl': imageUrl,
        'metadata': metadata,
      };

      await messageRef.set(messageData);

      // Update chat room with last message info
      await _chatRoomsRef.child(chatRoomId).update({
        'lastActivity': ServerValue.timestamp,
        'lastMessageId': messageId,
        'lastMessageText': type == MessageType.image ? '📷 Image' : message,
        'lastMessageTime': ServerValue.timestamp,
        'lastSenderId': userId,
        'lastSenderName': userName,
      });

      // Update participant's last seen
      await _updateParticipantLastSeen(chatRoomId, userId);
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Upload image and send image message
  Future<void> sendImageMessage(String chatRoomId, File imageFile) async {
    final userId = currentUserId;
    final userName = currentUserName;
    if (userId == null || userName == null) return;

    try {
      // For now, we'll use a placeholder image URL
      // In a real app, you'd upload to Firebase Storage and get the URL
      final imageUrl = await _uploadImageToStorage(imageFile);

      await sendMessage(
        chatRoomId: chatRoomId,
        message: '📷 Image',
        imageUrl: imageUrl,
        type: MessageType.image,
      );
    } catch (e) {
      print('Error sending image message: $e');
    }
  }

  // Upload image to storage (placeholder implementation)
  Future<String> _uploadImageToStorage(File imageFile) async {
    // TODO: Implement actual Firebase Storage upload
    // For now, return a placeholder URL
    await Future.delayed(const Duration(seconds: 1)); // Simulate upload
    return 'https://via.placeholder.com/300x300/4CAF50/FFFFFF?text=Image';
  }

  // Update participant's last seen
  Future<void> _updateParticipantLastSeen(
    String chatRoomId,
    String participantId,
  ) async {
    try {
      await _chatRoomsRef
          .child(chatRoomId)
          .child('participants')
          .child(participantId)
          .update({'lastSeen': ServerValue.timestamp});
    } catch (e) {
      print('Error updating participant last seen: $e');
    }
  }

  // Get user presence for a chat room
  Stream<List<UserPresence>> getUserPresence(String chatRoomId) {
    if (!_presenceControllers.containsKey(chatRoomId)) {
      _presenceControllers[chatRoomId] =
          StreamController<List<UserPresence>>.broadcast();
    }

    // Get participant IDs first
    _chatRoomsRef.child(chatRoomId).child('participantIds').onValue.listen((
      event,
    ) async {
      if (event.snapshot.value == null) {
        _presenceControllers[chatRoomId]?.add([]);
        return;
      }

      final List<String> participantIds = [];
      if (event.snapshot.value is List) {
        participantIds.addAll((event.snapshot.value as List).cast<String>());
      } else if (event.snapshot.value is Map) {
        participantIds.addAll(
          (event.snapshot.value as Map).keys.cast<String>(),
        );
      }

      // Get presence for each participant
      final List<UserPresence> presences = [];
      for (final participantId in participantIds) {
        try {
          final presenceSnapshot = await _userPresenceRef
              .child(participantId)
              .get();
          if (presenceSnapshot.exists) {
            final presenceData =
                presenceSnapshot.value as Map<dynamic, dynamic>;
            final presence = UserPresence.fromFirebase(
              Map<String, dynamic>.from(presenceData),
              participantId,
            );
            presences.add(presence);
          }
        } catch (e) {
          print('Error getting presence for user $participantId: $e');
        }
      }

      _presenceControllers[chatRoomId]?.add(presences);
    });

    return _presenceControllers[chatRoomId]!.stream;
  }

  // Get online users count for a chat room
  Stream<int> getOnlineUsersCount(String chatRoomId) {
    if (!_onlineUsersCountControllers.containsKey(chatRoomId)) {
      _onlineUsersCountControllers[chatRoomId] =
          StreamController<int>.broadcast();
    }

    return getUserPresence(chatRoomId).map((presences) {
      return presences.where((presence) => presence.isOnline).length;
    });
  }

  // Mark message as read
  Future<void> markMessageAsRead(String chatRoomId, String messageId) async {
    try {
      await _messagesRef
          .child(chatRoomId)
          .child(messageId)
          .child('readBy')
          .child(currentUserId!)
          .set(ServerValue.timestamp);
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    try {
      await _messagesRef.child(chatRoomId).child(messageId).remove();
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  // Leave chat room
  Future<void> leaveChatRoom(String chatRoomId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      // Remove user from participants
      await _chatRoomsRef
          .child(chatRoomId)
          .child('participantIds')
          .child(userId)
          .remove();

      // Remove from participants list
      await _chatRoomsRef
          .child(chatRoomId)
          .child('participants')
          .child(userId)
          .remove();
    } catch (e) {
      print('Error leaving chat room: $e');
    }
  }

  // Update user status
  Future<void> updateUserStatus(String status) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      await _userPresenceRef.child(userId).update({
        'status': status,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating user status: $e');
    }
  }

  // Test database connection
  Future<bool> testDatabaseConnection() async {
    try {
      final testRef = _database.ref('test');
      await testRef.set({
        'test': 'connection_test',
        'timestamp': ServerValue.timestamp,
      });
      await testRef.remove();
      print('Database connection test successful');
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }

  // Test authentication and permissions
  Future<bool> testAuthenticationAndPermissions() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('User not authenticated');
        return false;
      }

      // Test writing to userPresence
      await _userPresenceRef.child(userId).update({
        'test': 'permission_test',
        'timestamp': ServerValue.timestamp,
      });

      print('Authentication and permissions test successful');
      return true;
    } catch (e) {
      print('Authentication and permissions test failed: $e');
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    for (final controller in _chatRoomsControllers.values) {
      controller.close();
    }
    for (final controller in _messagesControllers.values) {
      controller.close();
    }
    for (final controller in _presenceControllers.values) {
      controller.close();
    }
    for (final controller in _onlineUsersCountControllers.values) {
      controller.close();
    }
    _chatRoomsControllers.clear();
    _messagesControllers.clear();
    _presenceControllers.clear();
    _onlineUsersCountControllers.clear();
  }
}
