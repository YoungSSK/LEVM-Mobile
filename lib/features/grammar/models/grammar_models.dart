/// Models cho Grammar feature.
///
/// Backend đã có sẵn:
/// - GrammarTopic: name, slug, description, order, lessonCount, isActive
/// - GrammarLesson: topicId, title, slug, shortDescription, htmlContent,
///   plainTextContent, thumbnailUrl, estimatedTime, order, isPublished,
///   xpReward (default 10), passThreshold (default 70), hasQuiz
/// - GrammarQuizQuestion: lessonId, questionText, options, explanation, order
/// - UserGrammarProgress: userId, lessonId, isCompleted, completedAt, lastAccessedAt
/// - UserQuizAttempt: userId, lessonId, answers, score, isPassed, xpEarned,
///   isFirstCompletionToday
library;

class GrammarTopicModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? thumbnailUrl;
  final int lessonCount;
  final int completedLessons;
  final int order;
  final bool isActive;
  final DateTime? createdAt;

  const GrammarTopicModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.thumbnailUrl,
    this.lessonCount = 0,
    this.completedLessons = 0,
    this.order = 0,
    this.isActive = true,
    this.createdAt,
  });

  /// Tính phần trăm hoàn thành topic.
  double get progressPercent =>
      lessonCount > 0 ? completedLessons / lessonCount : 0.0;

  factory GrammarTopicModel.fromJson(Map<String, dynamic> json) {
    return GrammarTopicModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      slug: (json["slug"] ?? "").toString(),
      description: _stringOrNull(json["description"]),
      thumbnailUrl: _stringOrNull(json["thumbnailUrl"]),
      // Backend trả về totalLessons hoặc lessonCount
      lessonCount: _intOrDefault(json["totalLessons"] ?? json["lessonCount"]),
      // Backend trả về completedLessons
      completedLessons: _intOrDefault(json["completedLessons"]),
      order: _intOrDefault(json["order"]),
      isActive: json["isActive"] ?? true,
      createdAt: _dateOrNull(json["createdAt"]),
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }

  static DateTime? _dateOrNull(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "slug": slug,
        if (description != null) "description": description,
        if (thumbnailUrl != null) "thumbnailUrl": thumbnailUrl,
        "lessonCount": lessonCount,
        "completedLessons": completedLessons,
        "order": order,
        "isActive": isActive,
        if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
      };
}

class GrammarLessonModel {
  final String id;
  final String? topicId;
  final String? topicName;
  final String title;
  final String slug;
  final String? shortDescription;
  final String? htmlContent;
  final String? plainTextContent;
  final String? thumbnailUrl;
  final int estimatedTime;
  final int order;
  final bool isPublished;
  final bool isActive;
  final int xpReward;
  final int passThreshold;
  final bool hasQuiz;
  /// Trạng thái hoàn thành của user (true nếu đã pass quiz).
  final bool isCompleted;
  /// Số sao đạt được (0-3). Tính ở client dựa trên score.
  final int stars;
  /// Điểm cao nhất đã đạt được.
  final int bestScore;
  final DateTime? createdAt;

  const GrammarLessonModel({
    required this.id,
    this.topicId,
    this.topicName,
    required this.title,
    required this.slug,
    this.shortDescription,
    this.htmlContent,
    this.plainTextContent,
    this.thumbnailUrl,
    this.estimatedTime = 0,
    this.order = 0,
    this.isPublished = true,
    this.isActive = true,
    this.xpReward = 10,
    this.passThreshold = 70,
    this.hasQuiz = true,
    this.isCompleted = false,
    this.stars = 0,
    this.bestScore = 0,
    this.createdAt,
  });

  /// Tính số sao dựa trên điểm số và ngưỡng pass.
  /// Quy tắc: score >= 90 → 3 sao, >= 80 → 2 sao, >= passThreshold → 1 sao.
  static int calculateStars(int score, int passThreshold) {
    if (score >= 90) return 3;
    if (score >= 80) return 2;
    if (score >= passThreshold) return 1;
    return 0;
  }

  factory GrammarLessonModel.fromJson(Map<String, dynamic> json) {
    final score = _intOrDefault(json["bestScore"]);
    final passThres = _intOrDefault(json["passThreshold"], defaultValue: 70);
    return GrammarLessonModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      topicId: _stringOrNull(json["topicId"]),
      topicName: _stringOrNull(json["topicName"]),
      title: (json["title"] ?? "").toString(),
      slug: (json["slug"] ?? "").toString(),
      shortDescription: _stringOrNull(json["shortDescription"]),
      htmlContent: _stringOrNull(json["htmlContent"]),
      plainTextContent: _stringOrNull(json["plainTextContent"]),
      thumbnailUrl: _stringOrNull(json["thumbnailUrl"]),
      estimatedTime: _intOrDefault(json["estimatedTime"]),
      order: _intOrDefault(json["order"]),
      isPublished: json["isPublished"] ?? true,
      isActive: json["isActive"] ?? true,
      xpReward: _intOrDefault(json["xpReward"], defaultValue: 10),
      passThreshold: passThres,
      hasQuiz: json["hasQuiz"] ?? true,
      isCompleted: json["isCompleted"] ?? false,
      stars: calculateStars(score, passThres),
      bestScore: score,
      createdAt: _dateOrNull(json["createdAt"]),
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  static int _intOrDefault(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    return int.tryParse((value ?? defaultValue.toString()).toString()) ??
        defaultValue;
  }

  static DateTime? _dateOrNull(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  GrammarLessonModel copyWith({
    String? id,
    String? topicId,
    String? topicName,
    String? title,
    String? slug,
    String? shortDescription,
    String? htmlContent,
    String? plainTextContent,
    String? thumbnailUrl,
    int? estimatedTime,
    int? order,
    bool? isPublished,
    bool? isActive,
    int? xpReward,
    int? passThreshold,
    bool? hasQuiz,
    bool? isCompleted,
    int? stars,
    int? bestScore,
    DateTime? createdAt,
  }) {
    return GrammarLessonModel(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      shortDescription: shortDescription ?? this.shortDescription,
      htmlContent: htmlContent ?? this.htmlContent,
      plainTextContent: plainTextContent ?? this.plainTextContent,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      order: order ?? this.order,
      isPublished: isPublished ?? this.isPublished,
      isActive: isActive ?? this.isActive,
      xpReward: xpReward ?? this.xpReward,
      passThreshold: passThreshold ?? this.passThreshold,
      hasQuiz: hasQuiz ?? this.hasQuiz,
      isCompleted: isCompleted ?? this.isCompleted,
      stars: stars ?? this.stars,
      bestScore: bestScore ?? this.bestScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        if (topicId != null) "topicId": topicId,
        if (topicName != null) "topicName": topicName,
        "title": title,
        "slug": slug,
        if (shortDescription != null) "shortDescription": shortDescription,
        if (htmlContent != null) "htmlContent": htmlContent,
        if (plainTextContent != null) "plainTextContent": plainTextContent,
        if (thumbnailUrl != null) "thumbnailUrl": thumbnailUrl,
        "estimatedTime": estimatedTime,
        "order": order,
        "isPublished": isPublished,
        "isActive": isActive,
        "xpReward": xpReward,
        "passThreshold": passThreshold,
        "hasQuiz": hasQuiz,
        "isCompleted": isCompleted,
        "stars": stars,
        "bestScore": bestScore,
        if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
      };
}

/// Câu hỏi trắc nghiệm (lấy từ /quiz-play, KHÔNG có isCorrect/explanation).
class GrammarQuizQuestionModel {
  final String id;
  final String lessonId;
  final String questionText;
  final List<QuizOptionModel> options;
  final int order;

  const GrammarQuizQuestionModel({
    required this.id,
    required this.lessonId,
    required this.questionText,
    required this.options,
    this.order = 0,
  });

  factory GrammarQuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return GrammarQuizQuestionModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      lessonId: (json["lessonId"] ?? "").toString(),
      questionText: (json["questionText"] ?? "").toString(),
      options: (json["options"] as List<dynamic>?)
              ?.map((o) => QuizOptionModel.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      order: _intOrDefault(json["order"]),
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }
}

/// Một lựa chọn trong câu hỏi trắc nghiệm.
class QuizOptionModel {
  final String text;

  const QuizOptionModel({required this.text});

  factory QuizOptionModel.fromJson(Map<String, dynamic> json) {
    return QuizOptionModel(
      text: (json["text"] ?? "").toString(),
    );
  }
}

/// Kết quả chi tiết của một câu hỏi sau khi submit.
class QuizQuestionResult {
  final String questionId;
  final int selectedIndex;
  final int correctIndex;
  final bool isCorrect;
  final String explanation;

  const QuizQuestionResult({
    required this.questionId,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
    required this.explanation,
  });

  factory QuizQuestionResult.fromJson(Map<String, dynamic> json) {
    return QuizQuestionResult(
      questionId: (json["questionId"] ?? "").toString(),
      selectedIndex: _intOrDefault(json["selectedIndex"]),
      correctIndex: _intOrDefault(json["correctIndex"]),
      isCorrect: json["isCorrect"] ?? false,
      explanation: (json["explanation"] ?? "").toString(),
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "-1").toString()) ?? -1;
  }
}

/// Kết quả submit quiz (trả về từ backend).
class QuizSubmitResultModel {
  final String lessonId;
  final double score;
  final int passThreshold;
  final bool isPassed;
  final List<QuizQuestionResult> result;
  final int xpEarned;
  final int? newXp;
  final int? newStreak;
  final int? longestStreak;
  final bool streakUpdated;
  final bool isFirstCompletionToday;
  final bool alreadyPassed;

  const QuizSubmitResultModel({
    required this.lessonId,
    required this.score,
    required this.passThreshold,
    required this.isPassed,
    required this.result,
    this.xpEarned = 0,
    this.newXp,
    this.newStreak,
    this.longestStreak,
    this.streakUpdated = false,
    this.isFirstCompletionToday = false,
    this.alreadyPassed = false,
  });

  /// Tính số sao dựa trên score.
  int get stars => GrammarLessonModel.calculateStars(score.round(), passThreshold);

  /// Số câu đúng.
  int get correctCount => result.where((r) => r.isCorrect).length;

  /// Tổng số câu.
  int get totalQuestions => result.length;

  factory QuizSubmitResultModel.fromJson(Map<String, dynamic> json) {
    return QuizSubmitResultModel(
      lessonId: (json["lessonId"] ?? "").toString(),
      score: _doubleOrDefault(json["score"]),
      passThreshold: _intOrDefault(json["passThreshold"], defaultValue: 70),
      isPassed: json["isPassed"] ?? false,
      result: (json["result"] as List<dynamic>?)
              ?.map((r) => QuizQuestionResult.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      xpEarned: _intOrDefault(json["xpEarned"]),
      newXp: json["newXp"] is int ? json["newXp"] : null,
      newStreak: json["newStreak"] is int ? json["newStreak"] : null,
      longestStreak: json["longestStreak"] is int ? json["longestStreak"] : null,
      streakUpdated: json["streakUpdated"] ?? false,
      isFirstCompletionToday: json["isFirstCompletionToday"] ?? false,
      alreadyPassed: json["alreadyPassed"] ?? false,
    );
  }

  static int _intOrDefault(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    return int.tryParse((value ?? defaultValue.toString()).toString()) ??
        defaultValue;
  }

  static double _doubleOrDefault(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse((value ?? "0").toString()) ?? 0.0;
  }
}

/// Progress của user với một bài học Grammar.
class UserGrammarProgressModel {
  final String id;
  final String userId;
  final String lessonId;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? lastAccessedAt;

  const UserGrammarProgressModel({
    required this.id,
    required this.userId,
    required this.lessonId,
    this.isCompleted = false,
    this.completedAt,
    this.lastAccessedAt,
  });

  factory UserGrammarProgressModel.fromJson(Map<String, dynamic> json) {
    return UserGrammarProgressModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      userId: (json["userId"] ?? "").toString(),
      lessonId: (json["lessonId"] ?? "").toString(),
      isCompleted: json["isCompleted"] ?? false,
      completedAt: _dateOrNull(json["completedAt"]),
      lastAccessedAt: _dateOrNull(json["lastAccessedAt"]),
    );
  }

  static DateTime? _dateOrNull(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
