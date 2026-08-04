class ReadingPassage {
  final String id;
  final String categoryId;
  final String title;
  final String slug;
  final String description;
  final String thumbnail;
  final String htmlContent;
  final String plainText;
  final String difficulty; // beginner, elementary, intermediate, upper_intermediate, advanced
  final String cefrLevel; // A1, A2, B1, B2, C1, C2
  final String readingType; // academic, article, general, story, etc.
  final List<String> tags;
  final int wordCount;
  final int estimatedTime; // in minutes
  final int xpReward;
  final int passThreshold; // percentage e.g. 70
  final bool hasQuestions;
  final String status; // draft, published, archived
  final List<dynamic> allowedPackageIds;

  const ReadingPassage({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.slug,
    this.description = '',
    this.thumbnail = '',
    this.htmlContent = '',
    this.plainText = '',
    this.difficulty = 'intermediate',
    this.cefrLevel = 'B1',
    this.readingType = 'article',
    this.tags = const [],
    this.wordCount = 0,
    this.estimatedTime = 5,
    this.xpReward = 15,
    this.passThreshold = 70,
    this.hasQuestions = false,
    this.status = 'published',
    this.allowedPackageIds = const [],
  });

  factory ReadingPassage.fromJson(Map<String, dynamic> json) {
    String catId = '';
    if (json['categoryId'] != null) {
      if (json['categoryId'] is Map) {
        catId = (json['categoryId']['_id'] ?? json['categoryId']['id'] ?? '').toString();
      } else {
        catId = json['categoryId'].toString();
      }
    }

    return ReadingPassage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      categoryId: catId,
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      thumbnail: (json['thumbnail'] ?? '').toString(),
      htmlContent: (json['htmlContent'] ?? '').toString(),
      plainText: (json['plainText'] ?? '').toString(),
      difficulty: (json['difficulty'] ?? 'intermediate').toString(),
      cefrLevel: (json['cefrLevel'] ?? 'B1').toString(),
      readingType: (json['readingType'] ?? 'article').toString(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
      estimatedTime: (json['estimatedTime'] as num?)?.toInt() ?? 5,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 15,
      passThreshold: (json['passThreshold'] as num?)?.toInt() ?? 70,
      hasQuestions: json['hasQuestions'] ?? false,
      status: (json['status'] ?? 'published').toString(),
      allowedPackageIds: json['allowedPackageIds'] as List<dynamic>? ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'categoryId': categoryId,
      'title': title,
      'slug': slug,
      'description': description,
      'thumbnail': thumbnail,
      'htmlContent': htmlContent,
      'plainText': plainText,
      'difficulty': difficulty,
      'cefrLevel': cefrLevel,
      'readingType': readingType,
      'tags': tags,
      'wordCount': wordCount,
      'estimatedTime': estimatedTime,
      'xpReward': xpReward,
      'passThreshold': passThreshold,
      'hasQuestions': hasQuestions,
      'status': status,
    };
  }
}
