import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
          body: Center(child: Text('Please sign in to see history')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz History')),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance
            .ref('quizAttempts/$uid')
            .orderByChild('completedAt')
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
          if (data == null || data.isEmpty) {
            return const Center(child: Text('No attempts yet'));
          }
          final items = data.entries
              .map((e) => Map<String, dynamic>.from(e.value as Map))
              .toList()
            ..sort((a, b) =>
                (b['completedAt'] ?? 0).compareTo(a['completedAt'] ?? 0));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final it = items[index];
              final date = DateTime.fromMillisecondsSinceEpoch(
                  (it['completedAt'] ?? 0) as int,
                  isUtc: false);
              final score = it['score'] ?? 0;
              final total = it['total'] ?? 0;
              final durationMs = (it['durationMs'] ?? 0) as int;
              return ListTile(
                title: Text('Score: $score/$total'),
                subtitle: Text(
                    '${DateFormat.yMMMd().add_jm().format(date)} • ${(durationMs / 1000).toStringAsFixed(1)}s'),
                leading: const Icon(Icons.history),
              );
            },
          );
        },
      ),
    );
  }
}
