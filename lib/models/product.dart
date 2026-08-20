import '../utils/image_url_helper.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final double? priceBulihan;
  final double? priceDasmarinas;
  final String? imagePath;
  final int stockQuantity;
  final int stockBulihan;
  final int stockDasmarinas;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.priceBulihan,
    this.priceDasmarinas,
    this.imagePath,
    required this.stockQuantity,
    this.stockBulihan = 0,
    this.stockDasmarinas = 0,
    required this.isActive,
  });

  /// Price for a specific branch ('Bulihan' or 'Dasma'/'Dasmarinas')
  double priceForBranch(String? branch) {
    if (branch == null) return price;
    final b = branch.toLowerCase();
    if (b.contains('bulihan') && priceBulihan != null && priceBulihan! > 0) {
      return priceBulihan!;
    }
    if (b.contains('dasma') && priceDasmarinas != null && priceDasmarinas! > 0) {
      return priceDasmarinas!;
    }
    return price;
  }

  /// Stock quantity for a specific branch
  int stockForBranch(String? branch) {
    if (branch == null) return stockQuantity;
    final b = branch.toLowerCase();
    if (b.contains('bulihan')) {
      return stockBulihan > 0 ? stockBulihan : stockQuantity;
    }
    if (b.contains('dasma')) {
      return stockDasmarinas > 0 ? stockDasmarinas : stockQuantity;
    }
    return stockQuantity;
  }

  bool inStockForBranch(String? branch) => stockForBranch(branch) > 0;

  bool get inStock => stockQuantity > 0 || stockBulihan > 0 || stockDasmarinas > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: _toDouble(json['price']),
      priceBulihan: json['price_bulihan'] != null ? _toDouble(json['price_bulihan']) : null,
      priceDasmarinas: json['price_dasmarinas'] != null ? _toDouble(json['price_dasmarinas']) : null,
      imagePath: ImageUrlHelper.normalize(json['image_path'] as String?),
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      stockBulihan: json['stock_bulihan'] as int? ?? 0,
      stockDasmarinas: json['stock_dasmarinas'] as int? ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'price_bulihan': priceBulihan,
        'price_dasmarinas': priceDasmarinas,
        'image_path': imagePath,
        'stock_quantity': stockQuantity,
        'stock_bulihan': stockBulihan,
        'stock_dasmarinas': stockDasmarinas,
        'is_active': isActive,
      };

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
