// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

class ErrorService {
  // Production error messages
  static const Map<String, String> _errorMessages = {
    // Authentication errors
    'user-not-found':
        'No account found with this email address. Please check your email or create a new account.',
    'wrong-password': 'Incorrect password. Please try again.',
    'email-already-in-use':
        'An account with this email already exists. Please sign in instead.',
    'weak-password': 'Password is too weak. Please use at least 6 characters.',
    'invalid-email': 'Please enter a valid email address.',
    'user-disabled': 'This account has been disabled. Please contact support.',
    'too-many-requests': 'Too many failed attempts. Please try again later.',
    'operation-not-allowed':
        'Email/password sign in is not enabled. Please contact support.',

    // Firebase errors
    'permission-denied': 'Access denied. Please check your permissions.',
    'unavailable': 'Service temporarily unavailable. Please try again later.',
    'deadline-exceeded': 'Request timed out. Please try again.',
    'resource-exhausted': 'Service quota exceeded. Please try again later.',
    'failed-precondition': 'Operation cannot be completed. Please try again.',
    'aborted': 'Operation was aborted. Please try again.',
    'out-of-range': 'Request is out of valid range.',
    'unimplemented': 'This feature is not yet implemented.',
    'internal': 'An internal error occurred. Please try again later.',
    'data-loss': 'Data was lost during operation. Please try again.',
    'unauthenticated': 'Please sign in to continue.',

    // Network errors
    'network-request-failed':
        'Network connection failed. Please check your internet connection.',
    'timeout': 'Request timed out. Please check your connection and try again.',

    // General errors
    'unknown': 'An unexpected error occurred. Please try again.',
    'default': 'Something went wrong. Please try again.',
  };

  // Get user-friendly error message
  static String getErrorMessage(dynamic error, {String? fallback}) {
    if (error == null) return fallback ?? _errorMessages['default']!;

    String errorCode = 'unknown';

    // Handle Firebase Auth exceptions
    if (error.toString().contains('FirebaseAuthException')) {
      final errorString = error.toString();
      for (final code in _errorMessages.keys) {
        if (errorString.contains(code)) {
          errorCode = code;
          break;
        }
      }
    }

    // Handle Firebase Firestore exceptions
    if (error.toString().contains('FirebaseException')) {
      final errorString = error.toString();
      for (final code in _errorMessages.keys) {
        if (errorString.contains(code)) {
          errorCode = code;
          break;
        }
      }
    }

    return _errorMessages[errorCode] ?? fallback ?? _errorMessages['default']!;
  }

  // Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    String? fallback,
  }) {
    final message = getErrorMessage(error, fallback: fallback);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Log error for debugging (in production, this would go to a logging service)
  static void logError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    print('ERROR in $context: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }

  // Handle async operations with error handling
  static Future<T> handleAsyncOperation<T>({
    required Future<T> Function() operation,
    required String context,
    String? fallbackMessage,
    bool showErrorSnackBar = true,
    BuildContext? snackBarContext,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      logError(context, error, stackTrace);

      if (showErrorSnackBar && snackBarContext != null) {
        ErrorService.showErrorSnackBar(
          snackBarContext,
          error,
          fallback: fallbackMessage,
        );
      }

      rethrow;
    }
  }
}
