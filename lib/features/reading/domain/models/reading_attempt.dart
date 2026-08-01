class ReadingAttempt {
  final String id;
  final String userId;
  final String passageId;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int score; // 0-100%
  final bool isPassed;
  final int xpEarned;
  final int duration; // in seconds
  final String status; // in_progress, completed, abandoned
  final DateTime? submittedAt;

  const ReadingAttempt({
    required this.id,
    required this.userId,
    required this.passageId,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.score = 0,
    this.isPassed = false,
    this.xpEarned = 0,
    this.duration = 0,
    this.status = 'completed',
    this.submittedAt,
  });

  factory ReadingAttempt.fromJson(Map<String, dynamic> json) {
    // Backend submitAttempt returns { attemptId: "...", score: 80.0, ... }
    // Backend ReadingAttempt doc returns { _id: "...", score: 80, ... }
    final rawId = json['attemptId'] ?? json['_id'] ?? json['id'] ?? '';
    final id = rawId is Map ? (rawId['_id'] ?? rawId['id'] ?? '').toString() : rawId.toString();

    // passageId can be a string or a populated object
    final rawPassageId = json['passageId'] ?? '';
    final passageId = rawPassageId is Map
        ? (rawPassageId['_id'] ?? '').toString()
        : rawPassageId.toString();

    // score from backend can be double (e.g. 80.0), convert to int
    final rawScore = json['score'] ?? 0;
    final score = rawScore is double ? rawScore.round() : (rawScore as int? ?? 0);

    return ReadingAttempt(
      id: id,
      userId: (json['userId'] ?? '').toString(),
      passageId: passageId,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (json['wrongAnswers'] as num?)?.toInt() ?? 0,
      score: score,
      isPassed: json['isPassed'] ?? false,
      xpEarned: (json['xpEarned'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'completed',
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'passageId': passageId,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'score': score,
      'isPassed': isPassed,
      'xpEarned': xpEarned,
      'duration': duration,
      'status': status,
      'submittedAt': submittedAt?.toIso8601String(),
    };
  }
}
