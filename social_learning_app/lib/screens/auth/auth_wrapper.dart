import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_service.dart';
import 'login_screen.dart';
import '../main_screen.dart';
import '../onboarding/onboarding_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _forceRebuild = false;

  void _onOnboardingComplete() {
    setState(() {
      _forceRebuild = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is signed in, check onboarding status
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: OnboardingService.isOnboardingCompleted(),
            builder: (context, onboardingSnapshot) {
              if (onboardingSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // If onboarding not completed, show onboarding
              if (onboardingSnapshot.data != true) {
                return OnboardingScreen(
                  onOnboardingComplete: _onOnboardingComplete,
                );
              }

              // Onboarding completed, show main app
              return const MainScreen();
            },
          );
        }

        // If user is not signed in, show login screen
        return const LoginScreen();
      },
    );
  }
}
