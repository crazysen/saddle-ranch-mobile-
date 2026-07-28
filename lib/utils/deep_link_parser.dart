String? extractTableFromUri(Uri uri) {
  final table = uri.queryParameters['table'];
  if (table != null && table.trim().isNotEmpty) {
    return table.trim();
  }

  // saddleranch://dine-in/05 or /dine-in/05
  final segments = uri.pathSegments;
  if (segments.isNotEmpty) {
    final dineInIndex = segments.indexWhere((s) => s.toLowerCase() == 'dine-in');
    if (dineInIndex >= 0 && dineInIndex + 1 < segments.length) {
      return segments[dineInIndex + 1].trim();
    }
  }

  return null;
}

bool isDineInLink(Uri uri) {
  final path = uri.path.toLowerCase();
  final host = uri.host.toLowerCase();
  return path.contains('dine-in') ||
      host == 'dine-in' ||
      uri.scheme.toLowerCase() == 'saddleranch';
}
