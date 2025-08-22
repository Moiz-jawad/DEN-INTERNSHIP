import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  DatabaseReference _roomRef() =>
      FirebaseDatabase.instance.ref('globalChat/messages');

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    await _roomRef().push().set({
      'text': text,
      'uid': user?.uid,
      'displayName': user?.email?.split('@').first ?? 'User',
      'avatarUrl': '',
      'timestamp': ServerValue.timestamp,
    });
    _msgCtrl.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scroll.hasClients)
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Group Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _roomRef().orderByChild('timestamp').onValue,
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
                final messages = data == null
                    ? <Map<String, dynamic>>[]
                    : data.entries
                        .map((e) => Map<String, dynamic>.from(e.value as Map))
                        .toList()
                  ..sort((a, b) =>
                      (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));
                return ListView.builder(
                  controller: _scroll,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    return ListTile(
                      leading: CircleAvatar(
                          child: Text((m['displayName'] ?? 'U')
                              .toString()
                              .substring(0, 1)
                              .toUpperCase())),
                      title: Text(m['displayName'] ?? 'Unknown'),
                      subtitle: Text(m['text'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _msgCtrl,
                      decoration:
                          const InputDecoration(hintText: 'Type a message'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
