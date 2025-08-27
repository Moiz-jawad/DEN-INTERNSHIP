# Firebase Authentication Implementation

This document describes the Firebase Authentication system implemented in the Social Learning App.

## Features Implemented

### 1. User Authentication

- **Sign Up**: Users can create new accounts with email, password, and name
- **Sign In**: Users can sign in with existing email and password
- **Sign Out**: Users can sign out from their account
- **Password Reset**: Users can request password reset emails

### 2. User Profile Management

- **Profile Storage**: User profiles are stored in Firebase Firestore
- **Profile Fields**: Name, email, avatar URL, quiz history, and task count
- **Profile Updates**: Users can update their profile information

### 3. Security Features

- **Email Validation**: Proper email format validation
- **Password Requirements**: Minimum 6 characters
- **Error Handling**: Comprehensive error messages for authentication failures
- **Secure Storage**: User data stored securely in Firebase

## File Structure

```
lib/
├── services/
│   ├── auth_service.dart          # Firebase Authentication service
│   └── firebase_service.dart      # Firebase Firestore service
├── screens/
│   ├── auth/
│   │   ├── auth_wrapper.dart      # Authentication state wrapper
│   │   ├── login_screen.dart      # Login screen
│   │   └── register_screen.dart   # Registration screen
│   └── main_screen.dart           # Main app screen
├── models/
│   └── user.dart                  # User model with avatar support
└── providers/
    └── app_state.dart             # App state management with auth integration
```

## How It Works

### 1. Authentication Flow

1. **App Launch**: `AuthWrapper` checks Firebase authentication state
2. **Not Authenticated**: Shows `LoginScreen`
3. **Authenticated**: Shows `MainScreen` with user data loaded

### 2. User Registration

1. User fills out registration form (name, email, password, confirm password)
2. Form validation ensures data integrity
3. `AuthService.signUpWithEmailAndPassword()` creates Firebase user
4. User profile is stored in Firestore
5. User is redirected to login screen

### 3. User Login

1. User enters email and password
2. `AuthService.signInWithEmailAndPassword()` authenticates with Firebase
3. On success, user is automatically redirected to main app
4. User profile is loaded from Firestore

### 4. Profile Management

1. User profile is automatically loaded when app initializes
2. Profile information is displayed in the profile screen
3. Users can edit their profile information
4. Sign out button clears all user data and returns to login

## Firebase Configuration

### Required Firebase Services

- **Firebase Authentication**: For user sign up/sign in
- **Firebase Firestore**: For storing user profiles and app data

### Firestore Collections

- `users`: Stores user profiles with the following structure:
  ```json
  {
    "id": "firebase_user_uid",
    "name": "User's Full Name",
    "email": "user@example.com",
    "avatarUrl": "https://example.com/avatar.jpg",
    "quizHistory": [],
    "tasksCount": 0
  }
  ```

## Usage Examples

### Sign Up a New User

```dart
try {
  await AuthService.signUpWithEmailAndPassword(
    email: 'user@example.com',
    password: 'password123',
    name: 'John Doe',
  );
  // User created successfully
} catch (e) {
  // Handle error
  print('Sign up failed: $e');
}
```

### Sign In Existing User

```dart
try {
  await AuthService.signInWithEmailAndPassword(
    email: 'user@example.com',
    password: 'password123',
  );
  // User signed in successfully
} catch (e) {
  // Handle error
  print('Sign in failed: $e');
}
```

### Get Current User Profile

```dart
final user = AuthService.currentUser;
if (user != null) {
  final profile = await AuthService.getUserProfile(user.uid);
  // Use profile data
}
```

### Update User Profile

```dart
await AuthService.updateUserProfile(
  userId: 'user_uid',
  name: 'New Name',
  email: 'newemail@example.com',
);
```

### Sign Out

```dart
await AuthService.signOut();
// User is now signed out
```

## Error Handling

The authentication system includes comprehensive error handling for common Firebase Auth errors:

- **user-not-found**: No user found with the email
- **wrong-password**: Incorrect password
- **email-already-in-use**: Email already registered
- **weak-password**: Password too weak
- **invalid-email**: Invalid email format
- **user-disabled**: User account disabled
- **too-many-requests**: Rate limiting
- **operation-not-allowed**: Email/password not enabled

## Security Considerations

1. **Password Requirements**: Minimum 6 characters
2. **Email Validation**: Proper email format validation
3. **Secure Storage**: User data stored in Firebase (not locally)
4. **Authentication State**: Proper state management and cleanup
5. **Error Messages**: User-friendly error messages without exposing system details

## Testing the Authentication

1. **Run the app**: The app will show the login screen if no user is authenticated
2. **Create account**: Use the "Create Account" button to register
3. **Sign in**: Use your credentials to sign in
4. **Profile**: Check the profile screen to see your information
5. **Sign out**: Use the sign out button in the profile screen

## Troubleshooting

### Common Issues

1. **Firebase not initialized**: Ensure Firebase is properly configured
2. **Authentication errors**: Check Firebase console for authentication settings
3. **Profile not loading**: Verify Firestore rules allow read/write access
4. **Sign out not working**: Check if the user is properly authenticated

### Debug Information

The app includes debug logging for authentication operations. Check the console for:

- Firebase initialization status
- User authentication state changes
- Profile loading operations
- Error messages

## Future Enhancements

1. **Social Authentication**: Google, Facebook, Apple Sign In
2. **Email Verification**: Require email verification before access
3. **Two-Factor Authentication**: Additional security layer
4. **Profile Pictures**: Image upload and storage
5. **Password Change**: Allow users to change passwords
6. **Account Deletion**: User account deletion functionality




