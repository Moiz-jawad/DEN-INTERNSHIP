import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int answerIndex;
  QuizQuestion(
      {required this.id,
      required this.question,
      required this.options,
      required this.answerIndex});

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as int,
      question: map['question'] as String,
      options: (map['options'] as List).map((e) => e.toString()).toList(),
      answerIndex: map['answerIndex'] as int,
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion> _questions = [];
  int _current = 0;
  int _secondsLeft = 10;
  Timer? _timer;
  final Map<int, int> _answers = {};
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final String jsonStr =
        await rootBundle.loadString('assets/quiz/questions.json');
    final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
    setState(() {
      _questions = data
          .map((e) => QuizQuestion.fromMap(e as Map<String, dynamic>))
          .toList();
      _current = 0;
      _secondsLeft = 10;
      _startTime = DateTime.now();
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        _onTimeout();
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
    setState(() {});
  }

  void _onTimeout() {
    if (_answers[_questions[_current].id] == null) {
      _answers[_questions[_current].id] = -1; // missed
    }
    _next();
  }

  void _choose(int optionIndex) {
    if (_answers.containsKey(_questions[_current].id)) return;
    setState(() {
      _answers[_questions[_current].id] = optionIndex;
    });
    Future.delayed(const Duration(milliseconds: 400), _next);
  }

  Future<void> _next() async {
    _timer?.cancel();
    if (_current + 1 < _questions.length) {
      setState(() => _current += 1);
      _startTimer();
      return;
    }
    await _finish();
  }

  int _score() {
    int s = 0;
    for (final q in _questions) {
      final picked = _answers[q.id];
      if (picked != null && picked == q.answerIndex) s += 1;
    }
    return s;
  }

  Future<void> _finish() async {
    final end = DateTime.now();
    final durationMs = end.difference(_startTime ?? end).inMilliseconds;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final ref = FirebaseDatabase.instance.ref('quizAttempts/$uid').push();
      await ref.set({
        'score': _score(),
        'total': _questions.length,
        'startedAt': _startTime?.millisecondsSinceEpoch,
        'completedAt': end.millisecondsSinceEpoch,
        'durationMs': durationMs,
        'answers': _answers.map((k, v) => MapEntry(k.toString(), v)),
      });
    }
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Completed'),
        content: Text(
            'Score: ${_score()}/${_questions.length}\nTime: ${(durationMs / 1000).toStringAsFixed(1)}s'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')),
        ],
      ),
    ).then((_) {
      setState(() {
        _current = 0;
        _answers.clear();
        _startTime = DateTime.now();
      });
      _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = _questions[_current];
    final picked = _answers[q.id];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          IconButton(
              onPressed: () => context.push('history'),
              icon: const Icon(Icons.history))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text('Q ${_current + 1}/${_questions.length}')),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(value: _secondsLeft / 10),
                ),
                const SizedBox(width: 8),
                Text('${_secondsLeft}s'),
              ],
            ),
            const SizedBox(height: 16),
            Text(q.question, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...List.generate(q.options.length, (i) {
              final bool isCorrect = i == q.answerIndex;
              Color? color;
              if (picked != null) {
                if (i == picked) color = isCorrect ? Colors.green : Colors.red;
                if (picked != i && isCorrect)
                  color = Colors.green.withOpacity(0.2);
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  tileColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300)),
                  onTap: picked == null ? () => _choose(i) : null,
                  title: Text(q.options[i]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
