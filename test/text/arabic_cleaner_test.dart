import 'package:arabic_dev_utils/src/text/arabic_cleaner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArabicCleaner.strip', () {
    test('removes zero-width joiner (U+200D)', () {
      expect(ArabicCleaner.strip('مر‍حبا'), 'مرحبا');
    });

    test('removes zero-width non-joiner (U+200C)', () {
      expect(ArabicCleaner.strip('مر‌حبا'), 'مرحبا');
    });

    test('removes zero-width space (U+200B)', () {
      expect(ArabicCleaner.strip('مرحبا​'), 'مرحبا');
    });

    test('removes left-to-right and right-to-left marks (U+200E, U+200F)', () {
      expect(ArabicCleaner.strip('‎مرحبا‏'), 'مرحبا');
    });

    test('removes bidi embedding/override controls (U+202A-U+202E)', () {
      const controls = '\u202a\u202b\u202c\u202d\u202e';
      expect(ArabicCleaner.strip('مرحبا$controls'), 'مرحبا');
    });

    test('removes bidi isolate controls (U+2066-U+2069)', () {
      const isolates = '\u2066\u2067\u2068\u2069';
      expect(ArabicCleaner.strip('مرحبا$isolates'), 'مرحبا');
    });

    test('leaves visible text untouched', () {
      expect(ArabicCleaner.strip('Hello مرحبا 123'), 'Hello مرحبا 123');
    });

    test('returns empty string unchanged', () {
      expect(ArabicCleaner.strip(''), '');
    });

    test(
      'two strings that look identical but differ by a mid-word ZWJ '
      'become equal after stripping',
      () {
        const fromWhatsApp = 'محمد‍علي';
        const typedByHand = 'محمدعلي';
        expect(fromWhatsApp == typedByHand, isFalse);
        expect(
          ArabicCleaner.strip(fromWhatsApp) == ArabicCleaner.strip(typedByHand),
          isTrue,
        );
      },
    );

    test(
      'two strings that look identical but differ by a mid-word ZWNJ '
      'become equal after stripping',
      () {
        const fromWord = 'سلام‌تی';
        const typedByHand = 'سلامتی';
        expect(fromWord == typedByHand, isFalse);
        expect(
          ArabicCleaner.strip(fromWord) == ArabicCleaner.strip(typedByHand),
          isTrue,
        );
      },
    );
  });
}
