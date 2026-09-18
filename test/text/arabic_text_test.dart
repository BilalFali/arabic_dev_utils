import 'package:arabic_dev_utils/src/text/arabic_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArabicText.isArabic', () {
    test('true for Arabic text', () {
      expect(ArabicText.isArabic('مرحبا'), isTrue);
    });

    test('false for Latin-only text', () {
      expect(ArabicText.isArabic('hello'), isFalse);
    });

    test('true for mixed text', () {
      expect(ArabicText.isArabic('hello مرحبا'), isTrue);
    });

    test('false for empty string', () {
      expect(ArabicText.isArabic(''), isFalse);
    });

    test('false for punctuation-only string', () {
      expect(ArabicText.isArabic('!!! ??? ,,,'), isFalse);
    });
  });

  group('ArabicText.isArabicOnly', () {
    test('true for pure Arabic text', () {
      expect(ArabicText.isArabicOnly('مرحبا بالعالم'), isTrue);
    });

    test('ignores surrounding whitespace and punctuation', () {
      expect(ArabicText.isArabicOnly('  مرحبا، بالعالم!  '), isTrue);
    });

    test('false when mixed with Latin text', () {
      expect(ArabicText.isArabicOnly('مرحبا hello'), isFalse);
    });

    test('false for empty string', () {
      expect(ArabicText.isArabicOnly(''), isFalse);
    });

    test('false for punctuation-only string', () {
      expect(ArabicText.isArabicOnly('!!! ???'), isFalse);
    });
  });

  group('ArabicText.isMixed', () {
    test('true for Arabic + Latin text', () {
      expect(ArabicText.isMixed('Hello مرحبا'), isTrue);
    });

    test('false for Arabic-only text', () {
      expect(ArabicText.isMixed('مرحبا'), isFalse);
    });

    test('false for Latin-only text', () {
      expect(ArabicText.isMixed('hello'), isFalse);
    });

    test('false for empty string', () {
      expect(ArabicText.isMixed(''), isFalse);
    });

    test('true for Arabic text with embedded English numbers/words', () {
      expect(ArabicText.isMixed('السعر 100 دولار USD'), isTrue);
    });
  });

  group('ArabicText.removeDiacritics', () {
    test('removes fatha (U+064B fathatan tested separately below)', () {
      expect(ArabicText.removeDiacritics('كَتَبَ'), 'كتب');
    });

    test('removes damma', () {
      expect(ArabicText.removeDiacritics('كُتُبٌ'), 'كتب');
    });

    test('removes kasra', () {
      expect(ArabicText.removeDiacritics('بِسْمِ'), 'بسم');
    });

    test('removes shadda', () {
      expect(ArabicText.removeDiacritics('مُحَمَّد'), 'محمد');
    });

    test('removes sukun', () {
      expect(ArabicText.removeDiacritics('مَنْ'), 'من');
    });

    test('removes fathatan (tanween)', () {
      expect(ArabicText.removeDiacritics('كِتَابًا'), 'كتابا');
    });

    test('removes dammatan (tanween)', () {
      expect(ArabicText.removeDiacritics('كِتَابٌ'), 'كتاب');
    });

    test('removes kasratan (tanween)', () {
      expect(ArabicText.removeDiacritics('كِتَابٍ'), 'كتاب');
    });

    test('removes dagger alef (U+0670)', () {
      expect(ArabicText.removeDiacritics('هَٰذَا'), 'هذا');
    });

    test('leaves plain text without diacritics untouched', () {
      expect(ArabicText.removeDiacritics('مرحبا'), 'مرحبا');
    });

    test('empty string stays empty', () {
      expect(ArabicText.removeDiacritics(''), '');
    });
  });

  group('ArabicText.removeTatweel', () {
    test('removes kashida between letters', () {
      expect(ArabicText.removeTatweel('مـــرحبا'), 'مرحبا');
    });

    test('leaves text without tatweel untouched', () {
      expect(ArabicText.removeTatweel('مرحبا'), 'مرحبا');
    });
  });

  group('ArabicText.normalizeAlef', () {
    test('normalizes alef with hamza above (أ)', () {
      expect(ArabicText.normalizeAlef('أحمد'), 'احمد');
    });

    test('normalizes alef with hamza below (إ)', () {
      expect(ArabicText.normalizeAlef('إحسان'), 'احسان');
    });

    test('normalizes alef with madda above (آ)', () {
      expect(ArabicText.normalizeAlef('آمين'), 'امين');
    });

    test('normalizes alef wasla (ٱ)', () {
      expect(ArabicText.normalizeAlef('ٱلرحمن'), 'الرحمن');
    });

    test('leaves plain alef untouched', () {
      expect(ArabicText.normalizeAlef('احمد'), 'احمد');
    });
  });

  group('ArabicText.normalizeYeh', () {
    test('normalizes alef maksura (ى) to yeh (ي)', () {
      expect(ArabicText.normalizeYeh('على'), 'علي');
    });

    test('leaves plain yeh untouched', () {
      expect(ArabicText.normalizeYeh('علي'), 'علي');
    });
  });

  group('ArabicText.normalizeTehMarbuta', () {
    test('normalizes teh marbuta (ة) to heh (ه)', () {
      expect(ArabicText.normalizeTehMarbuta('مدرسة'), 'مدرسه');
    });

    test('leaves plain heh untouched', () {
      expect(ArabicText.normalizeTehMarbuta('مدرسه'), 'مدرسه');
    });
  });

  group('ArabicText.normalize', () {
    test('applies diacritics, tatweel, alef, yeh in order (teh off by default)', () {
      expect(ArabicText.normalize('أَحْمَـدٌ عَلَى'), 'احمد علي');
    });

    test('normalizeTeh: false leaves teh marbuta untouched', () {
      expect(ArabicText.normalize('مدرسة'), 'مدرسة');
    });

    test('normalizeTeh: true also normalizes teh marbuta', () {
      expect(
        ArabicText.normalize('مدرسة', normalizeTeh: true),
        'مدرسه',
      );
    });

    test('empty string stays empty', () {
      expect(ArabicText.normalize(''), '');
    });
  });

  group('ArabicText.stripInvisibleChars', () {
    test('delegates to remove invisible characters', () {
      expect(ArabicText.stripInvisibleChars('مر‍حبا'), 'مرحبا');
    });

    test(
      'two strings identical except for a mid-word ZWJ are unequal before, '
      'equal after',
      () {
        const fromWhatsApp = 'محمد‍علي';
        const typedByHand = 'محمدعلي';
        expect(fromWhatsApp == typedByHand, isFalse);
        expect(
          ArabicText.stripInvisibleChars(fromWhatsApp) ==
              ArabicText.stripInvisibleChars(typedByHand),
          isTrue,
        );
      },
    );

    test(
      'two strings identical except for a mid-word ZWNJ are unequal before, '
      'equal after',
      () {
        const fromWord = 'سلام‌تی';
        const typedByHand = 'سلامتی';
        expect(fromWord == typedByHand, isFalse);
        expect(
          ArabicText.stripInvisibleChars(fromWord) ==
              ArabicText.stripInvisibleChars(typedByHand),
          isTrue,
        );
      },
    );
  });

  group('ArabicText.wordCount', () {
    test('counts words in a plain Arabic sentence', () {
      expect(ArabicText.wordCount('مرحبا بكم في العالم'), 4);
    });

    test('counts words in a mixed Arabic/English sentence', () {
      expect(ArabicText.wordCount('Hello مرحبا World'), 3);
    });

    test('collapses multiple spaces', () {
      expect(ArabicText.wordCount('مرحبا    بكم'), 2);
    });

    test('returns 0 for empty string', () {
      expect(ArabicText.wordCount(''), 0);
    });

    test('returns 0 for whitespace-only string', () {
      expect(ArabicText.wordCount('   '), 0);
    });
  });

  group('ArabicText.charCount', () {
    test('counts characters including diacritics by default', () {
      expect(ArabicText.charCount('كَتَبَ'), 6);
    });

    test('excludes diacritics when requested', () {
      expect(
        ArabicText.charCount('كَتَبَ', excludeDiacritics: true),
        3,
      );
    });

    test('returns 0 for empty string', () {
      expect(ArabicText.charCount(''), 0);
    });

    test('counts mixed Arabic/English/number strings', () {
      expect(ArabicText.charCount('abc مرحبا 123'), 13);
    });
  });
}
