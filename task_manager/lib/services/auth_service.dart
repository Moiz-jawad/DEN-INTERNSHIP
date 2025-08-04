import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await updateLastLogin(result.user!.uid);
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(name);

      // Save user profile data to Firestore
      if (result.user != null) {
        await _saveUserProfile(result.user!.uid, name, email);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Save user profile to Firestore
  Future<void> _saveUserProfile(String uid, String name, String email) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'loginCount': 1,
      });
    } catch (e) {
      throw 'Failed to save user profile: $e';
    }
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw 'Failed to get user profile: $e';
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update user profile: $e';
    }
  }

  // Update last login timestamp and increment login count
  Future<void> updateLastLogin(String uid) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      int currentCount = (doc.data()?['loginCount'] ?? 0) as int;

      await docRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'loginCount': currentCount + 1,
        'isActive': true,
      });
    } catch (e) {
      print('Failed to update last login: $e');
    }
  }

  // Update user activity status
  Future<void> updateUserActivity(String uid, bool isActive) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isActive': isActive,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to update user activity: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final user = currentUser;
      if (user != null) {
        await updateUserActivity(user.uid, false);
      }
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out: $e';
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
    } catch (e) {
      throw 'Failed to delete account: $e';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
