class Voucher {
  final int id;
  final String code;
  final String discountType; // 'fixed' | 'percentage'
  final double value;
  final double minSpend;
  final bool isOneTimeUse;
  final bool isLimitedTime;
  final String? startsAt;
  final String? expiresAt;
  final int timesUsed;
  final String branch; // 'all' | 'bulihan' | 'dasmarinas'
  final bool isUsed;

  const Voucher({
    required this.id,
    required this.code,
    required this.discountType,
    required this.value,
    this.minSpend = 0.0,
    this.isOneTimeUse = false,
    this.isLimitedTime = false,
    this.startsAt,
    this.expiresAt,
    this.timesUsed = 0,
    this.branch = 'all',
    this.isUsed = false,
  });

  /// Computes discount amount based on subtotal according to spec formula
  double calculateDiscount(double subtotal) {
    if (subtotal < minSpend) return 0.0;
    if (discountType.toLowerCase() == 'percentage') {
      return (subtotal * (value / 100.0)).clamp(0.0, subtotal);
    } else {
      return value.clamp(0.0, subtotal);
    }
  }

  /// Calculates final total after discount
  double calculateFinalTotal(double subtotal) {
    final discount = calculateDiscount(subtotal);
    final total = subtotal - discount;
    return total < 0 ? 0.0 : total;
  }

  /// Returns user friendly discount label (e.g. "10% OFF" or "₱50 OFF")
  String get discountLabel {
    if (discountType.toLowerCase() == 'percentage') {
      return '${value.toInt()}% OFF';
    } else {
      return '₱${value.toInt()} OFF';
    }
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code'] as String? ?? '',
      discountType: json['discount_type'] as String? ?? 'percentage',
      value: _toDouble(json['value']),
      minSpend: _toDouble(json['min_spend']),
      isOneTimeUse: json['is_one_time_use'] == true || json['is_one_time_use'] == 1,
      isLimitedTime: json['is_limited_time'] == true || json['is_limited_time'] == 1,
      startsAt: json['starts_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      timesUsed: json['times_used'] is int ? json['times_used'] as int : int.tryParse(json['times_used']?.toString() ?? '0') ?? 0,
      branch: json['branch'] as String? ?? 'all',
      isUsed: json['is_used'] == true || json['is_used'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'discount_type': discountType,
        'value': value,
        'min_spend': minSpend,
        'is_one_time_use': isOneTimeUse,
        'is_limited_time': isLimitedTime,
        'starts_at': startsAt,
        'expires_at': expiresAt,
        'times_used': timesUsed,
        'branch': branch,
        'is_used': isUsed,
      };

  static double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '') ?? 0.0;
  }
}
