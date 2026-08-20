import 'package:flutter/foundation.dart';

/// Helper utility for sanitizing, normalizing, and proxying image URLs across platforms.
///
/// On Flutter Web, cross-origin images (such as those hosted on Render without CORS headers)
/// trigger browser CORS blocks when fetched via CanvasKit / CachedNetworkImage.
/// This utility transparently routes non-CORS image URLs through wsrv.nl (a fast, open-source
/// image cache CDN powered by Cloudflare with full `Access-Control-Allow-Origin: *` headers).
class ImageUrlHelper {
  /// Default origin for relative asset paths
  static const String defaultOrigin = 'https://saddle-ranch-web.onrender.com';

  /// Normalizes and ensures the given image URL is accessible on all platforms.
  ///
  /// - Trims and checks for empty/null strings.
  /// - Resolves relative paths (e.g., `/images/...` or `images/...`).
  /// - On Web, wraps unproxied URLs with `https://wsrv.nl/?url=...` for zero CORS failures.
  static String? normalize(String? rawUrl) {
    if (rawUrl == null) return null;
    var url = rawUrl.trim();
    if (url.isEmpty) return null;

    // Resolve relative paths
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('/')) {
        url = '$defaultOrigin$url';
      } else {
        url = '$defaultOrigin/$url';
      }
    }

    // On Flutter Web, bypass CORS restrictions using wsrv.nl
    if (kIsWeb) {
      if (url.contains('wsrv.nl') || url.contains('images.weserv.nl')) {
        return url;
      }
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}';
    }

    return url;
  }
}
