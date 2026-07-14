/// Model cho nhóm ngành (OccupationCategory) trả về từ
/// `GET /api/occupation-categories`.
class OccupationCategoryModel {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  const OccupationCategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
  });

  factory OccupationCategoryModel.fromJson(Map<String, dynamic> json) {
    return OccupationCategoryModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isActive: json['isActive'] is bool
          ? json['isActive'] as bool
          : (json['isActive']?.toString() != 'false'),
    );
  }
}

/// Model cho nghề nghiệp (Occupation) trả về từ
/// `GET /api/occupations` và `GET /api/occupations/category/:id`.
class OccupationModel {
  final String id;
  final String name;
  final String categoryId;
  final String description;
  final bool isActive;

  const OccupationModel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.description = '',
    this.isActive = true,
  });

  factory OccupationModel.fromJson(Map<String, dynamic> json) {
    String? readString(Object? value) {
      if (value == null) return null;
      final str = value.toString();
      if (str.isEmpty) return null;
      return str;
    }

    final rawCat = json['categoryId'];
    final catId = rawCat is Map
        ? readString(rawCat['_id']) ?? ''
        : readString(rawCat) ?? '';

    return OccupationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      categoryId: catId,
      description: (json['description'] ?? '').toString(),
      isActive: json['isActive'] is bool
          ? json['isActive'] as bool
          : (json['isActive']?.toString() != 'false'),
    );
  }
}