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
      expect(
        ArabicDirection.dominantDirection('مرحبا'),
        ArabicTextDirection.rtl,
      );
    });

    test('returns ltr for Latin-only text', () {
      expect(
        ArabicDirection.dominantDirection('hello'),
        ArabicTextDirection.ltr,
      );
    });

    test('returns mixed when both scripts are present', () {
      expect(
        ArabicDirection.dominantDirection('hello مرحبا'),
        ArabicTextDirection.mixed,
      );
    });

    test('returns neutral for digits/punctuation only', () {
      expect(
        ArabicDirection.dominantDirection('123 !!!'),
        ArabicTextDirection.neutral,
      );
    });

    test('returns neutral for empty string', () {
      expect(
        ArabicDirection.dominantDirection(''),
        ArabicTextDirection.neutral,
      );
    });

  });

  group('ArabicDirection.isRtl BOM regression', () {
    test('false for BOM-prefixed non-Arabic text', () {
      final bom = String.fromCharCode(0xFEFF);
      expect(ArabicDirection.isRtl('${bom}hello'), isFalse);
    });
  });

  group('ArabicDirection non-RTL script regression (guards against the '
      'FB1D range-corruption bug)', () {
    test('Chinese text is not detected as RTL', () {
      expect(ArabicDirection.isRtl('中文测试'), isFalse);
      expect(
        ArabicDirection.dominantDirection('中文测试'),
        ArabicTextDirection.neutral,
      );
    });

    test('Thai text is not detected as RTL', () {
      expect(ArabicDirection.isRtl('ไทยทดสอบ'), isFalse);
      expect(
        ArabicDirection.dominantDirection('ไทยทดสอบ'),
        ArabicTextDirection.neutral,
      );
    });

    test('Hangul text is not detected as RTL', () {
      expect(ArabicDirection.isRtl('한국어테스트'), isFalse);
      expect(
        ArabicDirection.dominantDirection('한국어테스트'),
        ArabicTextDirection.neutral,
      );
    });

    test('Hebrew text is still correctly detected as RTL', () {
      expect(ArabicDirection.isRtl('שלום עולם'), isTrue);
      expect(
        ArabicDirection.dominantDirection('שלום עולם'),
        ArabicTextDirection.rtl,
      );
    });
  });
}
