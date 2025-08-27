// ignore_for_file: avoid_print

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnboardingService {
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _currentOnboardingStepKey = 'current_onboarding_step';
  static const String _userOnboardingCompletedKey = 'user_onboarding_completed';

  // Check if onboarding has been completed for current user
  static Future<bool> isOnboardingCompleted() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // First check Firestore for user-specific onboarding status
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData.containsKey('onboardingCompleted')) {
          return userData['onboardingCompleted'] ?? false;
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(
            '${_userOnboardingCompletedKey}_${currentUser.uid}',
          ) ??
          false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      // Fallback to local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          return prefs.getBool(
                '${_userOnboardingCompletedKey}_${currentUser.uid}',
              ) ??
              false;
        }
      } catch (localError) {
        print('Error with local storage fallback: $localError');
      }
      return false;
    }
  }

  // Mark onboarding as completed for current user
  static Future<void> completeOnboarding() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({
            'onboardingCompleted': true,
            'onboardingCompletedAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        '${_userOnboardingCompletedKey}_${currentUser.uid}',
        true,
      );

      print('Onboarding marked as completed for user: ${currentUser.uid}');
    } catch (e) {
      print('Error completing onboarding: $e');
      // Fallback to local storage only
      try {
        final prefs = await SharedPreferences.getInstance();
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await prefs.setBool(
            '${_userOnboardingCompletedKey}_${currentUser.uid}',
            true,
          );
        }
      } catch (localError) {
        print('Error with local storage fallback: $localError');
      }
    }
  }

  // Get current onboarding step
  static Future<int> getCurrentOnboardingStep() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        return prefs.getInt(
              '${_currentOnboardingStepKey}_${currentUser.uid}',
            ) ??
            0;
      }
      return prefs.getInt(_currentOnboardingStepKey) ?? 0;
    } catch (e) {
      print('Error getting onboarding step: $e');
      return 0;
    }
  }

  // Set current onboarding step
  static Future<void> setCurrentOnboardingStep(int step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await prefs.setInt(
          '${_currentOnboardingStepKey}_${currentUser.uid}',
          step,
        );
      } else {
        await prefs.setInt(_currentOnboardingStepKey, step);
      }
    } catch (e) {
      print('Error setting onboarding step: $e');
    }
  }

  // Reset onboarding for current user (useful for testing or if user wants to see it again)
  static Future<void> resetOnboarding() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
              'onboardingCompleted': false,
              'onboardingResetAt': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        // Clear local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('${_userOnboardingCompletedKey}_${currentUser.uid}');
        await prefs.remove('${_currentOnboardingStepKey}_${currentUser.uid}');
      } else {
        // Fallback for when no user is signed in
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_onboardingCompletedKey);
        await prefs.remove(_currentOnboardingStepKey);
      }
    } catch (e) {
      print('Error resetting onboarding: $e');
      // Fallback to local storage only
      try {
        final prefs = await SharedPreferences.getInstance();
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await prefs.remove(
            '${_userOnboardingCompletedKey}_${currentUser.uid}',
          );
          await prefs.remove('${_currentOnboardingStepKey}_${currentUser.uid}');
        } else {
          await prefs.remove(_onboardingCompletedKey);
          await prefs.remove(_currentOnboardingStepKey);
        }
      } catch (localError) {
        print('Error with local storage fallback: $localError');
      }
    }
  }

  // Check if user has seen onboarding before (for analytics)
  static Future<bool> hasSeenOnboarding() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        return userData != null && userData.containsKey('onboardingCompleted');
      }
      return false;
    } catch (e) {
      print('Error checking if user has seen onboarding: $e');
      return false;
    }
  }
}
