## 0.2.0

- `HijriDate`: conversion between the Gregorian calendar and the tabular
  (civil-epoch) Hijri calendar, via `HijriDate.fromGregorian` and
  `toGregorian()`. This is a computed calendar, not a moon-sighting
  calendar — see the class dartdoc for details.

## 0.1.0

Initial release.

- `ArabicText`: script detection, diacritic/tatweel/alef/yeh/teh-marbuta
  normalization, invisible-character stripping, word/char counting.
- `ArabicSearch`: diacritic-insensitive matching, tokenizing, and ranking.
- `ArabicNumbers`: Arabic-Indic and Extended Arabic-Indic digit conversion,
  `intl`-backed formatting.
- `ArabicDirection` and `ArabicDirectionality`: RTL/LTR detection and a
  convenience `Directionality`-wrapping widget.
