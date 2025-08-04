// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/auth_foam.dart'; // Make sure this file uses 'AuthFoam'

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  var _isLoading = false;

  Future<void> _submitAuthForm(
    String email,
    String password,
    String username,
    bool isLogin,
    BuildContext ctx,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });

      UserCredential authResult;

      if (isLogin) {
        authResult = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final userId = authResult.user!.uid;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'lastLogin': DateTime.now().toIso8601String(),
        });

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final fetchedUsername = userDoc.data()?['name'] ?? 'Unknown User';
        print('Logged in as: $fetchedUsername');
      } else {
        authResult = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final userId = authResult.user!.uid;

        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'email': email,
          'name': username.isNotEmpty ? username : 'Unknown User',
          'lastLogin': DateTime.now().toIso8601String(),
        });

        print(
          'User registered with name: ${username.isNotEmpty ? username : "Unknown User"}',
        );
      }
    } on PlatformException catch (err) {
      var message = 'An error occurred, please check your credentials!';
      if (err.message != null) {
        message = err.message!;
      }

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(ctx).colorScheme.error,
        ),
      );
    } catch (err) {
      print(err);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Text('Authentication failed!'),
          backgroundColor: Theme.of(ctx).colorScheme.error,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthFoam(_submitAuthForm, _isLoading),
    );
  }
}
