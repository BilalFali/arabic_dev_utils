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

  group('ArabicDirection non-RTL script regression (guards against the '
      'FB1D range-corruption bug)', () {
    test('Chinese text is not detected as RTL', () {
      expect(ArabicDirection.isRtl('中文测试'), isFalse);
      expect(
        ArabicDirection.dominantDirection('中文测试'),
        TextDirection.neutral,
      );
    });

    test('Thai text is not detected as RTL', () {
      expect(ArabicDirection.isRtl('ไทยทดสอบ'), isFalse);
      expect(
        ArabicDirection.dominantDirection('ไทยทดสอบ'),
        TextDirection.neutral,
      );
    });

    test('Hangul text is not detected as RTL', () {
      expect(ArabicDirection.isRtl('한국어테스트'), isFalse);
      expect(
        ArabicDirection.dominantDirection('한국어테스트'),
        TextDirection.neutral,
      );
    });

    test('Hebrew text is still correctly detected as RTL', () {
      expect(ArabicDirection.isRtl('שלום עולם'), isTrue);
      expect(
        ArabicDirection.dominantDirection('שלום עולם'),
        TextDirection.rtl,
      );
    });
  });
}
