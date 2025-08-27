// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../firebase_options.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Configure Firestore settings for better performance
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Enable offline persistence
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );

      // Configure Realtime Database settings
      FirebaseDatabase.instance.setLoggingEnabled(
        true,
      ); // Enable logging for debugging

      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  // Get Firestore instance
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // Get Realtime Database instance
  static FirebaseDatabase get database => FirebaseDatabase.instance;

  // Get Auth instance
  static FirebaseAuth get auth => FirebaseAuth.instance;

  // Check if Firebase is initialized
  static bool get isInitialized => Firebase.apps.isNotEmpty;

  // Get current user ID
  static String? get currentUserId => auth.currentUser?.uid;

  // Ensure user is authenticated
  static bool get isAuthenticated => auth.currentUser != null;

  // Get user document reference
  static DocumentReference<Map<String, dynamic>> getUserDocument(
    String userId,
  ) {
    return firestore.collection('users').doc(userId);
  }

  // Get user tasks collection reference
  static CollectionReference<Map<String, dynamic>> getUserTasksCollection(
    String userId,
  ) {
    return firestore.collection('users').doc(userId).collection('tasks');
  }
}
