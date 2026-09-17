# arabic_dev_utils v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build v1 of `arabic_dev_utils`, a Flutter package providing Arabic text normalization, invisible-character cleanup, Arabic-aware search, digit conversion, and RTL direction utilities.

**Architecture:** Single Flutter package. Pure-Dart logic files under `lib/src/` (text, search, numbers, and the direction enum/logic) import only `dart:core`, `package:meta`, and (for numbers only) `package:intl`. Exactly one file, `lib/src/rtl/arabic_directionality.dart`, imports `package:flutter`. A barrel file re-exports the public API.

**Tech Stack:** Dart 3 / Flutter, `package:meta`, `package:intl`, `flutter_test`, `flutter_lints`.

**Spec:** `docs/superpowers/specs/2026-09-17-arabic-dev-utils-v1-design.md`

## Global Constraints

- Dart SDK `^3.12.0`, Flutter `>=1.17.0` (already set in `pubspec.yaml`).
- Zero runtime dependencies beyond `meta` and `intl` (plus the `flutter` SDK itself).
- 100% of public API members must have dartdoc (`///`) comments.
- No `package:flutter` or `dart:ui` import in any file under `lib/src/` except `lib/src/rtl/arabic_directionality.dart`.
- `stripInvisibleChars` dartdoc must include a before/after "silent bug" example (WhatsApp/Word invisible-char corruption).
- README's first line must be exactly: `Useful utilities for developers building Arabic and RTL Flutter/Dart applications.`
- Out of scope, do not implement: Hijri dates, currency conversion, phone number parsing, number-to-words.
- Every task ends with `flutter test` passing and a commit.

---

## File Structure

```
lib/
  arabic_dev_utils.dart
  src/
    text/
      arabic_cleaner.dart
      arabic_text.dart
    search/
      arabic_search.dart
    numbers/
      arabic_numbers.dart
    rtl/
      arabic_direction.dart
      arabic_directionality.dart
test/
  text/arabic_cleaner_test.dart
  text/arabic_text_test.dart
  search/arabic_search_test.dart
  numbers/arabic_numbers_test.dart
  rtl/arabic_direction_test.dart
example/
  lib/main.dart
pubspec.yaml
LICENSE
README.md
CHANGELOG.md
```

---

### Task 1: Project setup — pubspec, license

**Files:**
- Modify: `pubspec.yaml`
- Modify: `LICENSE`

**Interfaces:**
- Consumes: nothing.
- Produces: `meta` and `intl` available as dependencies for all later tasks.

- [ ] **Step 1: Update `pubspec.yaml`**

Replace the full contents of `pubspec.yaml` with:

```yaml
name: arabic_dev_utils
description: "Utilities for developers building Arabic and RTL Flutter/Dart applications: text normalization, invisible-character cleanup, Arabic-aware search, digit conversion, and RTL direction helpers."
version: 0.1.0
homepage:

environment:
  sdk: ^3.12.0
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  meta: ^1.15.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

- [ ] **Step 2: Fetch dependencies**

Run: `flutter pub get`
Expected: resolves successfully, no version conflicts. If `intl: ^0.19.0` conflicts with the installed Flutter SDK's constraints, lower the constraint to whatever `flutter pub get` resolves to and note the exact version used.

- [ ] **Step 3: Fill in `LICENSE`**

Replace the full contents of `LICENSE` with:

```
MIT License

Copyright (c) 2026 bilalfali60@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 4: Commit**

Note: `pubspec.lock` is gitignored for this package (per `.gitignore`'s
"Libraries should not include pubspec.lock" rule) — do not add it.

```bash
git add pubspec.yaml LICENSE
git commit -m "chore: configure dependencies and MIT license"
```

---

### Task 2: `ArabicCleaner` — invisible character stripping

**Files:**
- Create: `lib/src/text/arabic_cleaner.dart`
- Test: `test/text/arabic_cleaner_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `ArabicCleaner.strip(String text) → String`, used by `ArabicText.stripInvisibleChars` in Task 3.

- [ ] **Step 1: Write the failing test**

Create `test/text/arabic_cleaner_test.dart`:

```dart
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
      const controls = '‪‫‬‭‮';
      expect(ArabicCleaner.strip('مرحبا$controls'), 'مرحبا');
    });

    test('removes bidi isolate controls (U+2066-U+2069)', () {
      const isolates = '⁦⁧⁨⁩';
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/text/arabic_cleaner_test.dart`
Expected: FAIL — `package:arabic_dev_utils/src/text/arabic_cleaner.dart` does not exist / `ArabicCleaner` undefined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/text/arabic_cleaner.dart`:

```dart
import 'package:meta/meta.dart';

/// Internal helper backing [ArabicText.stripInvisibleChars]. Not part of
/// the public API — use `ArabicText.stripInvisibleChars` instead.
@internal
class ArabicCleaner {
  ArabicCleaner._();

  /// Matches zero-width joiner/non-joiner, zero-width space, and
  /// bidirectional control characters that are invisible when rendered
  /// but affect string equality, search, and diffing.
  static final RegExp invisibleChars = RegExp(
    '[​-‏‪-‮⁦-⁩]',
  );

  /// Removes all characters matched by [invisibleChars] from [text].
  static String strip(String text) => text.replaceAll(invisibleChars, '');
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/text/arabic_cleaner_test.dart`
Expected: PASS (all 10 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/text/arabic_cleaner.dart test/text/arabic_cleaner_test.dart
git commit -m "feat: add ArabicCleaner invisible-character stripping"
```

---

### Task 3: `ArabicText` — normalization, classification, counting

**Files:**
- Create: `lib/src/text/arabic_text.dart`
- Test: `test/text/arabic_text_test.dart`

**Interfaces:**
- Consumes: `ArabicCleaner.strip(String) → String` (Task 2).
- Produces: `ArabicText` static methods — `isArabic`, `isArabicOnly`, `isMixed`, `removeDiacritics`, `removeTatweel`, `normalizeAlef`, `normalizeYeh`, `normalizeTehMarbuta`, `normalize({bool normalizeTeh})`, `stripInvisibleChars`, `wordCount`, `charCount({bool excludeDiacritics})` — all `(String) → String` or `(String) → bool`/`int` as named above. Used by `ArabicSearch` in Task 4.

- [ ] **Step 1: Write the failing test**

Create `test/text/arabic_text_test.dart`:

```dart
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
      expect(ArabicText.removeDiacritics('كِتَابًا'), 'كِتَابا');
    });

    test('removes dammatan (tanween)', () {
      expect(ArabicText.removeDiacritics('كِتَابٌ'), 'كِتَاب');
    });

    test('removes kasratan (tanween)', () {
      expect(ArabicText.removeDiacritics('كِتَابٍ'), 'كِتَاب');
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
      expect(ArabicText.normalize('أَحْمَـدٌ عَلَى'), 'احمد على');
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/text/arabic_text_test.dart`
Expected: FAIL — `arabic_text.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/text/arabic_text.dart`:

```dart
import 'arabic_cleaner.dart';

/// Arabic text normalization, classification, and counting utilities.
///
/// All methods are static and operate on plain [String] values — there is
/// no state to construct.
class ArabicText {
  ArabicText._();

  static final RegExp _arabicChar = RegExp(
    '[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]',
  );
  static final RegExp _latinChar = RegExp('[A-Za-z]');
  static final RegExp _arabicOnlyFullMatch = RegExp(
    r'^[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-﻿]+$',
  );
  static final RegExp _whitespaceOrPunctuation = RegExp(
    r'[\s\p{P}]',
    unicode: true,
  );
  static final RegExp _diacritics = RegExp('[ً-ْٰ]');
  static final RegExp _tatweel = RegExp('ـ');
  static final RegExp _alefVariants = RegExp('[أإآٱ]');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Returns true if [text] contains at least one Arabic-script character.
  static bool isArabic(String text) => _arabicChar.hasMatch(text);

  /// Returns true if [text], after removing whitespace and punctuation, is
  /// 100% Arabic-script characters. Returns false for an empty string or a
  /// string that is only whitespace/punctuation, since neither contains any
  /// Arabic text.
  static bool isArabicOnly(String text) {
    final stripped = text.replaceAll(_whitespaceOrPunctuation, '');
    if (stripped.isEmpty) return false;
    return _arabicOnlyFullMatch.hasMatch(stripped);
  }

  /// Returns true if [text] contains both Arabic-script and Latin-script
  /// characters.
  static bool isMixed(String text) =>
      _arabicChar.hasMatch(text) && _latinChar.hasMatch(text);

  /// Removes Arabic diacritics (tashkeel): fatha, damma, kasra, shadda,
  /// sukun, tanween, and the dagger alef (U+064B–U+0652, U+0670).
  static String removeDiacritics(String text) =>
      text.replaceAll(_diacritics, '');

  /// Removes the tatweel/kashida elongation character (ـ, U+0640).
  static String removeTatweel(String text) => text.replaceAll(_tatweel, '');

  /// Normalizes all alef variants (أ, إ, آ, ٱ) to the plain alef (ا).
  static String normalizeAlef(String text) =>
      text.replaceAll(_alefVariants, 'ا');

  /// Normalizes alef maksura (ى) to yeh (ي).
  static String normalizeYeh(String text) =>
      text.replaceAll('ى', 'ي');

  /// Normalizes teh marbuta (ة) to heh (ه).
  ///
  /// This is a search-only, linguistically lossy normalization (it discards
  /// the grammatical feminine marker), so it is never applied by
  /// [normalize] unless `normalizeTeh: true` is passed explicitly.
  static String normalizeTehMarbuta(String text) =>
      text.replaceAll('ة', 'ه');

  /// Applies [removeDiacritics], [removeTatweel], [normalizeAlef], and
  /// [normalizeYeh] in that order, then [normalizeTehMarbuta] if
  /// [normalizeTeh] is true.
  static String normalize(String text, {bool normalizeTeh = false}) {
    var result = removeDiacritics(text);
    result = removeTatweel(result);
    result = normalizeAlef(result);
    result = normalizeYeh(result);
    if (normalizeTeh) result = normalizeTehMarbuta(result);
    return result;
  }

  /// Removes invisible characters that can corrupt equality checks, search,
  /// and diffs without being visible on screen: zero-width joiner/non-joiner
  /// (U+200C, U+200D), zero-width space (U+200B), and bidirectional control
  /// characters (U+200E, U+200F, U+202A–U+202E, U+2066–U+2069).
  ///
  /// This matters because text copied from apps like WhatsApp or Word often
  /// carries these characters silently. Two strings can look and print
  /// identically while being unequal in code:
  ///
  /// ```dart
  /// const fromWhatsApp = 'محمد‍علي'; // contains a hidden ZWJ
  /// const typedByHand = 'محمدعلي';
  ///
  /// fromWhatsApp == typedByHand; // false — a silent bug in search/diffing
  ///
  /// ArabicText.stripInvisibleChars(fromWhatsApp) ==
  ///     ArabicText.stripInvisibleChars(typedByHand); // true
  /// ```
  static String stripInvisibleChars(String text) => ArabicCleaner.strip(text);

  /// Counts words in [text] by splitting on whitespace, since Arabic (like
  /// English) does not use word-internal spaces.
  static int wordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(_whitespace).where((w) => w.isNotEmpty).length;
  }

  /// Counts Unicode scalar values (not UTF-16 code units) in [text], so
  /// characters outside the basic multilingual plane are counted once. If
  /// [excludeDiacritics] is true, diacritics are removed before counting.
  static int charCount(String text, {bool excludeDiacritics = false}) {
    final target = excludeDiacritics ? removeDiacritics(text) : text;
    return target.runes.length;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/text/arabic_text_test.dart`
Expected: PASS (all tests). If `charCount('abc مرحبا 123')` count mismatches, recount manually (`a,b,c,' ',م,ر,ح,ب,ا,' ',1,2,3` = 13) rather than changing the implementation.

- [ ] **Step 5: Commit**

```bash
git add lib/src/text/arabic_text.dart test/text/arabic_text_test.dart
git commit -m "feat: add ArabicText normalization and classification"
```

---

### Task 4: `ArabicSearch`

**Files:**
- Create: `lib/src/search/arabic_search.dart`
- Test: `test/search/arabic_search_test.dart`

**Interfaces:**
- Consumes: `ArabicText.normalize(String, {bool normalizeTeh}) → String`, `ArabicText.stripInvisibleChars(String) → String` (Task 3).
- Produces: `ArabicSearch.matches({required String query, required String text}) → bool`, `ArabicSearch.normalizeForSearch(String) → String`, `ArabicSearch.tokenize(String) → List<String>`, `ArabicSearch.rank(String query, List<String> candidates) → List<String>`. Used by the example app in Task 9.

- [ ] **Step 1: Write the failing test**

Create `test/search/arabic_search_test.dart`:

```dart
import 'package:arabic_dev_utils/src/search/arabic_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArabicSearch.normalizeForSearch', () {
    test('normalizes teh marbuta unlike ArabicText.normalize default', () {
      expect(ArabicSearch.normalizeForSearch('مدرسة'), 'مدرسه');
    });

    test('strips invisible characters', () {
      expect(ArabicSearch.normalizeForSearch('محمد‍علي'), 'محمدعلي');
    });

    test('applies diacritic/alef/yeh normalization', () {
      expect(ArabicSearch.normalizeForSearch('أَحْمَد'), 'احمد');
    });
  });

  group('ArabicSearch.matches', () {
    test('matches despite diacritics', () {
      expect(
        ArabicSearch.matches(query: 'احمد', text: 'أَحْمَد بن علي'),
        isTrue,
      );
    });

    test('matches despite alef variant differences', () {
      expect(
        ArabicSearch.matches(query: 'احمد', text: 'أحمد'),
        isTrue,
      );
    });

    test('matches despite teh marbuta vs heh differences', () {
      expect(
        ArabicSearch.matches(query: 'مدرسه', text: 'مدرسة'),
        isTrue,
      );
    });

    test('does not match unrelated text', () {
      expect(
        ArabicSearch.matches(query: 'محمد', text: 'أحمد بن علي'),
        isFalse,
      );
    });

    test('empty query does not match', () {
      expect(ArabicSearch.matches(query: '', text: 'أحمد'), isFalse);
    });
  });

  group('ArabicSearch.tokenize', () {
    test('splits normalized text into tokens', () {
      expect(
        ArabicSearch.tokenize('أَحْمَد   بن علي'),
        ['احمد', 'بن', 'علي'],
      );
    });

    test('returns empty list for empty string', () {
      expect(ArabicSearch.tokenize(''), <String>[]);
    });
  });

  group('ArabicSearch.rank', () {
    test('exact match ranks before prefix, prefix before contains', () {
      final result = ArabicSearch.rank('احمد', [
        'محمد احمد', // contains
        'احمدي', // prefix
        'احمد', // exact
      ]);
      expect(result, ['احمد', 'احمدي', 'محمد احمد']);
    });

    test('excludes non-matching candidates', () {
      final result = ArabicSearch.rank('احمد', ['علي', 'محمد']);
      expect(result, <String>[]);
    });

    test('ties keep original input order', () {
      final result = ArabicSearch.rank('علي', ['علي أحمد', 'علي محمد']);
      expect(result, ['علي أحمد', 'علي محمد']);
    });

    test('matches are diacritic-insensitive', () {
      final result = ArabicSearch.rank('احمد', ['أَحْمَد']);
      expect(result, ['أَحْمَد']);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/search/arabic_search_test.dart`
Expected: FAIL — `arabic_search.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/search/arabic_search.dart`:

```dart
import '../text/arabic_text.dart';

/// Arabic-aware search utilities built on [ArabicText] normalization.
class ArabicSearch {
  ArabicSearch._();

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Returns true if [query] matches somewhere inside [text], ignoring
  /// diacritics, tatweel, alef variants, yeh variants, teh marbuta, and
  /// invisible characters. An empty [query] never matches.
  static bool matches({required String query, required String text}) {
    final normalizedQuery = normalizeForSearch(query);
    if (normalizedQuery.isEmpty) return false;
    return normalizeForSearch(text).contains(normalizedQuery);
  }

  /// Normalizes [text] for search: applies [ArabicText.normalize] with
  /// `normalizeTeh: true`, then strips invisible characters via
  /// [ArabicText.stripInvisibleChars]. This is more aggressive than
  /// [ArabicText.normalize]'s default because search needs to treat teh
  /// marbuta and heh as equivalent, unlike display or linguistic use.
  static String normalizeForSearch(String text) {
    final normalized = ArabicText.normalize(text, normalizeTeh: true);
    return ArabicText.stripInvisibleChars(normalized);
  }

  /// Splits [text] into normalized, non-empty, whitespace-separated tokens.
  static List<String> tokenize(String text) {
    final normalized = normalizeForSearch(text);
    if (normalized.trim().isEmpty) return const [];
    return normalized
        .split(_whitespace)
        .where((token) => token.isNotEmpty)
        .toList();
  }

  /// Sorts [candidates] by match quality against [query]: an exact
  /// normalized match first, then a normalized-prefix match, then a
  /// normalized-contains match. Non-matching candidates are excluded. Ties
  /// preserve the original order of [candidates].
  static List<String> rank(String query, List<String> candidates) {
    final normalizedQuery = normalizeForSearch(query);
    final scored = <(int score, int index, String candidate)>[];

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final score = _matchScore(normalizedQuery, normalizeForSearch(candidate));
      if (score != null) {
        scored.add((score, i, candidate));
      }
    }

    scored.sort((a, b) {
      final byScore = a.$1.compareTo(b.$1);
      return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
    });

    return scored.map((entry) => entry.$3).toList();
  }

  static int? _matchScore(String normalizedQuery, String normalizedCandidate) {
    if (normalizedQuery.isEmpty) return null;
    if (normalizedCandidate == normalizedQuery) return 0;
    if (normalizedCandidate.startsWith(normalizedQuery)) return 1;
    if (normalizedCandidate.contains(normalizedQuery)) return 2;
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/search/arabic_search_test.dart`
Expected: PASS (all tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/search/arabic_search.dart test/search/arabic_search_test.dart
git commit -m "feat: add ArabicSearch normalization, matching, and ranking"
```

---

### Task 5: `ArabicNumbers`

**Files:**
- Create: `lib/src/numbers/arabic_numbers.dart`
- Test: `test/numbers/arabic_numbers_test.dart`

**Interfaces:**
- Consumes: `NumberFormat.decimalPattern(String locale)` from `package:intl`.
- Produces: `ArabicNumbers.toArabicDigits(String) → String`, `ArabicNumbers.toEnglishDigits(String) → String`, `ArabicNumbers.containsArabicDigits(String) → bool`, `ArabicNumbers.format(num, {String locale}) → String`. Used by the example app in Task 9.

- [ ] **Step 1: Write the failing test**

Create `test/numbers/arabic_numbers_test.dart`:

```dart
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
    test('formats an integer using Arabic digits by default locale', () {
      expect(ArabicNumbers.format(1234), '١٬٢٣٤');
    });

    test('formats using an explicit locale', () {
      expect(ArabicNumbers.format(1234, locale: 'en'), '1,234');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/numbers/arabic_numbers_test.dart`
Expected: FAIL — `arabic_numbers.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/numbers/arabic_numbers.dart`:

```dart
import 'package:intl/intl.dart';

/// Arabic digit conversion and formatting utilities.
class ArabicNumbers {
  ArabicNumbers._();

  static const List<String> _easternArabicDigits = [
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩',
  ];

  static final RegExp _arabicIndicDigit = RegExp('[٠-٩]');
  static final RegExp _extendedArabicIndicDigit = RegExp('[۰-۹]');

  /// Replaces every ASCII digit (0-9) in [text] with its Arabic-Indic
  /// (٠-٩) equivalent, wherever it occurs in the string.
  static String toArabicDigits(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.write(_easternArabicDigits[rune - 0x30]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Replaces every Arabic-Indic (٠-٩) or Extended Arabic-Indic / Persian
  /// (۰-۹) digit in [text] with its ASCII (0-9) equivalent.
  static String toEnglishDigits(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.write(rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.write(rune - 0x06F0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Returns true if [text] contains any Arabic-Indic (٠-٩) or Extended
  /// Arabic-Indic / Persian (۰-۹) digit.
  static bool containsArabicDigits(String text) =>
      _arabicIndicDigit.hasMatch(text) ||
      _extendedArabicIndicDigit.hasMatch(text);

  /// Formats [value] using `package:intl`'s locale-aware
  /// [NumberFormat.decimalPattern], defaulting to the `'ar'` locale (Arabic
  /// digit output with Arabic grouping/decimal separators).
  ///
  /// This is a thin, discoverability wrapper — `package:intl` already does
  /// correct locale-aware number formatting, and this method exists so
  /// consumers of this package don't have to know to reach for `intl`
  /// separately, not because `intl` is inadequate.
  static String format(num value, {String locale = 'ar'}) =>
      NumberFormat.decimalPattern(locale).format(value);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/numbers/arabic_numbers_test.dart`
Expected: PASS. If the `format` tests fail on exact separator characters (e.g. Arabic thousands separator rendering), inspect the actual `NumberFormat.decimalPattern('ar').format(1234)` output in a `print` and update the expected string in the test to match `intl`'s real output — do not change `ArabicNumbers.format`'s implementation.

- [ ] **Step 5: Commit**

```bash
git add lib/src/numbers/arabic_numbers.dart test/numbers/arabic_numbers_test.dart
git commit -m "feat: add ArabicNumbers digit conversion and intl formatting wrapper"
```

---

### Task 6: `ArabicDirection` and `TextDirection`

**Files:**
- Create: `lib/src/rtl/arabic_direction.dart`
- Test: `test/rtl/arabic_direction_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `enum TextDirection { rtl, ltr, mixed, neutral }`; `ArabicDirection.isRtl(String) → bool`, `ArabicDirection.isLtr(String) → bool`, `ArabicDirection.isMixedDirection(String) → bool`, `ArabicDirection.dominantDirection(String) → TextDirection`. Used by `ArabicDirectionality` in Task 7.

- [ ] **Step 1: Write the failing test**

Create `test/rtl/arabic_direction_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/rtl/arabic_direction_test.dart`
Expected: FAIL — `arabic_direction.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/rtl/arabic_direction.dart`:

```dart
/// The dominant reading direction of a piece of text.
enum TextDirection {
  /// The text is dominated by right-to-left script.
  rtl,

  /// The text is dominated by left-to-right script.
  ltr,

  /// The text contains a meaningful mix of right-to-left and left-to-right
  /// script.
  mixed,

  /// The text contains no strong-directional characters (e.g. only digits
  /// or punctuation), or is empty.
  neutral,
}

/// Direction-detection utilities for Arabic and Latin script text.
class ArabicDirection {
  ArabicDirection._();

  static final RegExp _rtlChar = RegExp(
    '[֐-׿؀-ۿ܀-ݏݐ-ݿࢠ-ࣿ'
    'יִ-﷿ﹰ-﻿]',
  );
  static final RegExp _ltrChar = RegExp('[A-Za-z]');

  /// Returns true if the first strong-directional character in [text] is
  /// right-to-left script.
  static bool isRtl(String text) => _firstStrongIsRtl(text) == true;

  /// Returns true if the first strong-directional character in [text] is
  /// left-to-right script.
  static bool isLtr(String text) => _firstStrongIsRtl(text) == false;

  /// Returns true if [text] contains both right-to-left and left-to-right
  /// strong-directional characters.
  static bool isMixedDirection(String text) =>
      _rtlChar.hasMatch(text) && _ltrChar.hasMatch(text);

  /// Returns the dominant [TextDirection] of [text] based on the presence
  /// of right-to-left and left-to-right strong-directional characters.
  static TextDirection dominantDirection(String text) {
    final hasRtl = _rtlChar.hasMatch(text);
    final hasLtr = _ltrChar.hasMatch(text);
    if (hasRtl && hasLtr) return TextDirection.mixed;
    if (hasRtl) return TextDirection.rtl;
    if (hasLtr) return TextDirection.ltr;
    return TextDirection.neutral;
  }

  static bool? _firstStrongIsRtl(String text) {
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (_rtlChar.hasMatch(char)) return true;
      if (_ltrChar.hasMatch(char)) return false;
    }
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/rtl/arabic_direction_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/rtl/arabic_direction.dart test/rtl/arabic_direction_test.dart
git commit -m "feat: add ArabicDirection detection and TextDirection enum"
```

---

### Task 7: `ArabicDirectionality` widget

**Files:**
- Create: `lib/src/rtl/arabic_directionality.dart`
- Test: `test/rtl/arabic_directionality_test.dart`

**Interfaces:**
- Consumes: `ArabicDirection.dominantDirection(String) → TextDirection` (Task 6).
- Produces: `ArabicDirectionality({Key? key, required Widget child, required String basedOn})` widget. Used by the example app in Task 9. This is the only file in `lib/src/` allowed to import `package:flutter`.

- [ ] **Step 1: Write the failing test**

Create `test/rtl/arabic_directionality_test.dart`:

```dart
import 'package:arabic_dev_utils/src/rtl/arabic_directionality.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('resolves RTL directionality from Arabic basedOn text',
      (tester) async {
    await tester.pumpWidget(
      const ArabicDirectionality(
        basedOn: 'مرحبا',
        child: Text('مرحبا', textDirection: TextDirection.rtl),
      ),
    );

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality),
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('resolves LTR directionality from Latin basedOn text',
      (tester) async {
    await tester.pumpWidget(
      const ArabicDirectionality(
        basedOn: 'hello',
        child: Text('hello', textDirection: TextDirection.ltr),
      ),
    );

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality),
    );
    expect(directionality.textDirection, TextDirection.ltr);
  });

  testWidgets('falls back to LTR for neutral basedOn text', (tester) async {
    await tester.pumpWidget(
      const ArabicDirectionality(
        basedOn: '123',
        child: Text('123', textDirection: TextDirection.ltr),
      ),
    );

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality),
    );
    expect(directionality.textDirection, TextDirection.ltr);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/rtl/arabic_directionality_test.dart`
Expected: FAIL — `arabic_directionality.dart` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/rtl/arabic_directionality.dart`:

```dart
import 'package:flutter/widgets.dart';

import 'arabic_direction.dart' as detect;

/// Wraps [child] in a [Directionality] whose text direction is inferred
/// from [basedOn] using [detect.ArabicDirection.dominantDirection].
///
/// This exists as a convenience layer: `package:intl` already exposes a
/// `Bidi` class for direction detection, but `ArabicDirectionality` is
/// easier to discover and use for the common case of "set this widget's
/// direction from a string" without looking up `Bidi`'s API.
///
/// [detect.TextDirection.mixed] and [detect.TextDirection.neutral] both
/// resolve to [TextDirection.ltr], since there is no single correct choice
/// for genuinely mixed or non-directional text.
class ArabicDirectionality extends StatelessWidget {
  /// Creates an [ArabicDirectionality] that infers direction from
  /// [basedOn].
  const ArabicDirectionality({
    super.key,
    required this.child,
    required this.basedOn,
  });

  /// The widget to render inside the inferred [Directionality].
  final Widget child;

  /// The text used to infer the reading direction.
  final String basedOn;

  @override
  Widget build(BuildContext context) {
    final direction = detect.ArabicDirection.dominantDirection(basedOn);
    final resolved = direction == detect.TextDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    return Directionality(textDirection: resolved, child: child);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/rtl/arabic_directionality_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/rtl/arabic_directionality.dart test/rtl/arabic_directionality_test.dart
git commit -m "feat: add ArabicDirectionality widget"
```

---

### Task 8: Barrel export and old scaffold cleanup

**Files:**
- Modify: `lib/arabic_dev_utils.dart`
- Delete: `test/arabic_dev_utils_test.dart` (tests the default `Calculator` scaffold class, which this package does not have)

**Interfaces:**
- Consumes: all public classes/enums from Tasks 2–7 (only the non-internal ones).
- Produces: the package's full public API import surface — `import 'package:arabic_dev_utils/arabic_dev_utils.dart';` exposes `ArabicText`, `ArabicSearch`, `ArabicNumbers`, `ArabicDirection`, `TextDirection`, `ArabicDirectionality`.

- [ ] **Step 1: Replace the barrel file**

Replace the full contents of `lib/arabic_dev_utils.dart` with:

```dart
/// Utilities for developers building Arabic and RTL Flutter/Dart
/// applications: text normalization, invisible-character cleanup,
/// Arabic-aware search, digit conversion, and RTL direction helpers.
library;

export 'src/text/arabic_text.dart';
export 'src/search/arabic_search.dart';
export 'src/numbers/arabic_numbers.dart';
export 'src/rtl/arabic_direction.dart';
export 'src/rtl/arabic_directionality.dart';
```

Note: `arabic_cleaner.dart` is intentionally not exported — `ArabicCleaner` is `@internal` and reached only through `ArabicText.stripInvisibleChars`.

- [ ] **Step 2: Delete the stale scaffold test**

Delete `test/arabic_dev_utils_test.dart` (it imports a `Calculator` class this package never had; keeping it will break `flutter test`).

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: PASS — all tests from Tasks 2–7 pass, no reference to the deleted file remains.

- [ ] **Step 4: Run static analysis**

Run: `flutter analyze`
Expected: `No issues found!`. If `flutter_lints` flags anything (e.g. missing trailing commas, prefer_const), fix it in the flagged file before proceeding.

- [ ] **Step 5: Commit**

```bash
git add lib/arabic_dev_utils.dart
git rm test/arabic_dev_utils_test.dart
git commit -m "feat: export public API via barrel file, remove scaffold test"
```

---

### Task 9: Example app

**Files:**
- Create: `example/pubspec.yaml`
- Create: `example/lib/main.dart`

**Interfaces:**
- Consumes: `ArabicText`, `ArabicSearch`, `ArabicNumbers`, `ArabicDirection`, `TextDirection`, `ArabicDirectionality` (all public API from Task 8).
- Produces: a runnable Flutter demo app; no other task depends on this one.

- [ ] **Step 1: Create `example/pubspec.yaml`**

```yaml
name: arabic_dev_utils_example
description: "Demo app for the arabic_dev_utils package."
publish_to: "none"
version: 0.1.0

environment:
  sdk: ^3.12.0
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  arabic_dev_utils:
    path: ../

dev_dependencies:
  flutter_lints: ^6.0.0
```

- [ ] **Step 2: Create `example/lib/main.dart`**

```dart
import 'package:arabic_dev_utils/arabic_dev_utils.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// Demo app showing all four arabic_dev_utils modules: text normalization,
/// search, number conversion, and RTL direction.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'arabic_dev_utils example',
      home: const HomePage(),
    );
  }
}

/// Home page hosting the four module demos.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _names = [
    'أحمد محمد',
    'إسراء علي',
    'محمد أحمد',
    'فاطمة الزهراء',
    'يوسف إبراهيم',
    'مريم حسن',
  ];

  final _searchController = TextEditingController();
  List<String> _results = _names;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchController.text;
    setState(() {
      _results = query.isEmpty ? _names : ArabicSearch.rank(query, _names);
    });
  }

  @override
  Widget build(BuildContext context) {
    const sampleText = 'أَحْمَد يعمل في London 2024';

    return Scaffold(
      appBar: AppBar(title: const Text('arabic_dev_utils example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('1. ArabicText'),
          Text('Input: $sampleText'),
          Text('isArabic: ${ArabicText.isArabic(sampleText)}'),
          Text('isMixed: ${ArabicText.isMixed(sampleText)}'),
          Text('normalize: ${ArabicText.normalize(sampleText)}'),
          Text('wordCount: ${ArabicText.wordCount(sampleText)}'),
          const SizedBox(height: 24),
          _SectionTitle('2. ArabicSearch (live)'),
          ArabicDirectionality(
            basedOn: 'ابحث عن اسم',
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'ابحث عن اسم',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._results.map(
            (name) => ArabicDirectionality(
              basedOn: name,
              child: ListTile(title: Text(name)),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('3. ArabicNumbers'),
          Text(
            'toArabicDigits("السعر 100 ريال"): '
            '${ArabicNumbers.toArabicDigits("السعر 100 ريال")}',
          ),
          Text(
            'toEnglishDigits("١٢٣"): '
            '${ArabicNumbers.toEnglishDigits("١٢٣")}',
          ),
          Text('format(1234): ${ArabicNumbers.format(1234)}'),
          const SizedBox(height: 24),
          _SectionTitle('4. ArabicDirection'),
          Text(
            'dominantDirection("مرحبا hello"): '
            '${ArabicDirection.dominantDirection("مرحبا hello")}',
          ),
          ArabicDirectionality(
            basedOn: sampleText,
            child: Text(sampleText),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
```

- [ ] **Step 3: Fetch example dependencies**

Run: `cd example && flutter pub get && cd ..`
Expected: resolves successfully against the parent package via the `path: ../` dependency.

- [ ] **Step 4: Analyze the example app**

Run: `cd example && flutter analyze && cd ..`
Expected: `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add example/
git commit -m "feat: add example app demonstrating all four modules"
```

---

### Task 10: README and CHANGELOG

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: nothing (documentation only).
- Produces: pub.dev landing page content.

- [ ] **Step 1: Replace `README.md`**

Replace the full contents of `README.md` with:

````markdown
Useful utilities for developers building Arabic and RTL Flutter/Dart applications.

[![pub package](https://img.shields.io/pub/v/arabic_dev_utils.svg)](https://pub.dev/packages/arabic_dev_utils)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`arabic_dev_utils` is a modular toolkit for MENA app development: normalize
and classify Arabic text, search across it in a diacritic-insensitive way,
convert between Arabic and Western digits, and infer RTL/LTR direction —
without pulling in a framework or reimplementing locale-aware number
formatting yourself.

## Install

```yaml
dependencies:
  arabic_dev_utils: ^0.1.0
```

## Quick start

```dart
import 'package:arabic_dev_utils/arabic_dev_utils.dart';

// Text normalization
ArabicText.isArabic('مرحبا'); // true
ArabicText.normalize('أَحْمَد'); // 'احمد'
ArabicText.stripInvisibleChars('محمد‍علي'); // 'محمدعلي'

// Search
ArabicSearch.matches(query: 'احمد', text: 'أَحْمَد بن علي'); // true
ArabicSearch.rank('علي', ['محمد علي', 'علي حسن']); // ['علي حسن', 'محمد علي']

// Numbers
ArabicNumbers.toArabicDigits('100 ريال'); // '١٠٠ ريال'
ArabicNumbers.format(1234); // '١٬٢٣٤'

// RTL/direction
ArabicDirection.dominantDirection('مرحبا hello'); // TextDirection.mixed
ArabicDirectionality(
  basedOn: 'مرحبا',
  child: Text('مرحبا'), // rendered right-to-left automatically
);
```

## Features

### Text (`ArabicText`)
- `isArabic`, `isArabicOnly`, `isMixed` — script detection
- `removeDiacritics`, `removeTatweel` — strip tashkeel and kashida
- `normalizeAlef`, `normalizeYeh`, `normalizeTehMarbuta` — variant normalization
- `normalize` — applies all of the above in one call
- `stripInvisibleChars` — see [Why invisible-character stripping matters](#why-invisible-character-stripping-matters)
- `wordCount`, `charCount` — Arabic-aware counting

### Search (`ArabicSearch`)
- `matches` — diacritic/tatweel/alef/yeh-insensitive containment check
- `normalizeForSearch` — the aggressive normalization used internally
- `tokenize` — normalized search tokens
- `rank` — sort candidates by match quality (exact → prefix → contains)

### Numbers (`ArabicNumbers`)
- `toArabicDigits`, `toEnglishDigits` — convert between ASCII, Arabic-Indic
  (٠-٩), and Extended Arabic-Indic/Persian (۰-۹) digits
- `containsArabicDigits` — detect Arabic-Indic digits
- `format` — a thin, documented wrapper around `package:intl`'s
  `NumberFormat` for Arabic-digit output; it exists for discoverability,
  not because `intl` is inadequate

### RTL/direction (`ArabicDirection`)
- `isRtl`, `isLtr`, `isMixedDirection` — direction checks
- `dominantDirection` — returns a `TextDirection` (`rtl`, `ltr`, `mixed`,
  `neutral`)
- `ArabicDirectionality` — a `Directionality`-wrapping widget that infers
  direction from a string. `package:intl`'s `Bidi` class already exposes
  direction detection, but this widget is easier to discover and use for
  the common "set this widget's direction from a string" case.

## Why invisible-character stripping matters

Text copied from WhatsApp, Word, or many mobile keyboards can carry
invisible characters — zero-width joiners, zero-width spaces, bidi control
marks — that render identically to the naked eye but break equality
checks, search, and diffs:

```dart
const fromWhatsApp = 'محمد‍علي'; // contains a hidden ZWJ
const typedByHand = 'محمدعلي';

fromWhatsApp == typedByHand; // false — a silent bug

ArabicText.stripInvisibleChars(fromWhatsApp) ==
    ArabicText.stripInvisibleChars(typedByHand); // true
```

Without stripping, this shows up as duplicate-looking entries in a
database, search results that silently miss a match, or a diff tool
reporting a change between two strings that look the same on screen.

## Example app

See [`example/lib/main.dart`](example/lib/main.dart) for a full demo of all
four modules, including a live search box over a list of Arabic names.

## Contributing

Issues and pull requests are welcome. Please include tests for any new
behavior and keep new public API fully documented with dartdoc comments.

## License

MIT — see [LICENSE](LICENSE).
````

- [ ] **Step 2: Update `CHANGELOG.md`**

Replace the full contents of `CHANGELOG.md` with:

```markdown
## 0.1.0

Initial release.

- `ArabicText`: script detection, diacritic/tatweel/alef/yeh/teh-marbuta
  normalization, invisible-character stripping, word/char counting.
- `ArabicSearch`: diacritic-insensitive matching, tokenizing, and ranking.
- `ArabicNumbers`: Arabic-Indic and Extended Arabic-Indic digit conversion,
  `intl`-backed formatting.
- `ArabicDirection` and `ArabicDirectionality`: RTL/LTR detection and a
  convenience `Directionality`-wrapping widget.
```

- [ ] **Step 3: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: write README and changelog for v1"
```

---

### Task 11: Final verification

**Files:** none (verification only).

**Interfaces:** none.

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: all tests across `test/text/`, `test/search/`, `test/numbers/`, `test/rtl/` pass, 0 failures.

- [ ] **Step 2: Run static analysis on the package and the example**

Run: `flutter analyze && cd example && flutter analyze && cd ..`
Expected: `No issues found!` in both.

- [ ] **Step 3: Verify dartdoc coverage**

Run: `dart doc .`
Expected: completes without "missing documentation" warnings for public members. If any public class/method lacks a `///` comment, add one before proceeding — cross-check against the method tables in the spec (`docs/superpowers/specs/2026-09-17-arabic-dev-utils-v1-design.md`).

- [ ] **Step 4: Run `dart pub publish --dry-run`**

Run: `dart pub publish --dry-run`
Expected: no errors or warnings (e.g. missing `homepage`/`repository` is acceptable and won't fail the dry run, but any actual validation error must be fixed). Note any warnings in the commit message if you choose to leave them for the user to address (e.g. adding a `repository:` field once the package has a remote).

- [ ] **Step 5: Confirm no forbidden Flutter import leaked into pure-Dart files**

Run: `grep -rl "package:flutter" lib/src/ | grep -v arabic_directionality.dart`
Expected: no output (empty). If any file other than `arabic_directionality.dart` is listed, that's a spec violation — move the Flutter-dependent code out or drop the import.

- [ ] **Step 6: Commit final state (if verification produced any fixes)**

```bash
git status
```

If any fixes were made during verification, stage and commit them with a message describing what was fixed (e.g. `fix: add missing dartdoc on ArabicSearch.tokenize`). If verification produced no changes, no commit is needed.
