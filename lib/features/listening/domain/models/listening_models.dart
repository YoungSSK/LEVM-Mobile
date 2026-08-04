class ListeningSet {
  final String id;
  final String title;
  final int part;
  final String difficulty;
  final String status;
  final int xpReward;
  final int passThreshold;
  final int questionCount;
  final List<dynamic> allowedPackageIds;
  final bool isProRequired;

  const ListeningSet({
    required this.id,
    required this.title,
    required this.part,
    required this.difficulty,
    required this.status,
    required this.xpReward,
    required this.passThreshold,
    required this.questionCount,
    this.allowedPackageIds = const [],
    this.isProRequired = false,
  });

  factory ListeningSet.fromJson(Map<String, dynamic> json) {
    final pkgs = json['allowedPackageIds'] as List<dynamic>? ?? [];

    bool isPro = false;
    for (final pkg in pkgs) {
      if (pkg is Map<String, dynamic>) {
        final level = (pkg['level'] is num) ? (pkg['level'] as num).toInt() : 0;
        final price = (pkg['price'] is num) ? (pkg['price'] as num).toInt() : 0;
        final slug = (pkg['slug'] ?? '').toString().toLowerCase();
        if ((level > 1 || price > 0) && slug != 'thuong' && slug != 'free') {
          isPro = true;
          break;
        }
      }
    }

    return ListeningSet(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      part: (json['part'] is num) ? (json['part'] as num).toInt() : 1,
      difficulty: json['difficulty'] ?? 'intermediate',
      status: json['status'] ?? 'published',
      xpReward: (json['xpReward'] is num) ? (json['xpReward'] as num).toInt() : 15,
      passThreshold: (json['passThreshold'] is num) ? (json['passThreshold'] as num).toInt() : 70,
      questionCount: (json['questionCount'] is num) ? (json['questionCount'] as num).toInt() : 0,
      allowedPackageIds: pkgs,
      isProRequired: isPro,
    );
  }
}

class ListeningAudioGroup {
  final String id;
  final String setId;
  final String title;
  final String audioUrl;
  final String transcript;
  final String? imageUrl;

  const ListeningAudioGroup({
    required this.id,
    required this.setId,
    required this.title,
    required this.audioUrl,
    required this.transcript,
    this.imageUrl,
  });

  factory ListeningAudioGroup.fromJson(Map<String, dynamic> json) {
    return ListeningAudioGroup(
      id: json['_id'] ?? json['id'] ?? '',
      setId: json['setId'] ?? '',
      title: json['title'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      transcript: json['transcript'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
}

class ListeningOption {
  final String key;
  final String text;
  final bool? isCorrect;

  const ListeningOption({
    required this.key,
    required this.text,
    this.isCorrect,
  });

  factory ListeningOption.fromJson(Map<String, dynamic> json) {
    return ListeningOption(
      key: json['key'] ?? '',
      text: json['text'] ?? '',
      isCorrect: json['isCorrect'] as bool?,
    );
  }
}

class ListeningQuestion {
  final String id;
  final String setId;
  final String? groupId;
  final int part;
  final String? audioUrl;
  final String? imageUrl;
  final String? transcript;
  final String? questionText;
  final List<ListeningOption> options;

  const ListeningQuestion({
    required this.id,
    required this.setId,
    this.groupId,
    required this.part,
    this.audioUrl,
    this.imageUrl,
    this.transcript,
    this.questionText,
    required this.options,
  });

  factory ListeningQuestion.fromJson(Map<String, dynamic> json) {
    return ListeningQuestion(
      id: json['_id'] ?? json['id'] ?? '',
      setId: json['setId'] ?? '',
      groupId: json['groupId'],
      part: (json['part'] is num) ? (json['part'] as num).toInt() : 1,
      audioUrl: json['audioUrl'],
      imageUrl: json['imageUrl'],
      transcript: json['transcript'],
      questionText: json['questionText'],
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => ListeningOption.fromJson(o))
              .toList() ??
          [],
    );
  }
}

class ListeningPlayPayload {
  final ListeningSet set;
  final List<ListeningAudioGroup> groups;
  final List<ListeningQuestion> questions;

  const ListeningPlayPayload({
    required this.set,
    required this.groups,
    required this.questions,
  });

  factory ListeningPlayPayload.fromJson(Map<String, dynamic> json) {
    return ListeningPlayPayload(
      set: ListeningSet.fromJson(json['set'] ?? {}),
      groups: (json['groups'] as List<dynamic>?)
              ?.map((g) => ListeningAudioGroup.fromJson(g))
              .toList() ??
          [],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => ListeningQuestion.fromJson(q))
              .toList() ??
          [],
    );
  }
}

class ListeningDetailAnswer {
  final String questionId;
  final int part;
  final String? questionText;
  final String selectedKey;
  final String correctKey;
  final bool isCorrect;
  final String explanation;
  final String transcript;
  final List<ListeningOption> options;

  const ListeningDetailAnswer({
    required this.questionId,
    required this.part,
    this.questionText,
    required this.selectedKey,
    required this.correctKey,
    required this.isCorrect,
    required this.explanation,
    required this.transcript,
    required this.options,
  });

  factory ListeningDetailAnswer.fromJson(Map<String, dynamic> json) {
    return ListeningDetailAnswer(
      questionId: json['questionId'] ?? '',
      part: (json['part'] is num) ? (json['part'] as num).toInt() : 1,
      questionText: json['questionText'],
      selectedKey: json['selectedKey'] ?? '',
      correctKey: json['correctKey'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
      explanation: json['explanation'] ?? '',
      transcript: json['transcript'] ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => ListeningOption.fromJson(o))
              .toList() ??
          [],
    );
  }
}

class ListeningSubmitResult {
  final String attemptId;
  final String setId;
  final String setTitle;
  final int part;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final bool isPassed;
  final int passThreshold;
  final int xpEarned;
  final int durationSeconds;
  final List<ListeningDetailAnswer> details;

  const ListeningSubmitResult({
    required this.attemptId,
    required this.setId,
    required this.setTitle,
    required this.part,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.isPassed,
    required this.passThreshold,
    required this.xpEarned,
    required this.durationSeconds,
    required this.details,
  });

  factory ListeningSubmitResult.fromJson(Map<String, dynamic> json) {
    return ListeningSubmitResult(
      attemptId: json['attemptId'] ?? '',
      setId: json['setId'] ?? '',
      setTitle: json['setTitle'] ?? '',
      part: (json['part'] is num) ? (json['part'] as num).toInt() : 1,
      score: (json['score'] is num) ? (json['score'] as num).toInt() : 0,
      totalQuestions: (json['totalQuestions'] is num) ? (json['totalQuestions'] as num).toInt() : 0,
      correctAnswers: (json['correctAnswers'] is num) ? (json['correctAnswers'] as num).toInt() : 0,
      isPassed: json['isPassed'] ?? false,
      passThreshold: (json['passThreshold'] is num) ? (json['passThreshold'] as num).toInt() : 70,
      xpEarned: (json['xpEarned'] is num) ? (json['xpEarned'] as num).toInt() : 0,
      durationSeconds: (json['durationSeconds'] is num) ? (json['durationSeconds'] as num).toInt() : 0,
      details: (json['details'] as List<dynamic>?)
              ?.map((d) => ListeningDetailAnswer.fromJson(d))
              .toList() ??
          [],
    );
  }
}
