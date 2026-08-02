/// Model cho gói thành viên từ API /packages
class PackageModel {
  final String id;
  final String name;
  final String slug;
  final int level;
  final int price;
  final String currency;
  final int? durationInDays;
  final String description;
  final List<String> features;
  final bool isActive;

  const PackageModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.level,
    required this.price,
    required this.currency,
    this.durationInDays,
    required this.description,
    required this.features,
    required this.isActive,
  });

  bool get isFree => slug == 'free' || price == 0;

  String get priceDisplay {
    if (isFree) return 'Miễn phí';
    return '${_formatVnd(price)}₫';
  }

  String get durationDisplay {
    if (durationInDays == null) return 'Vĩnh viễn';
    if (durationInDays == 30) return '1 tháng';
    if (durationInDays == 90) return '3 tháng';
    if (durationInDays == 365) return '1 năm';
    return '$durationInDays ngày';
  }

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      level: (json['level'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? 'VND').toString(),
      durationInDays: (json['durationInDays'] as num?)?.toInt(),
      description: (json['description'] ?? '').toString(),
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['isActive'] ?? true,
    );
  }

  static String _formatVnd(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

/// Model cho subscription hiện tại của user
class SubscriptionModel {
  final String id;
  final String packageId;
  final String packageName;
  final String packageSlug;
  final int packageLevel;
  final String status; // active | expired | cancelled | pending_payment
  final DateTime? startAt;
  final DateTime? endAt;

  const SubscriptionModel({
    required this.id,
    required this.packageId,
    required this.packageName,
    required this.packageSlug,
    required this.packageLevel,
    required this.status,
    this.startAt,
    this.endAt,
  });

  bool get isActive => status == 'active';

  bool get isExpiringSoon {
    if (endAt == null) return false;
    return endAt!.difference(DateTime.now()).inDays <= 7;
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final pkg = json['packageId'];
    return SubscriptionModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      packageId: pkg is Map ? (pkg['_id'] ?? '').toString() : (pkg ?? '').toString(),
      packageName: pkg is Map ? (pkg['name'] ?? '').toString() : '',
      packageSlug: pkg is Map ? (pkg['slug'] ?? '').toString() : '',
      packageLevel: pkg is Map ? (pkg['level'] as num?)?.toInt() ?? 0 : 0,
      status: (json['status'] ?? 'pending_payment').toString(),
      startAt: json['startAt'] != null ? DateTime.tryParse(json['startAt'].toString()) : null,
      endAt: json['endAt'] != null ? DateTime.tryParse(json['endAt'].toString()) : null,
    );
  }
}
