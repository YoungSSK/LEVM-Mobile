class AppRoutes {
  AppRoutes._();

  static const String splash = "/";
  static const String login = "/login";
  static const String register = "/register";
  static const String home = "/home";
  static const String profile = "/profile";
  static const String editProfile = "/profile/edit";
  static const String changePassword = "/profile/change-password";

  // Vocabulary routes
  static const String vocabularyTopics = "/vocabulary/topics";
  static const String vocabularyLessons = "/vocabulary/topics/:topicId/lessons";
  static const String lessonDetail = "/vocabulary/lessons/:lessonId";
  static const String flashcard = "/vocabulary/lessons/:lessonId/flashcard";
  static const String wordRecall = "/vocabulary/lessons/:lessonId/recall";
  static const String spelling = "/vocabulary/lessons/:lessonId/spelling";
  static const String levelResult = "/vocabulary/result/:attemptId";
  static const String lessonSummary = "/vocabulary/summary/:lessonId";

  // Grammar routes
  static const String grammarTopics = "/grammar/topics";
  static const String grammarLessons = "/grammar/topics/:topicId/lessons";
  static const String grammarTheory = "/grammar/lessons/:lessonId/theory";
  static const String grammarQuiz = "/grammar/lessons/:lessonId/quiz";
  static const String grammarResult = "/grammar/lessons/:lessonId/result";
}
