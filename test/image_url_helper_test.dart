import 'package:flutter_test/flutter_test.dart';
import 'package:saddle_ranch_mobile/utils/image_url_helper.dart';

void main() {
  group('ImageUrlHelper Tests', () {
    test('returns null for null, empty or whitespace strings', () {
      expect(ImageUrlHelper.normalize(null), isNull);
      expect(ImageUrlHelper.normalize(''), isNull);
      expect(ImageUrlHelper.normalize('   '), isNull);
    });

    test('resolves relative paths with leading slash', () {
      final normalized = ImageUrlHelper.normalize('/images/Menu/bangus.webp');
      expect(normalized, isNotNull);
      expect(normalized!.contains('saddle-ranch-web.onrender.com/images/Menu/bangus.webp'), isTrue);
    });

    test('resolves relative paths without leading slash', () {
      final normalized = ImageUrlHelper.normalize('images/FilipinoCousines/kare-kare.webp');
      expect(normalized, isNotNull);
      expect(normalized!.contains('saddle-ranch-web.onrender.com/images/FilipinoCousines/kare-kare.webp'), isTrue);
    });

    test('preserves absolute URLs and formats properly', () {
      const url = 'https://saddle-ranch-web.onrender.com/images/Menu/sisig.webp';
      final normalized = ImageUrlHelper.normalize(url);
      expect(normalized, isNotNull);
      expect(normalized!.contains('sisig.webp'), isTrue);
    });
  });
}
