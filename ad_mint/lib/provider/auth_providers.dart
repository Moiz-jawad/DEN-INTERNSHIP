import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  try {
    return FirebaseAuth.instance;
  } catch (_) {
    return null; // offline or Firebase not configured
  }
});

final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) {
    // Provide a null stream in fallback mode
    return const Stream.empty();
  }
  return auth.authStateChanges();
});

class AuthController {
  AuthController(this._auth);
  final FirebaseAuth? _auth;

  Future<User?> signIn(String email, String password) async {
    if (_auth == null) return null;
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> register(String email, String password) async {
    if (_auth == null) return null;
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  Future<User?> signInAnonymously() async {
    if (_auth == null) return null;
    final cred = await _auth.signInAnonymously();
    return cred.user;
  }

  Future<void> signOut() async {
    if (_auth == null) return;
    await _auth.signOut();
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(firebaseAuthProvider));
});
