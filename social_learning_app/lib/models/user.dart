class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final List<QuizResult> quizHistory;
  final int tasksCount;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
    this.quizHistory = const [],
    this.tasksCount = 0,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      name: data['name'] ?? data['displayName'] ?? 'Unknown User',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'] ?? data['photoUrl'],
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'])
          : null,
      quizHistory:
          (data['quizHistory'] as List<Object?>?)
              ?.map((e) => QuizResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tasksCount: data['tasksCount'] ?? 0,
    );
  }

  factory User.fromAuth(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      name: data['displayName'] ?? 'Unknown User',
      email: data['email'] ?? '',
      avatarUrl: data['avatarURL'] ?? data['photoURL'],
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown User',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'])
          : null,
      quizHistory:
          (json['quizHistory'] as List<Object?>?)
              ?.map((e) => QuizResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tasksCount: json['tasksCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'quizHistory': quizHistory.map((e) => e.toJson()).toList(),
      'tasksCount': tasksCount,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    List<QuizResult>? quizHistory,
    int? tasksCount,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      quizHistory: quizHistory ?? this.quizHistory,
      tasksCount: tasksCount ?? this.tasksCount,
    );
  }
}

class QuizResult {
  final String quizId;
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  QuizResult({
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId'] ?? '',
      quizTitle: json['quizTitle'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      completedAt: DateTime.parse(
        json['completedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}
