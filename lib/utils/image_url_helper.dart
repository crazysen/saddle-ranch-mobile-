import 'package:flutter/foundation.dart';

import '../core/config/api_config.dart';

/// Helper utility for sanitizing, normalizing, and proxying image URLs across platforms.
///
/// On Flutter Web, cross-origin images (such as those hosted on Render without CORS headers)
/// trigger browser CORS blocks when fetched via CanvasKit / CachedNetworkImage.
/// This utility transparently routes non-CORS public image URLs through wsrv.nl (a fast, open-source
/// image cache CDN powered by Cloudflare with full `Access-Control-Allow-Origin: *` headers).
///
/// Local development URLs (localhost / 127.0.0.1) are NEVER proxied through public CDNs
/// to prevent HTTP 400 Bad Request errors.
class ImageUrlHelper {
  /// Default origin for relative asset paths
  static const String defaultOrigin = 'https://saddle-ranch-web.onrender.com';

  /// Resolves the current backend origin dynamically (local vs live Render)
  static String get currentOrigin {
    final base = ApiConfig.baseUrl;
    return base.replaceAll(RegExp(r'/api/v1/?$'), '');
  }

  /// Normalizes and ensures the given image URL is accessible on all platforms.
  static String? normalize(String? rawUrl) {
    if (rawUrl == null) return null;
    var url = rawUrl.trim();
    if (url.isEmpty) return null;

    // Resolve relative paths (/images/... or images/...)
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final origin = currentOrigin.isNotEmpty ? currentOrigin : defaultOrigin;
      if (url.startsWith('/')) {
        url = '$origin$url';
      } else {
        url = '$origin/$url';
      }
    }

    final uri = Uri.tryParse(url);
    final host = uri?.host.toLowerCase() ?? '';
    final isLocal = host == 'localhost' ||
        host == '127.0.0.1' ||
        host.startsWith('192.168.') ||
        host.startsWith('10.');

    // Localhost / internal network URLs cannot and must not be proxied via public CDNs (wsrv.nl will reject with 400)
    if (isLocal) {
      return url;
    }

    // On Flutter Web, bypass CORS restrictions for public remote images using wsrv.nl
    if (kIsWeb) {
      if (url.contains('wsrv.nl') || url.contains('images.weserv.nl')) {
        return url;
      }
      return 'https://wsrv.nl/?url=${Uri.encodeComponent(url)}';
    }

    return url;
  }
}
