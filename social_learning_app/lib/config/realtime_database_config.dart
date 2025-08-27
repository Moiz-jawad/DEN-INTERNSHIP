// ignore_for_file: avoid_print

import 'package:firebase_database/firebase_database.dart';

class RealtimeDatabaseConfig {
  static void initialize() {
    final database = FirebaseDatabase.instance;

    // Enable logging for debugging (remove in production)
    database.setLoggingEnabled(true);

    // Set database URL if needed (usually not required for default project)
    // database.databaseURL = 'https://your-project-id.firebaseio.com';

    // Configure persistence
    database.setPersistenceEnabled(true);

    // Set cache size
    database.setPersistenceCacheSizeBytes(100 * 1024 * 1024); // 100MB

    print('Firebase Realtime Database configured successfully');
  }

  // Get database reference with proper path
  static DatabaseReference getDatabaseRef(String path) {
    return FirebaseDatabase.instance.ref(path);
  }

  // Get chat rooms reference
  static DatabaseReference getChatRoomsRef() {
    return getDatabaseRef('chatRooms');
  }

  // Get messages reference
  static DatabaseReference getMessagesRef() {
    return getDatabaseRef('messages');
  }

  // Get user presence reference
  static DatabaseReference getUserPresenceRef() {
    return getDatabaseRef('userPresence');
  }

  // Get presence reference
  static DatabaseReference getPresenceRef() {
    return getDatabaseRef('presence');
  }
}
