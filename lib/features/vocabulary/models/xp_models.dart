class XpInfoModel {
  final int totalXp;
  final int currentLevel;
  final int xpInLevel;
  final int xpToNextLevel;
  final double progressInLevel;
  final int xpPerLevel;

  const XpInfoModel({
    this.totalXp = 0,
    this.currentLevel = 1,
    this.xpInLevel = 0,
    this.xpToNextLevel = 100,
    this.progressInLevel = 0.0,
    this.xpPerLevel = 100,
  });

  factory XpInfoModel.fromJson(Map<String, dynamic> json) {
    return XpInfoModel(
      totalXp: _intOrDefault(json["totalXP"]),
      currentLevel: _intOrDefault(json["currentLevel"]),
      xpInLevel: _intOrDefault(json["xpInLevel"]),
      xpToNextLevel: _intOrDefault(json["xpToNextLevel"]),
      progressInLevel: _doubleOrDefault(json["progressInLevel"]),
      xpPerLevel: _intOrDefault(json["xpPerLevel"]),
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }

  static double _doubleOrDefault(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse((value ?? "0").toString()) ?? 0.0;
  }
}

class XpHistoryItemModel {
  final String id;
  final String userId;
  final int amount;
  final String reason;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  const XpHistoryItemModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  factory XpHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return XpHistoryItemModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      userId: (json["userId"] ?? "").toString(),
      amount: _intOrDefault(json["amount"]),
      reason: (json["reason"] ?? "").toString(),
      referenceId: _stringOrNull(json["referenceId"]),
      description: _stringOrNull(json["description"]),
      createdAt: _dateOrDefault(json["createdAt"]) ?? DateTime.now(),
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  static DateTime? _dateOrDefault(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String get displayReason {
    final reasonMap = {
      "quiz_correct": "Câu trả lời đúng",
      "level_complete": "Hoàn thành cấp độ",
      "lesson_complete": "Hoàn thành bài học",
      "streak_bonus": "Thưởng streak",
      "perfect_score": "Điểm hoàn hảo",
      "daily_bonus": "Thưởng hàng ngày",
    };
    return reasonMap[reason] ?? reason;
  }

  bool get isPositive => amount > 0;
}

class XpSummaryModel {
  final int todayXp;
  final int weekXp;
  final int totalTransactions;

  const XpSummaryModel({
    this.todayXp = 0,
    this.weekXp = 0,
    this.totalTransactions = 0,
  });

  factory XpSummaryModel.fromJson(Map<String, dynamic> json) {
    return XpSummaryModel(
      todayXp: _intOrDefault(json["todayXP"]),
      weekXp: _intOrDefault(json["weekXP"]),
      totalTransactions: _intOrDefault(json["totalTransactions"]),
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }
}

class StreakInfoModel {
  final int currentStreak;
  final int longestStreak;
  final int freezeCount;
  final String timezone;
  final bool studiedToday;
  final bool streakAtRisk;
  final DateTime? lastActivityDate;

  const StreakInfoModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.freezeCount = 0,
    this.timezone = "Asia/Ho_Chi_Minh",
    this.studiedToday = false,
    this.streakAtRisk = false,
    this.lastActivityDate,
  });

  factory StreakInfoModel.fromJson(Map<String, dynamic> json) {
    return StreakInfoModel(
      currentStreak: _intOrDefault(json["currentStreak"]),
      longestStreak: _intOrDefault(json["longestStreak"]),
      freezeCount: _intOrDefault(json["freezeCount"]),
      timezone: (json["timezone"] ?? "Asia/Ho_Chi_Minh").toString(),
      studiedToday: json["studiedToday"] ?? false,
      streakAtRisk: json["streakAtRisk"] ?? false,
      lastActivityDate: _dateOrDefault(json["lastActivityDate"]),
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }

  static DateTime? _dateOrDefault(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class StreakCalendarDayModel {
  final String date;
  final bool studied;
  final bool isToday;

  const StreakCalendarDayModel({
    required this.date,
    this.studied = false,
    this.isToday = false,
  });

  factory StreakCalendarDayModel.fromJson(Map<String, dynamic> json) {
    return StreakCalendarDayModel(
      date: (json["date"] ?? "").toString(),
      studied: json["studied"] ?? false,
      isToday: json["isToday"] ?? false,
    );
  }
}

class StreakCalendarModel {
  final int currentStreak;
  final int longestStreak;
  final int freezeCount;
  final List<StreakCalendarDayModel> calendar;

  const StreakCalendarModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.freezeCount = 0,
    this.calendar = const [],
  });

  factory StreakCalendarModel.fromJson(Map<String, dynamic> json) {
    return StreakCalendarModel(
      currentStreak: _intOrDefault(json["currentStreak"]),
      longestStreak: _intOrDefault(json["longestStreak"]),
      freezeCount: _intOrDefault(json["freezeCount"]),
      calendar: (json["calendar"] as List<dynamic>?)
              ?.map((c) => StreakCalendarDayModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "0").toString()) ?? 0;
  }
}
