import 'package:arabic_dev_utils/src/numbers/arabic_numbers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArabicNumbers.toArabicDigits', () {
    test('converts a pure numeric string', () {
      expect(ArabicNumbers.toArabicDigits('0123456789'), '٠١٢٣٤٥٦٧٨٩');
    });

    test('converts digits embedded in a sentence', () {
      expect(
        ArabicNumbers.toArabicDigits('السعر 100 ريال'),
        'السعر ١٠٠ ريال',
      );
    });

    test('leaves non-digit characters untouched', () {
      expect(ArabicNumbers.toArabicDigits('abc'), 'abc');
    });

    test('empty string stays empty', () {
      expect(ArabicNumbers.toArabicDigits(''), '');
    });
  });

  group('ArabicNumbers.toEnglishDigits', () {
    test('converts Arabic-Indic digits (٠-٩)', () {
      expect(ArabicNumbers.toEnglishDigits('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });

    test('converts Extended Arabic-Indic / Persian digits (۰-۹)', () {
      expect(ArabicNumbers.toEnglishDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
    });

    test('converts digits embedded in a sentence', () {
      expect(
        ArabicNumbers.toEnglishDigits('السعر ١٠٠ ريال'),
        'السعر 100 ريال',
      );
    });

    test('leaves ASCII digits untouched', () {
      expect(ArabicNumbers.toEnglishDigits('100'), '100');
    });
  });

  group('ArabicNumbers.containsArabicDigits', () {
    test('true for Arabic-Indic digits', () {
      expect(ArabicNumbers.containsArabicDigits('السعر ١٠٠'), isTrue);
    });

    test('true for Extended Arabic-Indic digits', () {
      expect(ArabicNumbers.containsArabicDigits('قیمت ۱۰۰'), isTrue);
    });

    test('false for ASCII-only digits', () {
      expect(ArabicNumbers.containsArabicDigits('price 100'), isFalse);
    });

    test('false for text with no digits', () {
      expect(ArabicNumbers.containsArabicDigits('مرحبا'), isFalse);
    });
  });

  group('ArabicNumbers.format', () {
    test('formats an integer using the default (ar) locale', () {
      // NOTE: `NumberFormat.decimalPattern('ar')` from the installed intl
      // (0.19.0) uses the CLDR `latn` numbering system for the 'ar' locale,
      // i.e. Western digits with a comma grouping separator — not Eastern
      // Arabic-Indic digits. Verified via
      // `NumberFormat.decimalPattern('ar').format(1234)` -> '1,234'.
      expect(ArabicNumbers.format(1234), '1,234');
    });

    test('formats using an explicit locale', () {
      expect(ArabicNumbers.format(1234, locale: 'en'), '1,234');
    });
  });
}
