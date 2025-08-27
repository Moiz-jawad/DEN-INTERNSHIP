# Firebase Realtime Database Setup Guide

This guide will help you set up Firebase Realtime Database properly to resolve the permission denied error.

## 🔧 **Step 1: Enable Firebase Realtime Database**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. In the left sidebar, click on "Realtime Database"
4. Click "Create Database"
5. Choose a location (preferably close to your users)
6. Start in **test mode** for development (we'll secure it later)

## 🔒 **Step 2: Set Security Rules**

1. In the Realtime Database section, click on the "Rules" tab
2. Replace the existing rules with the following:

```json
{
  "rules": {
    "chatRooms": {
      "$chatRoomId": {
        ".read": "data.child('participantIds').hasChild(auth.uid)",
        ".write": "data.child('participantIds').hasChild(auth.uid) || !data.exists()",
        "participants": {
          "$userId": {
            ".read": "data.child('participantIds').hasChild(auth.uid)",
            ".write": "auth.uid == $userId || data.child('participantIds').hasChild(auth.uid)"
          }
        }
      }
    },
    "messages": {
      "$chatRoomId": {
        ".read": "root.child('chatRooms').child($chatRoomId).child('participantIds').hasChild(auth.uid)",
        ".write": "root.child('chatRooms').child($chatRoomId).child('participantIds').hasChild(auth.uid)",
        "$messageId": {
          ".read": "root.child('chatRooms').child($chatRoomId).child('participantIds').hasChild(auth.uid)",
          ".write": "root.child('chatRooms').child($chatRoomId).child('participantIds').hasChild(auth.uid)",
          "readBy": {
            "$userId": {
              ".read": "root.child('chatRooms').child($chatRoomId).child('participantIds').hasChild(auth.uid)",
              ".write": "auth.uid == $userId"
            }
          }
        }
      }
    },
    "userPresence": {
      "$userId": {
        ".read": "auth.uid == $userId",
        ".write": "auth.uid == $userId",
        ".validate": "newData.hasChildren(['userId', 'userName', 'isOnline', 'lastSeen'])"
      }
    },
    "presence": {
      "$chatRoomId": {
        ".read": "root.child('chatRooms').child($chatRoomId).child('participantIds').hasChild(auth.uid)",
        ".write": "root.child('chatRooms').child($chatRoomId).child('participantIds').hasChild(auth.uid)"
      }
    },
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

3. Click "Publish" to save the rules

## 🔐 **Step 3: Enable Authentication**

1. In the left sidebar, click on "Authentication"
2. Click "Get started"
3. Go to the "Sign-in method" tab
4. Enable the authentication methods you want to use:
   - **Email/Password** (recommended for testing)
   - **Google** (if you want Google Sign-In)
   - **Anonymous** (for testing without sign-up)

## 📱 **Step 4: Update Firebase Configuration**

Make sure your `firebase_options.dart` file includes the Realtime Database URL:

```dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // ... other options ...

    return const FirebaseOptions(
      apiKey: 'your-api-key',
      appId: 'your-app-id',
      messagingSenderId: 'your-sender-id',
      projectId: 'your-project-id',
      databaseURL: 'https://your-project-id-default-rtdb.firebaseio.com', // Add this line
      // ... other options ...
    );
  }
}
```

## 🧪 **Step 5: Test the Setup**

1. **Run the app** and sign in with a test user
2. **Check the console logs** for any Firebase errors
3. **Verify authentication** is working properly
4. **Test chat functionality** by creating a chat room

## 🚨 **Common Issues and Solutions**

### Issue 1: "Client doesn't have permission to access the desired data"

**Solution:**

- Ensure the user is authenticated before accessing the database
- Check that the security rules are properly published
- Verify the database URL is correct in your configuration

### Issue 2: "Database not found"

**Solution:**

- Make sure you've created the Realtime Database in your Firebase project
- Check that the database URL in `firebase_options.dart` matches your project

### Issue 3: "Authentication failed"

**Solution:**

- Ensure Authentication is enabled in Firebase Console
- Check that the user is properly signed in before accessing the database
- Verify the authentication method is enabled

## 🔍 **Debugging Steps**

1. **Enable Firebase Logging:**

```dart
FirebaseDatabase.instance.setLoggingEnabled(true);
```

2. **Check Authentication State:**

```dart
print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');
```

3. **Test Database Connection:**

```dart
try {
  final ref = FirebaseDatabase.instance.ref('test');
  await ref.set({'test': 'value'});
  print('Database connection successful');
} catch (e) {
  print('Database connection failed: $e');
}
```

## 📋 **Security Rules Explanation**

- **`chatRooms`**: Users can only read/write chat rooms they're participants in
- **`messages`**: Users can only access messages from chat rooms they're in
- **`userPresence`**: Users can only read/write their own presence data
- **`presence`**: Users can access presence data for chat rooms they're in
- **`.read/.write`**: All operations require authentication

## 🚀 **Production Considerations**

1. **Remove test mode** and use proper security rules
2. **Implement rate limiting** for message sending
3. **Add data validation** rules
4. **Monitor database usage** and costs
5. **Implement backup strategies**

## 📞 **Need Help?**

If you're still experiencing issues:

1. Check the Firebase Console for any error messages
2. Verify your project configuration
3. Test with a simple database operation first
4. Check the Firebase documentation for your specific error

## ✅ **Verification Checklist**

- [ ] Realtime Database is created and enabled
- [ ] Security rules are published
- [ ] Authentication is enabled
- [ ] Database URL is correct in configuration
- [ ] User is properly authenticated
- [ ] No permission errors in console
- [ ] Chat functionality works properly
