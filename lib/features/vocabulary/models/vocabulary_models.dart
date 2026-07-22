class VocabularyTopicModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? thumbnail;
  final int lessonCount;
  final int wordCount;
  final int order;
  final bool isActive;
  final DateTime? createdAt;

  const VocabularyTopicModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.thumbnail,
    this.lessonCount = 0,
    this.wordCount = 0,
    this.order = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory VocabularyTopicModel.fromJson(Map<String, dynamic> json) {
    return VocabularyTopicModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      slug: (json["slug"] ?? "").toString(),
      description: _stringOrNull(json["description"]),
      thumbnail: _stringOrNull(json["thumbnail"]),
      lessonCount: _intOrDefault(json["lessonCount"]),
      wordCount: _intOrDefault(json["wordCount"]),
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
        if (thumbnail != null) "thumbnail": thumbnail,
        "lessonCount": lessonCount,
        "wordCount": wordCount,
        "order": order,
        "isActive": isActive,
        if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
      };
}

class VocabularyLessonModel {
  final String id;
  final String title;
  final String? description;
  final String? topicId;
  final String? topicName;
  final String slug;
  final String? thumbnail;
  final int estimatedTime;
  final int wordCount;
  final int order;
  final bool isActive;
  final DateTime? createdAt;

  const VocabularyLessonModel({
    required this.id,
    required this.title,
    this.description,
    this.topicId,
    this.topicName,
    required this.slug,
    this.thumbnail,
    this.estimatedTime = 0,
    this.wordCount = 0,
    this.order = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory VocabularyLessonModel.fromJson(Map<String, dynamic> json) {
    return VocabularyLessonModel(
      id: (json["_id"] ?? json["id"] ?? "").toString(),
      title: (json["title"] ?? "").toString(),
      description: _stringOrNull(json["description"]),
      topicId: _stringOrNull(json["topicId"]),
      topicName: _stringOrNull(json["topicName"]),
      slug: (json["slug"] ?? "").toString(),
      thumbnail: _stringOrNull(json["thumbnail"]),
      estimatedTime: _intOrDefault(json["estimatedTime"]),
      wordCount: _intOrDefault(json["wordCount"]),
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
        "title": title,
        if (description != null) "description": description,
        if (topicId != null) "topicId": topicId,
        if (topicName != null) "topicName": topicName,
        "slug": slug,
        if (thumbnail != null) "thumbnail": thumbnail,
        "estimatedTime": estimatedTime,
        "wordCount": wordCount,
        "order": order,
        "isActive": isActive,
        if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
      };
}

class StudyWordModel {
  final String lessonWordId;
  final String wordId;
  final String word;
  final PronunciationsModel pronunciations;
  final AudioUrlsModel audioUrls;
  final String? imageUrl;
  final String difficulty;
  final String meaningId;
  final String meaning;
  final String partOfSpeech;
  final String? exampleSentence;
  final String? exampleMeaning;
  final bool isPrimary;
  final int order;

  const StudyWordModel({
    required this.lessonWordId,
    required this.wordId,
    required this.word,
    required this.pronunciations,
    required this.audioUrls,
    this.imageUrl,
    required this.difficulty,
    required this.meaningId,
    required this.meaning,
    required this.partOfSpeech,
    this.exampleSentence,
    this.exampleMeaning,
    this.isPrimary = false,
    this.order = 1,
  });

  factory StudyWordModel.fromJson(Map<String, dynamic> json) {
    return StudyWordModel(
      lessonWordId: (json["lessonWordId"] ?? "").toString(),
      wordId: (json["wordId"] ?? "").toString(),
      word: (json["word"] ?? "").toString(),
      pronunciations: PronunciationsModel.fromJson(json["pronunciations"] ?? {}),
      audioUrls: AudioUrlsModel.fromJson(json["audioUrls"] ?? {}),
      imageUrl: _stringOrNull(json["imageUrl"]),
      difficulty: (json["difficulty"] ?? "easy").toString(),
      meaningId: (json["meaningId"] ?? "").toString(),
      meaning: (json["meaning"] ?? "").toString(),
      partOfSpeech: (json["partOfSpeech"] ?? "").toString(),
      exampleSentence: _stringOrNull(json["exampleSentence"]),
      exampleMeaning: _stringOrNull(json["exampleMeaning"]),
      isPrimary: json["isPrimary"] ?? false,
      order: _intOrDefault(json["order"]),
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  static int _intOrDefault(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? "1").toString()) ?? 1;
  }

  String get displayPartOfSpeech {
    const posMap = {
      "noun": "Danh từ",
      "verb": "Động từ",
      "adjective": "Tính từ",
      "adverb": "Trạng từ",
      "pronoun": "Đại từ",
      "preposition": "Giới từ",
      "conjunction": "Liên từ",
      "interjection": "Thán từ",
      "other": "Khác",
    };
    return posMap[partOfSpeech.toLowerCase()] ?? partOfSpeech;
  }
}

class PronunciationsModel {
  final String us;
  final String uk;

  const PronunciationsModel({
    this.us = "",
    this.uk = "",
  });

  factory PronunciationsModel.fromJson(Map<String, dynamic> json) {
    return PronunciationsModel(
      us: (json["us"] ?? "").toString(),
      uk: (json["uk"] ?? "").toString(),
    );
  }
}

class AudioUrlsModel {
  final String us;
  final String uk;

  const AudioUrlsModel({
    this.us = "",
    this.uk = "",
  });

  factory AudioUrlsModel.fromJson(Map<String, dynamic> json) {
    return AudioUrlsModel(
      us: (json["us"] ?? "").toString(),
      uk: (json["uk"] ?? "").toString(),
    );
  }

  bool get hasAudio => us.isNotEmpty || uk.isNotEmpty;
}

class LessonStudyData {
  final VocabularyLessonModel lesson;
  final int totalWords;
  final List<StudyWordModel> words;

  const LessonStudyData({
    required this.lesson,
    required this.totalWords,
    required this.words,
  });

  factory LessonStudyData.fromJson(Map<String, dynamic> json) {
    return LessonStudyData(
      lesson: VocabularyLessonModel.fromJson(json["lesson"] ?? {}),
      totalWords: json["totalWords"] ?? 0,
      words: (json["words"] as List<dynamic>?)
              ?.map((w) => StudyWordModel.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
