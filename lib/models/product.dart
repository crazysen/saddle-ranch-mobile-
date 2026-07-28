class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? imagePath;
  final int stockQuantity;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imagePath,
    required this.stockQuantity,
    required this.isActive,
  });

  bool get inStock => stockQuantity > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _toDouble(json['price']),
      imagePath: json['image_path'] as String?,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
