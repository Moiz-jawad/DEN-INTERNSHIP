class Quiz {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;
  final int timeLimit; // in minutes
  final String category;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    this.timeLimit = 30,
    this.category = 'General',
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      questions:
          (json['questions'] as List<Object?>?)
              ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeLimit: json['timeLimit'] ?? 30,
      category: json['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((e) => e.toJson()).toList(),
      'timeLimit': timeLimit,
      'category': category,
    };
  }
}

class Question {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  Question({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation = '',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      questionText: json['questionText'] ?? '',
      options: List<String>.from((json['options'] as List<Object?>?) ?? []),
      correctAnswerIndex: json['correctAnswerIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}
