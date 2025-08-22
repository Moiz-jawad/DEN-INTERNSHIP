import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { pending, done }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'All';
  String _search = '';

  DatabaseReference _userTasksRef() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseDatabase.instance.ref('tasks/$uid');
  }

  Future<void> _addOrEditTask(
      {String? key, Map<String, dynamic>? existing}) async {
    final titleCtrl = TextEditingController(text: existing?['title']);
    final descCtrl = TextEditingController(text: existing?['description']);
    TaskPriority priority = TaskPriority.values.firstWhere(
        (e) => e.name.toLowerCase() == (existing?['priority'] ?? 'low'),
        orElse: () => TaskPriority.low);
    TaskStatus status = ((existing?['status'] ?? 'pending') == 'done')
        ? TaskStatus.done
        : TaskStatus.pending;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(key == null ? 'Add Task' : 'Edit Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskPriority>(
                value: priority,
                items: TaskPriority.values
                    .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                            p.name[0].toUpperCase() + p.name.substring(1))))
                    .toList(),
                onChanged: (v) => priority = v ?? TaskPriority.low,
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
              DropdownButtonFormField<TaskStatus>(
                value: status,
                items: TaskStatus.values
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                            s.name[0].toUpperCase() + s.name.substring(1))))
                    .toList(),
                onChanged: (v) => status = v ?? TaskStatus.pending,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final payload = {
                'title': titleCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'priority': priority.name,
                'status': status.name,
                'updatedAt': ServerValue.timestamp,
              };
              if (key == null) {
                await _userTasksRef().push().set({
                  ...payload,
                  'createdAt': ServerValue.timestamp,
                });
              } else {
                await _userTasksRef().child(key).update(payload);
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(key == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(String key) async {
    await _userTasksRef().child(key).remove();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
          body: Center(child: Text('Please sign in to manage tasks')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Pending', child: Text('Pending')),
              PopupMenuItem(value: 'Done', child: Text('Done')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditTask(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: 'Search by title'),
              onChanged: (v) =>
                  setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _userTasksRef().onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final map =
                    snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
                final entries = (map ?? {})
                    .entries
                    .map((e) => ({
                          'key': e.key as String,
                          ...Map<String, dynamic>.from(e.value as Map)
                        }))
                    .toList();
                entries.sort((a, b) =>
                    ((b['updatedAt'] ?? b['createdAt']) as int? ?? 0).compareTo(
                        ((a['updatedAt'] ?? a['createdAt']) as int? ?? 0)));

                final filtered = entries.where((e) {
                  final matchesSearch = _search.isEmpty ||
                      (e['title']?.toString().toLowerCase().contains(_search) ??
                          false);
                  final status = (e['status'] ?? 'pending') as String;
                  final matchesFilter = _filter == 'All' ||
                      status.toLowerCase() == _filter.toLowerCase();
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No tasks'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    return ListTile(
                      title: Text(t['title'] ?? ''),
                      subtitle: Text(t['description'] ?? ''),
                      leading: Icon(
                        (t['priority'] == 'high')
                            ? Icons.priority_high
                            : t['priority'] == 'medium'
                                ? Icons.flag
                                : Icons.low_priority,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              onPressed: () =>
                                  _addOrEditTask(key: t['key'], existing: t),
                              icon: const Icon(Icons.edit)),
                          IconButton(
                              onPressed: () => _deleteTask(t['key']),
                              icon: const Icon(Icons.delete)),
                        ],
                      ),
                      onTap: () {
                        final newStatus =
                            (t['status'] == 'done') ? 'pending' : 'done';
                        _userTasksRef().child(t['key']).update({
                          'status': newStatus,
                          'updatedAt': ServerValue.timestamp
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
