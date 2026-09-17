class TableSessionStatus {
  final String tableNumber;
  final String branch;
  final String status; // active | closed | expired
  final bool isActive;
  final int remainingSeconds;
  final String formattedRemaining;
  final String? openedBy;

  const TableSessionStatus({
    required this.tableNumber,
    required this.branch,
    required this.status,
    required this.isActive,
    this.remainingSeconds = 0,
    this.formattedRemaining = 'Closed',
    this.openedBy,
  });

  bool get isLocked => !isActive || status != 'active';
  bool get isExpired => status == 'expired';

  factory TableSessionStatus.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as String? ?? 'closed').toLowerCase();
    final isActive = json['is_active'] == true || status == 'active';
    return TableSessionStatus(
      tableNumber: json['table_number']?.toString() ?? '',
      branch: json['branch']?.toString() ?? 'Bulihan',
      status: status,
      isActive: isActive,
      remainingSeconds: json['remaining_seconds'] is num
          ? (json['remaining_seconds'] as num).toInt()
          : int.tryParse(json['remaining_seconds']?.toString() ?? '') ?? 0,
      formattedRemaining: json['formatted_remaining']?.toString() ?? 'Closed',
      openedBy: json['opened_by']?.toString(),
    );
  }

  /// Safe fallback when API is unreachable — treat as locked so staff must open.
  factory TableSessionStatus.lockedFallback(String tableNumber, {String branch = 'Bulihan'}) {
    return TableSessionStatus(
      tableNumber: tableNumber,
      branch: branch,
      status: 'closed',
      isActive: false,
    );
  }
}
