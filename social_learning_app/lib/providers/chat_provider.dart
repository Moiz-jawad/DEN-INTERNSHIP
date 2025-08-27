// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import '../models/chat.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  // Chat rooms
  List<ChatRoom> _chatRooms = [];
  List<ChatRoom> get chatRooms => _chatRooms;

  // Current chat room
  ChatRoom? _currentChatRoom;
  ChatRoom? get currentChatRoom => _currentChatRoom;

  // Messages for current chat room
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // User presence for current chat room
  List<UserPresence> _userPresences = [];
  List<UserPresence> get userPresences => _userPresences;

  // Online users count
  int _onlineUsersCount = 0;
  int get onlineUsersCount => _onlineUsersCount;

  // Loading states
  bool _isLoadingChatRooms = false;
  bool _isLoadingMessages = false;
  bool _isLoadingPresence = false;

  bool get isLoadingChatRooms => _isLoadingChatRooms;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isLoadingPresence => _isLoadingPresence;

  // Stream subscriptions
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<List<UserPresence>>? _presenceSubscription;
  StreamSubscription<int>? _onlineUsersCountSubscription;

  // Initialize the provider
  void initialize() {
    _chatService.initialize();
    _loadChatRooms();
  }

  // Load chat rooms
  void _loadChatRooms() {
    _isLoadingChatRooms = true;
    notifyListeners();

    _chatRoomsSubscription?.cancel();
    _chatRoomsSubscription = _chatService.getChatRooms().listen(
      (chatRooms) {
        _chatRooms = chatRooms;
        _isLoadingChatRooms = false;
        notifyListeners();
      },
      onError: (error) {
        print('Error loading chat rooms: $error');
        _isLoadingChatRooms = false;
        notifyListeners();
      },
    );
  }

  // Create a new chat room
  Future<String?> createChatRoom({
    required String title,
    required List<String> participantIds,
    required bool isGroupChat,
  }) async {
    try {
      final chatRoomId = await _chatService.createChatRoom(
        title: title,
        participantIds: participantIds,
        isGroupChat: isGroupChat,
      );

      // Refresh chat rooms
      _loadChatRooms();

      return chatRoomId;
    } catch (e) {
      print('Error creating chat room: $e');
      return null;
    }
  }

  // Select a chat room
  void selectChatRoom(ChatRoom chatRoom) {
    _currentChatRoom = chatRoom;
    _loadMessages(chatRoom.id);
    _loadUserPresence(chatRoom.id);
    _loadOnlineUsersCount(chatRoom.id);
    notifyListeners();
  }

  // Load messages for a chat room
  void _loadMessages(String chatRoomId) {
    _isLoadingMessages = true;
    notifyListeners();

    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService
        .getMessages(chatRoomId)
        .listen(
          (messages) {
            _messages = messages;
            _isLoadingMessages = false;
            notifyListeners();
          },
          onError: (error) {
            print('Error loading messages: $error');
            _isLoadingMessages = false;
            notifyListeners();
          },
        );
  }

  // Load user presence for a chat room
  void _loadUserPresence(String chatRoomId) {
    _isLoadingPresence = true;
    notifyListeners();

    _presenceSubscription?.cancel();
    _presenceSubscription = _chatService
        .getUserPresence(chatRoomId)
        .listen(
          (presences) {
            _userPresences = presences;
            _isLoadingPresence = false;
            notifyListeners();
          },
          onError: (error) {
            print('Error loading user presence: $error');
            _isLoadingPresence = false;
            notifyListeners();
          },
        );
  }

  // Load online users count
  void _loadOnlineUsersCount(String chatRoomId) {
    _onlineUsersCountSubscription?.cancel();
    _onlineUsersCountSubscription = _chatService
        .getOnlineUsersCount(chatRoomId)
        .listen(
          (count) {
            _onlineUsersCount = count;
            notifyListeners();
          },
          onError: (error) {
            print('Error loading online users count: $error');
          },
        );
  }

  // Send a message
  Future<void> sendMessage({
    required String message,
    MessageType type = MessageType.text,
    String? replyToId,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentChatRoom == null) return;

    try {
      await _chatService.sendMessage(
        chatRoomId: _currentChatRoom!.id,
        message: message,
        type: type,
        replyToId: replyToId,
        imageUrl: imageUrl,
        metadata: metadata,
      );
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Send an image message
  Future<void> sendImageMessage(File imageFile) async {
    if (_currentChatRoom == null) return;

    try {
      await _chatService.sendImageMessage(_currentChatRoom!.id, imageFile);
    } catch (e) {
      print('Error sending image message: $e');
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    if (_currentChatRoom == null) return;

    try {
      await _chatService.markMessageAsRead(_currentChatRoom!.id, messageId);
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    if (_currentChatRoom == null) return;

    try {
      await _chatService.deleteMessage(_currentChatRoom!.id, messageId);
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  // Leave chat room
  Future<void> leaveChatRoom() async {
    if (_currentChatRoom == null) return;

    try {
      await _chatService.leaveChatRoom(_currentChatRoom!.id);

      // Clear current chat room
      _currentChatRoom = null;
      _messages.clear();
      _userPresences.clear();
      _onlineUsersCount = 0;

      // Refresh chat rooms
      _loadChatRooms();

      notifyListeners();
    } catch (e) {
      print('Error leaving chat room: $e');
    }
  }

  // Update user status
  Future<void> updateUserStatus(String status) async {
    try {
      await _chatService.updateUserStatus(status);
    } catch (e) {
      print('Error updating user status: $e');
    }
  }

  // Get user presence by ID
  UserPresence? getUserPresence(String userId) {
    try {
      return _userPresences.firstWhere((presence) => presence.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Check if user is online
  bool isUserOnline(String userId) {
    final presence = getUserPresence(userId);
    return presence?.isOnline ?? false;
  }

  // Get chat room by ID
  ChatRoom? getChatRoomById(String chatRoomId) {
    try {
      return _chatRooms.firstWhere((room) => room.id == chatRoomId);
    } catch (e) {
      return null;
    }
  }

  // Clear current chat room
  void clearCurrentChatRoom() {
    _currentChatRoom = null;
    _messages.clear();
    _userPresences.clear();
    _onlineUsersCount = 0;
    notifyListeners();
  }

  // Refresh chat rooms
  void refreshChatRooms() {
    _loadChatRooms();
  }

  // Test database connection and permissions
  Future<void> testDatabaseSetup() async {
    print('Testing database setup...');

    // Test basic connection
    final connectionTest = await _chatService.testDatabaseConnection();
    if (!connectionTest) {
      print('❌ Database connection failed');
      return;
    }
    print('✅ Database connection successful');

    // Test authentication and permissions
    final authTest = await _chatService.testAuthenticationAndPermissions();
    if (!authTest) {
      print('❌ Authentication and permissions test failed');
      return;
    }
    print('✅ Authentication and permissions test successful');

    print('🎉 All database tests passed!');
  }

  // Dispose resources
  @override
  void dispose() {
    _chatRoomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _presenceSubscription?.cancel();
    _onlineUsersCountSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }
}
