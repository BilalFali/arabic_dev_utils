# HijriDate v0.2.0 — Design Spec

## Summary

Adds a fifth module, `HijriDate`, to `arabic_dev_utils`: conversion between
the Gregorian calendar (`DateTime`) and the Hijri (Islamic) calendar.
Conversion only — no month/day name formatting, no locale-aware display, no
Umm al-Qura (table-based, moon-sighting-aligned) calendar. Those are
explicitly out of scope for this version, same as they were out of scope
for v1.

## Algorithm

The **tabular Islamic calendar, civil epoch** variant (the same algorithm
used by ICU's `islamic-civil` calendar and glibc): a deterministic,
table-free arithmetic algorithm with an 11-leap-years-per-30-year cycle. No
runtime data table, no network/astronomical lookup — consistent with the
package's zero-runtime-dependency philosophy.

**This is a computed calendar, not a moon-sighting calendar.** It will not
always agree with locally announced Hijri dates or the Umm al-Qura civil
calendar used in Saudi Arabia — those depend on lunar observation or an
official table and can differ from the arithmetic calendar by a day or two
around month boundaries. `HijriDate`'s dartdoc and the README must state
this plainly so it is not mistaken for an "official" calendar.

All conversions route through the Julian Day Number (JDN) as an integer
intermediate, using well-established closed-form integer-arithmetic
formulas (all divisions below are floor/integer division, matching Dart's
`~/` operator):

**Gregorian → JDN** (Fliegel & Van Flandern):
```
a = (14 - month) ~/ 12
y = year + 4800 - a
m = month + 12*a - 3
jdn = day + (153*m + 2) ~/ 5 + 365*y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045
```

**JDN → Gregorian** (inverse Fliegel & Van Flandern):
```
a = jdn + 32044
b = (4*a + 3) ~/ 146097
c = a - (146097*b) ~/ 4
d = (4*c + 3) ~/ 1461
e = c - (1461*d) ~/ 4
m = (5*e + 2) ~/ 153
day = e - (153*m + 2) ~/ 5 + 1
month = m + 3 - 12*(m ~/ 10)
year = 100*b + d - 4800 + (m ~/ 10)
```

**JDN → Hijri** (civil/tabular; epoch JDN 1948440 = 1 Muharram, 1 AH):
```
l = jdn - 1948440 + 10632
n = (l - 1) ~/ 10631
l = l - 10631*n + 354
j = ((10985 - l) ~/ 5316) * ((50*l) ~/ 17719) + (l ~/ 5670) * ((43*l) ~/ 15238)
l = l - ((30 - j) ~/ 15) * ((17719*j) ~/ 50) - (j ~/ 16) * ((15238*j) ~/ 43) + 29
hijriMonth = (24*l) ~/ 709
hijriDay = l - (709*hijriMonth) ~/ 24
hijriYear = 30*n + j - 30
```

**Hijri → JDN**:
```
jdn = (11*hijriYear + 3) ~/ 30 + 354*hijriYear + 30*hijriMonth
      - (hijriMonth - 1) ~/ 2 + hijriDay + 1948440 - 385
```

**Leap year rule** (derived from the same civil/tabular definition, used
for day-count validation, not for the JDN formulas above which don't need
it directly): a Hijri year is leap if `(11 * year + 14) % 30 < 11`.

**Days per Hijri month:** odd months (1, 3, 5, 7, 9, 11) have 30 days; even
months (2, 4, 6, 8, 10) have 29 days; month 12 (Dhu al-Hijjah) has 30 days
in a leap year, 29 otherwise.

**Scope of correctness:** conversion is defined and tested for Hijri years
from 1 AH onward (Gregorian dates from approximately 622 CE onward, per
the proleptic Gregorian calendar `DateTime` itself uses). Behavior for
dates before the Hijri epoch is unspecified — not a primary use case for a
package aimed at contemporary Arabic/MENA app development, and not worth
the added validation complexity for v0.2.0.

## Module

New file: `lib/src/hijri/hijri_date.dart` (pure Dart — no `package:flutter`,
no `package:intl`, no `package:meta` needed; only `dart:core`).

```dart
class HijriDate implements Comparable<HijriDate> {
  HijriDate(this.year, this.month, this.day); // validates, throws ArgumentError
  final int year;
  final int month; // 1-12
  final int day;   // 1-29 or 1-30, depending on month/leap year

  factory HijriDate.fromGregorian(DateTime date);
  DateTime toGregorian();

  @override
  bool operator ==(Object other);
  @override
  int get hashCode;
  @override
  int compareTo(HijriDate other);
  @override
  String toString(); // e.g. '1447-03-21' (zero-padded month/day)
}
```

**Conversion operates on date components only.** `HijriDate.fromGregorian`
reads only `date.year`, `date.month`, `date.day` from the given `DateTime`
— time-of-day and timezone are ignored. `toGregorian()` returns a
`DateTime` constructed via the plain (non-UTC) `DateTime(year, month, day)`
constructor, at midnight local time. This matches how calendar-only
conversions are conventionally handled (compare `DateTime`'s own `.year`/
`.month`/`.day` component model) and keeps the API from having to make
timezone decisions it has no information to make correctly.

**Validation:** the primary constructor validates `month` (1–12) and `day`
(1 to the correct days-in-month for that year/month, per the leap-year
rule above) and throws `ArgumentError.value` with a descriptive message
for anything out of range. `year` is not range-validated (proleptic years
before 1 AH or arbitrarily large years are accepted; only their JDN
arithmetic and `toGregorian()` output are affected, not the constructor).

**Equality, ordering, `toString`:** `==`/`hashCode` compare
`(year, month, day)`; `compareTo` orders chronologically the same way;
`toString()` renders as `'YYYY-MM-DD'` with month and day zero-padded to 2
digits (year is not zero-padded beyond its natural digit count, since
proleptic/far-future years may exceed 4 digits).

## Barrel export

`lib/arabic_dev_utils.dart` gains one more export:
`export 'src/hijri/hijri_date.dart';` — `HijriDate` becomes part of the
public API alongside `ArabicText`, `ArabicSearch`, `ArabicNumbers`,
`ArabicDirection`, `ArabicTextDirection`, `ArabicDirectionality`.

## Testing plan

Round-trip testing is the primary correctness strategy — it is
self-verifying and does not require hand-sourcing external "ground truth"
Hijri/Gregorian date pairs (a class of test-literal error this project has
hit before: plan-authored expected-value literals for domain conversions
are exactly the kind of thing a human/LLM author can get subtly wrong by
hand, as happened with three tanween-diacritic test literals earlier in
this package's history). Concretely:

- **Round-trip, Gregorian → Hijri → Gregorian:** for a representative
  spread of Gregorian dates (at minimum: a date in each of several
  different years across a ~50-year span, including a leap year in the
  standard Gregorian sense and a non-leap year, and the 1st/15th/last day
  of assorted months), assert
  `HijriDate.fromGregorian(date).toGregorian() == date`.
- **Round-trip, Hijri → Gregorian → Hijri:** for a representative spread of
  valid `HijriDate` values (including day 30 of an odd month, day 29 of an
  even month, and Dhu al-Hijjah in both a leap and non-leap Hijri year),
  assert `HijriDate.fromGregorian(hijriDate.toGregorian()) == hijriDate`.
- **Epoch anchor (the one hand-checkable literal, and it's inherent to the
  algorithm's own defining constant, not externally sourced):**
  `HijriDate` for JDN 1948440 is 1 Muharram, 1 AH — i.e.
  `HijriDate(1, 1, 1)`. Verify this by asserting
  `HijriDate(1, 1, 1).toGregorian()` round-trips back to
  `HijriDate(1, 1, 1)` via `fromGregorian`, AND, separately, that the
  Gregorian year of `HijriDate(1, 1, 1).toGregorian()` is `622` (the
  well-known, widely-documented year the Hijri calendar epoch falls in —
  low-risk to hand-verify since it's a single round number, not a
  day/month literal).
- **Validation:** `HijriDate` constructor throws `ArgumentError` for
  `month` outside 1–12, for `day` 0 or negative, for `day` 30 on an even
  (29-day) month, and for `day` 30 on Dhu al-Hijjah (month 12) in a
  non-leap Hijri year.
- **Leap year rule:** at least one known-leap and one known-non-leap Hijri
  year (computed from the stated formula `(11*year + 14) % 30 < 11`, not
  hand-picked from an external source), confirming day 30 of Dhu al-Hijjah
  is valid in the leap year and rejected in the non-leap year.
- **Ordering/equality:** `HijriDate` equality, `hashCode` consistency, and
  `compareTo` ordering across a small set of dates spanning month and year
  boundaries.
- **`toString`:** exact format check per the zero-padding rule above:
  `HijriDate(1447, 3, 21).toString() == '1447-03-21'` (month and day
  zero-padded to 2 digits; year not padded).

## Non-functional requirements

- Dart 3, null-safe, zero additional runtime dependencies (pure
  `dart:core` arithmetic).
- 100% dartdoc coverage on `HijriDate` and all its public members, plus
  the "computed calendar, not moon-sighting" caveat stated prominently on
  the class-level doc comment (not just buried in this spec).
- Version bump: `pubspec.yaml` version `0.1.0` → `0.2.0` (new public API,
  additive/non-breaking — matches semver minor-version-bump convention).
- `CHANGELOG.md` gains a `## 0.2.0` entry describing the new module.
- `README.md` gains a fifth module section (mirroring the existing four),
  including the moon-sighting caveat, and the quickstart code block gains
  a `HijriDate` example.
- Example app (`example/lib/main.dart`) gains a fifth reference section
  demonstrating `HijriDate.fromGregorian`/`.toGregorian()`, following the
  existing ink-and-gold design system already in place (accent-rule
  section, before→after transform row) — no new design system work
  needed, just a new section using existing shared widgets
  (`_ReferenceSection`, `_TransformRow`, `_Tag`).

## Out of scope (explicit)

Hijri month/day names, any text formatting beyond `toString()`'s plain
`'YYYY-MM-DD'`, the Umm al-Qura table-based calendar, moon-sighting-based
calendars, any other calendar system (Coptic, Persian, etc.), currency
conversion, phone number parsing, number-to-words — none of these are
implemented in v0.2.0 or opportunistically.
