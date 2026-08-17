import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String? branch;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.branch,
  });

  double get unitPrice => product.priceForBranch(branch);

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toOrderJson() => {
        'product_id': product.id,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };
}
