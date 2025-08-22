import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('profiles/${user.uid}').onValue,
        builder: (context, snapshot) {
          final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
          final profile = data == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(data);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                        radius: 32,
                        child: Text((profile['name'] ?? 'U')
                            .toString()
                            .substring(0, 1)
                            .toUpperCase())),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile['name'] ?? user.email ?? 'User',
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(profile['email'] ?? user.email ?? ''),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
