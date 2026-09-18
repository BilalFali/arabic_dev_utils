# arabic_dev_utils v1 — Design Spec

## Summary

`arabic_dev_utils` is a modular Dart/Flutter toolkit for Arabic, RTL, and
MENA app development. v1 covers exactly four modules: text normalization,
search, number formatting, and RTL/direction utilities. No Hijri dates, no
currency conversion, no phone number parsing, no number-to-words — out of
scope for this version and for any future version unless explicitly
requested.

## Package layout

Single Flutter package (not split into pure-Dart + Flutter packages). The
repo is already scaffolded as a Flutter package (`pubspec.yaml` depends on
the `flutter` SDK), so splitting would add publishing/versioning overhead
without payoff for v1. Instead, Flutter dependency is isolated at the file
level: only one file imports `package:flutter`.
```
arabic_dev_utils/
├── lib/
│   ├── arabic_dev_utils.dart              // barrel export
│   └── src/
│       ├── text/
│       │   ├── arabic_text.dart           // ArabicText: normalization (pure Dart)
│       │   └── arabic_cleaner.dart        // invisible-char stripping helper (pure Dart)
│       ├── search/
│       │   └── arabic_search.dart         // ArabicSearch (pure Dart)
│       ├── numbers/
│       │   └── arabic_numbers.dart        // ArabicNumbers (pure Dart, intl dep)
│       └── rtl/
│           ├── arabic_direction.dart      // ArabicDirection + ArabicTextDirection enum (pure Dart)
│           └── arabic_directionality.dart // ArabicDirectionality widget (Flutter only)
├── test/
│   ├── text/arabic_text_test.dart
│   ├── text/arabic_cleaner_test.dart
│   ├── search/arabic_search_test.dart
│   ├── numbers/arabic_numbers_test.dart
│   └── rtl/arabic_direction_test.dart
├── example/
│   └── lib/main.dart
├── README.md
├── CHANGELOG.md
├── LICENSE
└── pubspec.yaml
```

**File-level isolation rule:** every file under `lib/src/` except
`rtl/arabic_directionality.dart` must import only `dart:core` plus
`package:meta` (and `package:intl` in `arabic_numbers.dart`) — no
`package:flutter` or `dart:ui`. This is enforced by convention/review, not
tooling, since the package ships as one pub.dev unit.

**Public API shape:** `ArabicText.stripInvisibleChars` and the other
"cleaner" behavior live in `arabic_cleaner.dart` as the implementation, but
are exposed as static methods on `ArabicText` (via a private mixin or
delegation) so the file split matches the given tree while the public
surface stays exactly the single `ArabicText` class described below — no
separate `ArabicCleaner` class in the public API.

## Module 1: `ArabicText` (lib/src/text/, priority module)

Static methods, all pure functions on `String`:

| Method | Behavior |
|---|---|
| `isArabic(String)` → bool | true if text contains any Arabic-script codepoint (U+0600–U+06FF, U+0750–U+077F, U+08A0–U+08FF, U+FB50–U+FDFF, U+FE70–U+FEFC) |

Note: the Arabic Presentation Forms-B range is deliberately capped at U+FEFC (the last assigned character, lam-alef); U+FEFD/U+FEFE are unassigned and U+FEFF is the byte-order mark (BOM), which must never be classified as Arabic/RTL script. U+FEFF is instead handled by `stripInvisibleChars`/`ArabicCleaner`.
| `isArabicOnly(String)` → bool | true if every non-whitespace, non-punctuation character is Arabic script |
| `isMixed(String)` → bool | true if text contains both Arabic-script and Latin-script characters |
| `removeDiacritics(String)` → String | strips U+064B–U+0652 and U+0670 (tashkeel: fatha, damma, kasra, shadda, sukun, tanween, dagger alef) |
| `removeTatweel(String)` → String | strips U+0640 (ـ) |
| `normalizeAlef(String)` → String | أ/إ/آ/ٱ (U+0623, U+0625, U+0622, U+0671) → ا (U+0627) |
| `normalizeYeh(String)` → String | ى (U+0649) → ي (U+064A) |
| `normalizeTehMarbuta(String)` → String | ة (U+0629) → ه (U+0647); opt-in only, called explicitly |
| `normalize(String, {bool normalizeTeh = false})` → String | applies removeDiacritics → removeTatweel → normalizeAlef → normalizeYeh → (if normalizeTeh) normalizeTehMarbuta, in that order |
| `stripInvisibleChars(String)` → String | removes ZWJ/ZWNJ (U+200C, U+200D), zero-width space (U+200B), and bidi controls (U+200E, U+200F, U+202A–U+202E, U+2066–U+2069) |
| `wordCount(String)` → int | splits on whitespace, counts non-empty tokens (Arabic has no word-internal spaces so whitespace-splitting is correct) |
| `charCount(String, {bool excludeDiacritics = false})` → int | Unicode-scalar-aware length (uses `.runes.length`, not UTF-16 `.length`, to avoid miscounting surrogate pairs); if `excludeDiacritics`, counts after `removeDiacritics` |

Dartdoc on `stripInvisibleChars` must include a "why this matters" example:
text copied from WhatsApp/Word can carry an invisible ZWJ/ZWNJ mid-word,
making `text1 == text2` fail, search miss, and diffs show phantom changes,
even though the two strings render identically.

## Module 2: `ArabicSearch` (lib/src/search/, depends on Module 1)

| Method | Behavior |
|---|---|
| `matches({required String query, required String text})` → bool | true if `normalizeForSearch(query)` is contained in `normalizeForSearch(text)` |
| `normalizeForSearch(String)` → String | `ArabicText.normalize(text, normalizeTeh: true)` then `ArabicText.stripInvisibleChars(...)` |
| `tokenize(String)` → `List<String>` | `normalizeForSearch(text).split(whitespace)`, filtering empty tokens |
| `rank(String query, List<String> candidates)` → `List<String>` | stable sort: exact normalized match first, then normalized-prefix match, then normalized-contains match, then not-matching (excluded); ties keep input order |

## Module 3: `ArabicNumbers` (lib/src/numbers/)

| Method | Behavior |
|---|---|
| `toArabicDigits(String)` → String | replaces ASCII 0–9 with ٠–٩ (U+0660–U+0669) anywhere in the string, not just pure-numeric strings |
| `toEnglishDigits(String)` → String | replaces both Arabic-Indic (٠–٩, U+0660–U+0669) and Extended Arabic-Indic/Persian (۰–۹, U+06F0–U+06F9) digits with ASCII 0–9 |
| `containsArabicDigits(String)` → bool | true if text contains any U+0660–U+0669 or U+06F0–U+06F9 |
| `format(num value, {String locale = 'ar'})` → String | thin wrapper: `NumberFormat.decimalPattern(locale).format(value)` from `package:intl`; dartdoc explains this exists for discoverability (so users don't have to know to reach for `intl` directly), not because `intl` is inadequate |

**Note (discovered during implementation):** under the pinned `intl` version, the bare `'ar'` locale code produces Western (0-9) digits, not Arabic-Indic — only country-qualified codes like `'ar_EG'` produce Arabic-Indic (٠-٩) digit output. `format()`'s dartoc documents this explicitly rather than overclaiming Arabic digit output for the plain `'ar'` default. Any README/example usage that wants to *demonstrate* Arabic-Indic digit output must call `format(value, locale: 'ar_EG')` (or another country-qualified Arabic locale), not rely on the default.

## Module 4: `ArabicDirection` + `ArabicDirectionality` (lib/src/rtl/)

`arabic_direction.dart` (pure Dart):
- `enum ArabicTextDirection { rtl, ltr, mixed, neutral }`
- `ArabicDirection.isRtl(String)` → bool — true if the first strong-directional character is RTL (Arabic/Hebrew script)
- `ArabicDirection.isLtr(String)` → bool — true if the first strong-directional character is LTR
- `ArabicDirection.isMixedDirection(String)` → bool — true if text has both RTL and LTR strong-directional characters
- `ArabicDirection.dominantDirection(String)` → `ArabicTextDirection` — `mixed` if both scripts present, else `rtl`/`ltr` based on which is present, else `neutral` if no strong-directional characters (e.g. digits/punctuation only, or empty string)

`arabic_directionality.dart` (Flutter only):
- `ArabicDirectionality({required Widget child, required String basedOn})` — wraps `Directionality`, setting `textDirection` from `ArabicDirection.dominantDirection(basedOn)` (`mixed`/`neutral` fall back to `TextDirection.ltr` from `package:flutter`). The enum was renamed from `TextDirection` to `ArabicTextDirection` to avoid colliding with Flutter's own `TextDirection` type for consumers who import both unprefixed.

README documents that `intl`'s `Bidi` class already exists and explains in
one sentence why this wrapper is easier to discover/use for the common
"set widget direction from a string" case.

## Testing plan

One test file per module, mirroring the `lib/src/` tree, using
`flutter_test`. Coverage required by the original request:
- `ArabicText`: every Alef variant individually, every diacritic mark
  individually, mixed Arabic/English/number strings, empty string,
  punctuation-only string, and ≥2 invisible-character-corruption cases
  (same visible text, one copy with a ZWJ injected mid-word — assert
  unequal before `stripInvisibleChars`, equal after).
- `ArabicSearch`: normalization insensitivity (diacritics/tatweel/alef/yeh),
  ranking order correctness.
- `ArabicNumbers`: round-trip digit conversion, Extended Arabic-Indic
  handling, `format` sanity check.
- `ArabicDirection`: each `ArabicTextDirection` case, `ArabicDirectionality`
  widget smoke test (pumps a widget, checks resolved `Directionality`).

## Non-functional requirements

- Dart 3, null-safe, SDK `^3.12.0`, Flutter `>=1.17.0` (existing constraint).
- Zero runtime deps beyond `meta` and `intl`.
- 100% dartdoc coverage on public API (checked via `dart doc` / pana lint,
  not a hard test).
- Target pana score 160/160: valid `pubspec.yaml` (description, homepage
  left blank is fine — no `homepage:` value required for pana, but a
  non-generic `description` is), MIT `LICENSE` filled in, no analyzer
  warnings under `flutter_lints`, example app present, platform support
  declared.
- `LICENSE`: standard MIT text, copyright holder using the account email
  (bilalfali60@gmail.com) since no other name was given.
- `example/lib/main.dart`: Flutter demo covering all four modules, with a
  live-updating search box over a hardcoded list of Arabic names using
  `ArabicSearch`.

## Out of scope (explicit)

Hijri dates, currency conversion, phone number parsing beyond digit
conversion, number-to-words. Do not add these in v1 or opportunistically.
