// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current Firebase user
  static User? get currentUser => _auth.currentUser;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  static Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? avatarUrl,
  }) async {
    try {
      print('Attempting to create user with email: $email, name: $name');

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('User created successfully: ${userCredential.user!.uid}');
      print('Firebase Auth current user: ${_auth.currentUser?.uid}');

      // Set the user's display name in Firebase Auth
      await userCredential.user!.updateDisplayName(name);

      // Create user profile in Firestore
      final user = app_user.User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        quizHistory: [],
        tasksCount: 0,
      );

      // Use set with merge to ensure the document is created properly
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toJson(), SetOptions(merge: true));

      print('User registration completed successfully: $name');
      print('Firebase Auth display name set to: $name');
      print(
        'Firestore user document created with ID: ${userCredential.user!.uid}',
      );

      return userCredential;
    } catch (e) {
      print('Error during user registration: $e');
      throw _handleAuthError(e);
    }
  }

  // Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting to sign in with email: $email');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Sign in successful for user: ${userCredential.user!.uid}');
      print('Firebase Auth current user: ${_auth.currentUser?.uid}');

      // After successful sign-in, ensure the user has a proper profile
      await _ensureUserProfileAfterSignIn(userCredential.user!);

      print('User profile ensured, returning credential');
      return userCredential;
    } catch (e) {
      print('Sign in failed: $e');
      throw _handleAuthError(e);
    }
  }

  // Ensure user has a proper profile after sign-in
  static Future<void> _ensureUserProfileAfterSignIn(User firebaseUser) async {
    try {
      // First, try to get existing user profile from Firestore
      final userProfile = await getUserProfile(firebaseUser.uid);

      if (userProfile != null) {
        // User has a profile, update Firebase Auth display name if needed
        if (firebaseUser.displayName != userProfile.name &&
            userProfile.name.isNotEmpty) {
          await firebaseUser.updateDisplayName(userProfile.name);
          print('Updated Firebase Auth display name to: ${userProfile.name}');
        }
      } else {
        // User doesn't have a profile, create one with email as fallback name
        final fallbackName = _generateFallbackName(
          firebaseUser.email ?? 'User',
        );

        // Create user profile in Firestore
        final newUser = app_user.User(
          id: firebaseUser.uid,
          name: fallbackName,
          email: firebaseUser.email ?? '',
          avatarUrl: firebaseUser.photoURL,
          quizHistory: [],
          tasksCount: 0,
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toJson());

        // Set the display name in Firebase Auth
        await firebaseUser.updateDisplayName(fallbackName);

        print('Created new user profile with fallback name: $fallbackName');
        print('Note: User should update their name in profile settings');
      }
    } catch (e) {
      print('Error ensuring user profile after sign-in: $e');
      // Don't throw here as this is not critical for login
    }
  }

  // Generate a fallback name from email
  static String _generateFallbackName(String email) {
    if (email.isEmpty || email == 'User') return 'User';

    // Extract username part from email (before @)
    final username = email.split('@').first;
    if (username.isNotEmpty) {
      // Capitalize first letter and return
      return username[0].toUpperCase() + username.substring(1);
    }

    return 'User';
  }

  // Update user's display name in Firebase Auth from their Firestore profile
  static Future<void> _updateUserDisplayName(User firebaseUser) async {
    try {
      // Get user profile from Firestore
      final userProfile = await getUserProfile(firebaseUser.uid);
      if (userProfile != null && userProfile.name.isNotEmpty) {
        // Only update if the display name is different
        if (firebaseUser.displayName != userProfile.name) {
          await firebaseUser.updateDisplayName(userProfile.name);
          print('Updated Firebase Auth display name to: ${userProfile.name}');
        }
      }
    } catch (e) {
      print('Error updating user display name: $e');
      // Don't throw here as this is not critical for login
    }
  }

  // Ensure user's display name is synchronized between Firebase Auth and Firestore
  static Future<void> ensureDisplayNameSync(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await _updateUserDisplayName(currentUser);
      }
    } catch (e) {
      print('Error ensuring display name sync: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user profile from Firestore
  static Future<app_user.User?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return app_user.User.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

      // Use set with merge to create document if it doesn't exist
      await _firestore
          .collection('users')
          .doc(userId)
          .set(updates, SetOptions(merge: true));

      // Update Firebase Auth display name if name was changed
      if (name != null) {
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == userId) {
          await currentUser.updateDisplayName(name);
          print('Updated Firebase Auth display name to: $name');
        }
      }
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile');
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Delete user account
  static Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Delete Firebase user
        await user.delete();
      }
    } catch (e) {
      print('Error deleting user account: $e');
      throw Exception('Failed to delete account');
    }
  }

  // Handle Firebase Auth errors
  static String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred.';
  }
}
