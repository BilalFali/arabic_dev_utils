import 'package:arabic_dev_utils/src/rtl/arabic_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArabicDirection.isRtl', () {
    test('true when the first strong character is Arabic', () {
      expect(ArabicDirection.isRtl('مرحبا hello'), isTrue);
    });

    test('false when the first strong character is Latin', () {
      expect(ArabicDirection.isRtl('hello مرحبا'), isFalse);
    });

    test('false for empty string', () {
      expect(ArabicDirection.isRtl(''), isFalse);
    });
  });

  group('ArabicDirection.isLtr', () {
    test('true when the first strong character is Latin', () {
      expect(ArabicDirection.isLtr('hello مرحبا'), isTrue);
    });

    test('false when the first strong character is Arabic', () {
      expect(ArabicDirection.isLtr('مرحبا hello'), isFalse);
    });

    test('false for empty string', () {
      expect(ArabicDirection.isLtr(''), isFalse);
    });
  });

  group('ArabicDirection.isMixedDirection', () {
    test('true when both scripts are present', () {
      expect(ArabicDirection.isMixedDirection('hello مرحبا'), isTrue);
    });

    test('false when only Arabic is present', () {
      expect(ArabicDirection.isMixedDirection('مرحبا'), isFalse);
    });

    test('false when only Latin is present', () {
      expect(ArabicDirection.isMixedDirection('hello'), isFalse);
    });
  });

  group('ArabicDirection.dominantDirection', () {
    test('returns rtl for Arabic-only text', () {
      expect(ArabicDirection.dominantDirection('مرحبا'), TextDirection.rtl);
    });

    test('returns ltr for Latin-only text', () {
      expect(ArabicDirection.dominantDirection('hello'), TextDirection.ltr);
    });

    test('returns mixed when both scripts are present', () {
      expect(
        ArabicDirection.dominantDirection('hello مرحبا'),
        TextDirection.mixed,
      );
    });

    test('returns neutral for digits/punctuation only', () {
      expect(ArabicDirection.dominantDirection('123 !!!'), TextDirection.neutral);
    });

    test('returns neutral for empty string', () {
      expect(ArabicDirection.dominantDirection(''), TextDirection.neutral);
    });
  });
}
