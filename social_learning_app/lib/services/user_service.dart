// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  auth.User? get currentUser => _auth.currentUser;

  // Get all users (excluding current user)
  Stream<List<User>> getAllUsers() {
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .where('id', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => User.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  // Get users by IDs
  Future<List<User>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      return querySnapshot.docs
          .map((doc) => User.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching users by IDs: $e');
      return [];
    }
  }

  // Search users by name or email
  Stream<List<User>> searchUsers(String query) {
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    if (query.isEmpty) return getAllUsers();

    return _firestore
        .collection('users')
        .where('id', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => User.fromFirestore(doc.data(), doc.id))
              .where(
                (user) =>
                    (user.name?.toLowerCase().contains(query.toLowerCase()) ??
                        false) ||
                    (user.email?.toLowerCase().contains(query.toLowerCase()) ??
                        false),
              )
              .toList();
        });
  }

  // Get current user profile
  Future<User?> getCurrentUserProfile() async {
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        return User.fromFirestore(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error fetching current user profile: $e');
    }

    // Fallback to auth data if Firestore doesn't have profile
    final authUser = currentUser;
    if (authUser != null) {
      return User.fromAuth({
        'displayName': authUser.displayName,
        'email': authUser.email,
        'photoURL': authUser.photoURL,
      }, authUser.uid);
    }

    return null;
  }

  // Update current user profile
  Future<void> updateCurrentUserProfile({
    String? name,
    String? photoUrl,
  }) async {
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(currentUserId).update(updates);
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  // Create user profile if it doesn't exist
  Future<void> createUserProfileIfNotExists() async {
    final currentUserId = currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      if (!doc.exists) {
        final authUser = currentUser;
        if (authUser != null) {
          await _firestore.collection('users').doc(currentUserId).set({
            'name': authUser.displayName ?? 'Unknown User',
            'email': authUser.email ?? '',
            'photoUrl': authUser.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }
}
