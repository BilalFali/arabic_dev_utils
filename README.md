Useful utilities for developers building Arabic and RTL Flutter/Dart applications.

[![pub package](https://img.shields.io/pub/v/arabic_dev_utils.svg)](https://pub.dev/packages/arabic_dev_utils)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`arabic_dev_utils` is a modular toolkit for MENA app development: normalize
and classify Arabic text, search across it in a diacritic-insensitive way,
convert between Arabic and Western digits, infer RTL/LTR direction, and
convert between the Hijri and Gregorian calendars — without pulling in a
framework or reimplementing locale-aware number formatting yourself.

## Install

```yaml
dependencies:
  arabic_dev_utils: ^0.2.0
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
ArabicNumbers.format(1234, locale: 'ar_EG'); // '١٬٢٣٤'

// RTL/direction
ArabicDirection.dominantDirection('مرحبا hello'); // ArabicTextDirection.mixed
ArabicDirectionality(
  basedOn: 'مرحبا',
  child: Text('مرحبا'), // rendered right-to-left automatically
);

// Hijri calendar
HijriDate.fromGregorian(DateTime(2024, 3, 20)); // a HijriDate
HijriDate(1445, 9, 10).toGregorian(); // a DateTime
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
- `dominantDirection` — returns an `ArabicTextDirection` (`rtl`, `ltr`, `mixed`,
  `neutral`)
- `ArabicDirectionality` — a `Directionality`-wrapping widget that infers
  direction from a string. `package:intl`'s `Bidi` class already exposes
  direction detection, but this widget is easier to discover and use for
  the common "set this widget's direction from a string" case.

### Hijri calendar (`HijriDate`)
- `HijriDate.fromGregorian(DateTime)` / `.toGregorian()` — convert between
  the Gregorian calendar and the tabular (civil-epoch) Hijri calendar
- This is a **computed** calendar, not a moon-sighting calendar — it will
  not always agree with locally announced Hijri dates or the Umm al-Qura
  civil calendar used in Saudi Arabia, which can differ by a day or two
  around month boundaries

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
