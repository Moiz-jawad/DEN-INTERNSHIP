import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthProviders with ChangeNotifier {
  final AuthService authService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  AuthProviders(this.authService) {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signUp(String name, String email, String password) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    _user = userCred.user;

    // Store profile in Firestore
    await _firestore.collection('users').doc(_user!.uid).set({
      'name': name,
      'email': email,
    });

    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _user = userCred.user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
