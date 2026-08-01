class ReadingCategory {
  final String id;
  final String title;
  final String slug;
  final String description;
  final String? icon;
  final int order;
  final bool isActive;

  const ReadingCategory({
    required this.id,
    required this.title,
    required this.slug,
    this.description = '',
    this.icon,
    this.order = 0,
    this.isActive = true,
  });

  factory ReadingCategory.fromJson(Map<String, dynamic> json) {
    return ReadingCategory(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      icon: json['icon']?.toString() ?? json['thumbnail']?.toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'icon': icon,
      'order': order,
      'isActive': isActive,
    };
  }
}
