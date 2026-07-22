class LessonAttemptModel {
  final String id;
  final String lessonId;
  final String userId;
  final int level;
  final String status;
  final int correctCount;
  final int totalCount;
  final int score;
  final int stars;
  final List<AnswerModel> answers;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const LessonAttemptModel({
    required this.id,
    required this.lessonId,
    required this.userId,
    required this.level,
    this.status = "in_progress",
    this.correctCount = 0,
    this.totalCount = 0,
    this.score = 0,
    this.stars = 0,
    this.answers = const [],
    this.startedAt,
    this.completedAt,
    this.createdAt,
  });

  factory LessonAttemptModel.fromJson(Map<String, dynamic> json) {
    return LessonAttemptModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      lessonId: (json["lessonId"] ?? "").toString(),
      userId: (json["userId"] ?? "").toString(),
      level: _intOrDefault(json["level"]),
      status: (json["status"] ?? "in_progress").toString(),
      correctCount: _intOrDefault(json["correctCount"]),
      totalCount: _intOrDefault(json["totalCount"]),
      score: _intOrDefault(json["score"]),
      stars: _intOrDefault(json["stars"]),
      answers: (json["answers"] as List<dynamic>?)
              ?.map((a) => AnswerModel.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      startedAt: _dateOrNull(json["startedAt"]),
      completedAt: _dateOrNull(json["completedAt"]),
      createdAt: _dateOrNull(json["createdAt"]),
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }

  static DateTime? _dateOrNull(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  bool get isCompleted => status == "completed";
  double get accuracy => totalCount > 0 ? correctCount / totalCount : 0;

  LessonAttemptModel copyWith({
    String? id,
    String? lessonId,
    String? userId,
    int? level,
    String? status,
    int? correctCount,
    int? totalCount,
    int? score,
    int? stars,
    List<AnswerModel>? answers,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return LessonAttemptModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      userId: userId ?? this.userId,
      level: level ?? this.level,
      status: status ?? this.status,
      correctCount: correctCount ?? this.correctCount,
      totalCount: totalCount ?? this.totalCount,
      score: score ?? this.score,
      stars: stars ?? this.stars,
      answers: answers ?? this.answers,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AnswerModel {
  final String wordId;
  final bool isCorrect;
  final String userAnswer;
  final int timeSpent;

  const AnswerModel({
    required this.wordId,
    this.isCorrect = false,
    this.userAnswer = "",
    this.timeSpent = 0,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      wordId: (json["wordId"] ?? "").toString(),
      isCorrect: json["isCorrect"] ?? false,
      userAnswer: (json["userAnswer"] ?? "").toString(),
      timeSpent: _intOrDefault(json["timeSpent"]),
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }
}

class LessonStatsModel {
  final int totalAttempts;
  final int bestScore;
  final int bestStars;
  final int totalStars;
  final int averageScore;
  final Map<int, LevelStatsModel> levelStats;

  const LessonStatsModel({
    this.totalAttempts = 0,
    this.bestScore = 0,
    this.bestStars = 0,
    this.totalStars = 0,
    this.averageScore = 0,
    this.levelStats = const {},
  });

  factory LessonStatsModel.fromJson(Map<String, dynamic> json) {
    final levelStatsJson = json["levelStats"] as Map<String, dynamic>? ?? {};
    final levelStats = <int, LevelStatsModel>{};

    levelStatsJson.forEach((key, value) {
      final level = int.tryParse(key);
      if (level != null) {
        levelStats[level] = LevelStatsModel.fromJson(value as Map<String, dynamic>);
      }
    });

    return LessonStatsModel(
      totalAttempts: _intOrDefault(json["totalAttempts"]),
      bestScore: _intOrDefault(json["bestScore"]),
      bestStars: _intOrDefault(json["bestStars"]),
      totalStars: _intOrDefault(json["totalStars"]),
      averageScore: _intOrDefault(json["averageScore"]),
      levelStats: levelStats,
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }

  bool isLevelCompleted(int level) => levelStats[level]?.completed ?? false;

  int getLevelBestStars(int level) => levelStats[level]?.bestStars ?? 0;

  int getLevelBestScore(int level) => levelStats[level]?.bestScore ?? 0;
}

class LevelStatsModel {
  final int attempts;
  final int bestScore;
  final int bestStars;
  final bool completed;

  const LevelStatsModel({
    this.attempts = 0,
    this.bestScore = 0,
    this.bestStars = 0,
    this.completed = false,
  });

  factory LevelStatsModel.fromJson(Map<String, dynamic> json) {
    return LevelStatsModel(
      attempts: _intOrDefault(json["attempts"]),
      bestScore: _intOrDefault(json["bestScore"]),
      bestStars: _intOrDefault(json["bestStars"]),
      completed: json["completed"] ?? false,
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }
}

class CompleteAttemptResult {
  final LessonAttemptModel attempt;
  final int stars;
  final XpResultsModel xpResults;
  final StreakResultModel? streakResult;
  final bool allLevelsComplete;
  final bool leveledUp;

  const CompleteAttemptResult({
    required this.attempt,
    required this.stars,
    required this.xpResults,
    this.streakResult,
    this.allLevelsComplete = false,
    this.leveledUp = false,
  });

  factory CompleteAttemptResult.fromJson(Map<String, dynamic> json) {
    return CompleteAttemptResult(
      attempt: LessonAttemptModel.fromJson(json["attempt"] ?? {}),
      stars: _intOrDefault(json["stars"]),
      xpResults: XpResultsModel.fromJson(json["xpResults"] ?? {}),
      streakResult: json["streakResult"] != null
          ? StreakResultModel.fromJson(json["streakResult"])
          : null,
      allLevelsComplete: json["allLevelsComplete"] ?? false,
      leveledUp: json["leveledUp"] ?? false,
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }
}

class XpResultsModel {
  final int levelXp;
  final int bonusXp;
  final bool perfectBonus;
  final int streakXp;
  final int lessonBonusXp;
  final int totalXp;

  const XpResultsModel({
    this.levelXp = 0,
    this.bonusXp = 0,
    this.perfectBonus = false,
    this.streakXp = 0,
    this.lessonBonusXp = 0,
    this.totalXp = 0,
  });

  factory XpResultsModel.fromJson(Map<String, dynamic> json) {
    return XpResultsModel(
      levelXp: _intOrDefault(json["levelXP"]),
      bonusXp: _intOrDefault(json["bonusXP"]),
      perfectBonus: json["perfectBonus"] ?? false,
      streakXp: _intOrDefault(json["streakXP"]),
      lessonBonusXp: _intOrDefault(json["lessonBonusXP"]),
      totalXp: _intOrDefault(json["totalXP"]),
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }
}

class StreakResultModel {
  final int currentStreak;
  final int longestStreak;
  final bool streakUpdated;
  final bool usedFreeze;

  const StreakResultModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.streakUpdated = false,
    this.usedFreeze = false,
  });

  factory StreakResultModel.fromJson(Map<String, dynamic> json) {
    return StreakResultModel(
      currentStreak: _intOrDefault(json["currentStreak"]),
      longestStreak: _intOrDefault(json["longestStreak"]),
      streakUpdated: json["streakUpdated"] ?? false,
      usedFreeze: json["usedFreeze"] ?? false,
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }
}
