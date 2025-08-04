import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthViewModel with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _userName;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  String? get userName => _userName;
  String? get userEmail => _user?.email;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  AuthViewModel() {
    _auth.authStateChanges().listen((user) async {
      _user = user;
      if (_user != null) {
        await _loadUserProfile();
      } else {
        _userName = null;
      }
      notifyListeners();
    });
  }

  // Register user and save profile
  Future<void> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = result.user;

      await _firestore.collection('users').doc(_user!.uid).set({
        'name': name,
        'email': email,
      });

      _userName = name;
      _setError(null);
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Registration failed');
    } catch (e) {
      _setError('Something went wrong: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Login user and load profile
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;
      await _loadUserProfile();
      _setError(null);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Login failed');
      return false;
    } catch (e) {
      _setError('Something went wrong: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userName = data['name'] ?? '';
      } else {
        _userName = null;
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _userName = null;
    }
  }

  // Manually fetch profile if needed
  Future<void> fetchUserProfile() async {
    if (_user == null) return;
    await _loadUserProfile();
    notifyListeners();
  }

  // Refresh from Firestore
  Future<void> refreshUserProfile() async {
    if (_user != null) {
      await _loadUserProfile();
      notifyListeners();
    }
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _userName = null;
    notifyListeners();
  }

  // Set error
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
