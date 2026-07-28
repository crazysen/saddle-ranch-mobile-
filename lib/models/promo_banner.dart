class PromoBanner {
  final int id;
  final String title;
  final String? subtitle;
  final String? badge;
  final String? imagePath;
  final bool isActive;
  final int displayOrder;

  const PromoBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.badge,
    this.imagePath,
    required this.isActive,
    required this.displayOrder,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? json['description'] as String?,
      badge: json['badge'] as String?,
      imagePath: json['image_path'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }
}
