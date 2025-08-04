// ignore_for_file: prefer_final_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  String? _userName;
  String? _userEmail;

  String? get userName => _userName;
  String? get userEmail => _userEmail;

  final CollectionReference _dbRef =
      FirebaseFirestore.instance.collection('users');

  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Load user profile from Firestore or fallback to FirebaseAuth
  Future<void> loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      final doc = await _dbRef.doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        _userName = data['name'] ?? '';
        _userEmail = data['email'] ?? '';
        _userProfile = data;

        notifyListeners();
      } else {
        // fallback to FirebaseAuth data if document doesn't exist
        _userName = user.displayName ?? 'Unknown User';
        _userEmail = user.email ?? 'no-email@example.com';
        _userProfile = {
          'name': _userName!,
          'email': _userEmail!,
          'lastLogin': DateTime.now().toIso8601String(),
        };

        // Optionally save fallback to Firestore
        await _dbRef.doc(user.uid).set(_userProfile!);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  void clearUserProfile() {
    _userProfile = null;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }
}
