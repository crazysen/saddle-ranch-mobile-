class OrderItemModel {
  final int? id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const OrderItemModel({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final prod = json['product'] is Map<String, dynamic> ? json['product'] as Map<String, dynamic> : null;
    final pId = json['product_id'] is num
        ? (json['product_id'] as num).toInt()
        : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0;
    final name = (prod?['name'] ?? json['product_name'] ?? json['name'] ?? 'Item #$pId').toString();
    final qty = json['quantity'] is num
        ? (json['quantity'] as num).toInt()
        : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1;
    final price = _toDouble(json['unit_price'] ?? json['price']);
    final sub = _toDouble(json['subtotal'] ?? (price * qty));

    return OrderItemModel(
      id: json['id'] is num ? (json['id'] as num).toInt() : null,
      productId: pId,
      productName: name,
      quantity: qty,
      unitPrice: price,
      subtotal: sub,
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'subtotal': subtotal,
      };

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class OrderResult {
  final int id;
  final int? userId;
  final String orderNumber;
  final String branch;
  final String orderType; // 'dine_in' | 'express_takeout' | 'pickup' | 'delivery'
  final String? tableNumber;
  final String status; // 'pending' | 'preparing' | 'ready' | 'completed' | 'cancelled'
  final double totalAmount;
  final String paymentMethod;
  final String? voucherCode;
  final double discountAmount;
  final String? customerName;
  final String? customerPhone;
  final String? deliveryAddress;
  final String? deliveryNotes;
  final String? createdAt;
  final List<OrderItemModel> items;

  const OrderResult({
    required this.id,
    this.userId,
    required this.orderNumber,
    this.branch = 'Bulihan',
    required this.orderType,
    this.tableNumber,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    this.voucherCode,
    this.discountAmount = 0.0,
    this.customerName,
    this.customerPhone,
    this.deliveryAddress,
    this.deliveryNotes,
    this.createdAt,
    this.items = const [],
  });

  /// User friendly status label without emojis
  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Received';
      case 'preparing':
        return 'Sizzling on the Grill';
      case 'ready':
        return 'Ready for Pickup';
      case 'delivering':
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'completed':
        return 'Order Completed';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Live status message for Customer Tracker / Notifications from ORDER_LIFECYCLE_SPEC.md Section 7.B
  String get statusDescription {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'We have received your order. Sent to the kitchen grill.';
      case 'preparing':
        return 'Chef is preparing your sizzling dishes right now!';
      case 'ready':
        return 'Your food is cooked and ready at the dispatch counter!';
      case 'delivering':
      case 'out_for_delivery':
        return 'Rider is on the way with your sizzling favorites!';
      case 'completed':
        return 'Enjoy your meal! Thank you for dining with Saddle Ranch.';
      case 'cancelled':
        return 'This order was cancelled. Please check with our staff.';
      default:
        return 'Order is currently ${status.replaceAll('_', ' ')}.';
    }
  }

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['order_items'] ?? json['items']) as List<dynamic>? ?? [];
    final parsedItems = rawItems
        .whereType<Map<String, dynamic>>()
        .map((i) => OrderItemModel.fromJson(i))
        .toList();

    return OrderResult(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is num ? (json['user_id'] as num).toInt() : null,
      orderNumber: json['order_number'] as String? ?? json['orderNumber'] as String? ?? 'SR-0000',
      branch: json['branch'] as String? ?? 'Bulihan',
      orderType: json['order_type'] as String? ?? 'pickup',
      tableNumber: json['table_number'] as String?,
      status: json['status'] as String? ?? 'pending',
      totalAmount: _toDouble(json['total_amount'] ?? json['total']),
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      voucherCode: json['voucher_code'] as String?,
      discountAmount: _toDouble(json['discount_amount']),
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryNotes: json['delivery_notes'] as String?,
      createdAt: json['created_at'] as String?,
      items: parsedItems,
    );
  }

  OrderResult copyWith({
    int? id,
    int? userId,
    String? orderNumber,
    String? branch,
    String? orderType,
    String? tableNumber,
    String? status,
    double? totalAmount,
    String? paymentMethod,
    String? voucherCode,
    double? discountAmount,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? deliveryNotes,
    String? createdAt,
    List<OrderItemModel>? items,
  }) {
    return OrderResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber ?? this.orderNumber,
      branch: branch ?? this.branch,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      voucherCode: voucherCode ?? this.voucherCode,
      discountAmount: discountAmount ?? this.discountAmount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'order_number': orderNumber,
        'branch': branch,
        'order_type': orderType,
        'table_number': tableNumber,
        'status': status,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'voucher_code': voucherCode,
        'discount_amount': discountAmount,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'delivery_address': deliveryAddress,
        'delivery_notes': deliveryNotes,
        'created_at': createdAt,
        'order_items': items.map((i) => i.toJson()).toList(),
      };

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
