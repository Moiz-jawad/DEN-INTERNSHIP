// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_service.dart';
import '../../providers/app_state.dart';
import '../onboarding/onboarding_screen.dart';
import 'login_screen.dart';
import '../main_screen.dart';

class EnhancedAuthWrapper extends StatefulWidget {
  const EnhancedAuthWrapper({super.key});

  @override
  State<EnhancedAuthWrapper> createState() => _EnhancedAuthWrapperState();
}

class _EnhancedAuthWrapperState extends State<EnhancedAuthWrapper> {
  bool _isLoading = true;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final completed = await OnboardingService.isOnboardingCompleted();
      if (mounted) {
        setState(() {
          _onboardingCompleted = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If there's an error, assume onboarding is not completed
      if (mounted) {
        setState(() {
          _onboardingCompleted = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    // Show onboarding if not completed
    if (!_onboardingCompleted) {
      return OnboardingScreen(
        onOnboardingComplete: () {
          setState(() {
            _onboardingCompleted = true;
          });
        },
      );
    }

    // Check authentication state
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking authentication...'),
                ],
              ),
            ),
          );
        }

        // If user is signed in, show main app
        if (snapshot.hasData && snapshot.data != null) {
          print('User authenticated: ${snapshot.data!.email}');
          return const MainScreenWithInitialization();
        }

        // If user is not signed in, show login screen
        print('User not authenticated, showing login screen');
        return const LoginScreen();
      },
    );
  }
}

class MainScreenWithInitialization extends StatefulWidget {
  const MainScreenWithInitialization({super.key});

  @override
  State<MainScreenWithInitialization> createState() =>
      _MainScreenWithInitializationState();
}

class _MainScreenWithInitializationState
    extends State<MainScreenWithInitialization> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize the app state when user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _initializeAppState();
      }
    });
  }

  Future<void> _initializeAppState() async {
    try {
      print('Initializing AppState for authenticated user...');
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.initializeUserApp();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        print('AppState initialized successfully');
      }
    } catch (e) {
      print('Error initializing AppState: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your profile...'),
            ],
          ),
        ),
      );
    }

    return const MainScreen();
  }
}
