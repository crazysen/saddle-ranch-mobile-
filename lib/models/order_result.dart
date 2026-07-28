class OrderResult {
  final int id;
  final String orderNumber;
  final String orderType;
  final String? tableNumber;
  final String status;
  final double totalAmount;
  final String paymentMethod;

  const OrderResult({
    required this.id,
    required this.orderNumber,
    required this.orderType,
    this.tableNumber,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    return OrderResult(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String? ?? '',
      orderType: json['order_type'] as String? ?? '',
      tableNumber: json['table_number'] as String?,
      status: json['status'] as String? ?? 'pending',
      totalAmount: _toDouble(json['total_amount']),
      paymentMethod: json['payment_method'] as String? ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
