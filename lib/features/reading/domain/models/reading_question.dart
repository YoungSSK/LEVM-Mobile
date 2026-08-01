class QuizOption {
  final String key; // e.g. "A", "B", "C", "D"
  final String text;

  const QuizOption({
    required this.key,
    required this.text,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      key: json['key'] ?? json['id'] ?? '',
      text: json['text'] ?? json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'key': key, 'text': text};
}

class ReadingQuestion {
  final String id;
  final String passageId;
  final String questionText;
  final String questionType; // multiple_choice, true_false, fill_blank
  final List<QuizOption> options;
  final String correctAnswer; // e.g. "A" or "True"
  final String explanation;
  final int points;

  const ReadingQuestion({
    required this.id,
    required this.passageId,
    required this.questionText,
    this.questionType = 'multiple_choice',
    this.options = const [],
    required this.correctAnswer,
    this.explanation = '',
    this.points = 10,
  });

  factory ReadingQuestion.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'] as List<dynamic>? ?? [];
    List<QuizOption> options = rawOptions.map((opt) {
      if (opt is Map<String, dynamic>) {
        return QuizOption.fromJson(opt);
      }
      return QuizOption(key: opt.toString(), text: opt.toString());
    }).toList();

    return ReadingQuestion(
      id: json['_id'] ?? json['id'] ?? '',
      passageId: json['passageId'] ?? '',
      questionText: json['questionText'] ?? json['prompt'] ?? '',
      questionType: json['questionType'] ?? 'multiple_choice',
      options: options,
      correctAnswer: json['correctAnswer'] ?? json['answer'] ?? '',
      explanation: json['explanation'] ?? '',
      points: json['points'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'passageId': passageId,
      'questionText': questionText,
      'questionType': questionType,
      'options': options.map((e) => e.toJson()).toList(),
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
    };
  }
}
