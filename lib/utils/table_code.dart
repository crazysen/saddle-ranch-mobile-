/// Helpers for dine-in table QR codes (e.g. B-08, D-03, 08).
class TableCode {
  TableCode._();

  /// Digits only, zero-padded: B-08 / 8 / 08 → 08
  static String digits(String raw) {
    final cleaned = raw.trim().toUpperCase();
    final prefixed = RegExp(r'^[BD]-(\d+)$').firstMatch(cleaned);
    if (prefixed != null) {
      return prefixed.group(1)!.padLeft(2, '0');
    }
    final only = RegExp(r'(\d+)').firstMatch(cleaned);
    if (only != null) {
      return only.group(1)!.padLeft(2, '0');
    }
    return cleaned;
  }

  /// Canonical display / API code from QR (keeps B-/D- when present).
  static String normalize(String raw) {
    final cleaned = raw.trim().toUpperCase();
    final prefixed = RegExp(r'^([BD])-(\d+)$').firstMatch(cleaned);
    if (prefixed != null) {
      return '${prefixed.group(1)}-${prefixed.group(2)!.padLeft(2, '0')}';
    }
    if (RegExp(r'^\d+$').hasMatch(cleaned)) {
      return cleaned.padLeft(2, '0');
    }
    return cleaned;
  }

  /// Branch implied by QR prefix; null if unknown.
  static String? branchFromCode(String raw) {
    final cleaned = raw.trim().toUpperCase();
    if (cleaned.startsWith('B-')) return 'Bulihan';
    if (cleaned.startsWith('D-')) return 'Dasma';
    return null;
  }

  /// Candidate table_number values to query (handles B-08 vs 08 drift).
  static List<String> lookupCandidates(String raw) {
    final norm = normalize(raw);
    final dig = digits(raw);
    final set = <String>{norm, dig, 'B-$dig', 'D-$dig'};
    return set.toList();
  }
}
