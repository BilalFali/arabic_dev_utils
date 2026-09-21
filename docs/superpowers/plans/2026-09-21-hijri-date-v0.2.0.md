# HijriDate v0.2.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fifth module, `HijriDate`, to `arabic_dev_utils`: conversion between the Gregorian calendar (`DateTime`) and the tabular (civil-epoch) Hijri calendar.

**Architecture:** A single pure-Dart, dependency-free class (`HijriDate`) that converts through an integer Julian Day Number (JDN) intermediate using closed-form arithmetic formulas. No new Flutter code, no new third-party dependency. Barrel-exported alongside the existing four modules.

**Tech Stack:** Dart 3 (records, pattern-matching destructuring), `dart:core` only.

**Spec:** `docs/superpowers/specs/2026-09-21-hijri-date-design.md`

## Global Constraints

- Dart SDK `^3.12.0` (already set in `pubspec.yaml`, unchanged).
- Zero new runtime dependencies — `hijri_date.dart` imports only `dart:core`.
- 100% of public API members must have dartdoc (`///`) comments, and `HijriDate`'s class-level doc must state plainly that it is a computed (tabular) calendar, not a moon-sighting calendar, and may differ from the Umm al-Qura civil calendar by a day or two.
- Conversion operates on `DateTime`'s date components only (`year`/`month`/`day`) — time-of-day and timezone are ignored on the way in; `toGregorian()` returns local (non-UTC) midnight.
- `HijriDate`'s constructor validates `month` (1–12) and `day` (1 to the correct days-in-month, per the leap-year rule below) and throws `ArgumentError.value` for anything out of range. `year` is not range-validated.
- Leap year rule: a Hijri year is leap if `(11 * year + 14) % 30 < 11`. Days per month: odd months (1,3,5,7,9,11) = 30; even months (2,4,6,8,10) = 29; month 12 = 30 in a leap year, 29 otherwise.
- `toString()` format: `'YYYY-MM-DD'` with month and day zero-padded to 2 digits; year not padded.
- Out of scope — do not implement: Hijri month/day names, any text formatting beyond the plain `toString()`, the Umm al-Qura table-based calendar, moon-sighting calendars, any other calendar system, currency conversion, phone number parsing, number-to-words.
- Every task ends with `flutter test` passing and a commit.

---

## File Structure

```
lib/
  arabic_dev_utils.dart          (modify: add export)
  src/
    hijri/
      hijri_date.dart            (new)
test/
  hijri/
    hijri_date_test.dart         (new)
pubspec.yaml                     (modify: version bump)
CHANGELOG.md                     (modify: add 0.2.0 entry)
README.md                        (modify: add Hijri section + quickstart line)
example/
  lib/
    main.dart                    (modify: add Hijri reference section)
```

---

### Task 1: `HijriDate` — Gregorian/Hijri conversion

**Files:**
- Create: `lib/src/hijri/hijri_date.dart`
- Test: `test/hijri/hijri_date_test.dart`

**Interfaces:**
- Consumes: nothing (pure `dart:core`, no dependency on other modules).
- Produces: `HijriDate` class — constructor `HijriDate(int year, int month, int day)` (validates, throws `ArgumentError`), `HijriDate.fromGregorian(DateTime date)` factory, `DateTime toGregorian()`, `int year`/`month`/`day` fields, `operator ==`, `hashCode`, `compareTo(HijriDate other)` (implements `Comparable<HijriDate>`), `toString()`. Used by the barrel export in Task 2 and the example app in Task 5.

- [ ] **Step 1: Write the failing test**

Create `test/hijri/hijri_date_test.dart`:

```dart
import 'package:arabic_dev_utils/src/hijri/hijri_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HijriDate.fromGregorian / toGregorian round-trip', () {
    final sampleDates = [
      DateTime(2000, 1, 1),
      DateTime(2000, 2, 29),
      DateTime(1999, 12, 31),
      DateTime(2024, 3, 1),
      DateTime(1950, 6, 15),
      DateTime(2100, 1, 1),
      DateTime(1900, 1, 1),
      DateTime(2023, 7, 19),
    ];

    for (final date in sampleDates) {
      test('round-trips $date', () {
        final hijri = HijriDate.fromGregorian(date);
        expect(hijri.toGregorian(), date);
      });
    }
  });

  group('HijriDate Hijri -> Gregorian -> Hijri round-trip', () {
    final sampleHijriDates = [
      HijriDate(1400, 1, 1),
      HijriDate(1400, 1, 30),
      HijriDate(1400, 2, 29),
      HijriDate(1401, 12, 30),
      HijriDate(1445, 6, 15),
      HijriDate(1500, 9, 30),
    ];

    for (final hijri in sampleHijriDates) {
      test('round-trips $hijri', () {
        final gregorian = hijri.toGregorian();
        expect(HijriDate.fromGregorian(gregorian), hijri);
      });
    }
  });

  group('HijriDate epoch anchor', () {
    test('1 Muharram, 1 AH round-trips to itself', () {
      final epoch = HijriDate(1, 1, 1);
      expect(HijriDate.fromGregorian(epoch.toGregorian()), epoch);
    });

    test('1 Muharram, 1 AH falls in Gregorian year 622', () {
      final epoch = HijriDate(1, 1, 1);
      expect(epoch.toGregorian().year, 622);
    });
  });

  group('HijriDate validation', () {
    test('throws for month 0', () {
      expect(() => HijriDate(1400, 0, 1), throwsArgumentError);
    });

    test('throws for month 13', () {
      expect(() => HijriDate(1400, 13, 1), throwsArgumentError);
    });

    test('throws for day 0', () {
      expect(() => HijriDate(1400, 1, 0), throwsArgumentError);
    });

    test('throws for day 30 on an even (29-day) month', () {
      expect(() => HijriDate(1400, 2, 30), throwsArgumentError);
    });

    test('throws for day 30 on Dhu al-Hijjah in a non-leap year', () {
      // 1400 AH is not a leap year: (11*1400 + 14) % 30 == 24, not < 11.
      expect(() => HijriDate(1400, 12, 30), throwsArgumentError);
    });

    test('accepts day 30 on Dhu al-Hijjah in a leap year', () {
      // 1401 AH is a leap year: (11*1401 + 14) % 30 == 5, < 11.
      expect(() => HijriDate(1401, 12, 30), returnsNormally);
    });

    test('accepts day 30 on an odd (30-day) month', () {
      expect(() => HijriDate(1400, 1, 30), returnsNormally);
    });
  });

  group('HijriDate equality, hashCode, compareTo', () {
    test('equal dates are ==', () {
      expect(HijriDate(1400, 5, 10), HijriDate(1400, 5, 10));
    });

    test('equal dates have equal hashCode', () {
      expect(
        HijriDate(1400, 5, 10).hashCode,
        HijriDate(1400, 5, 10).hashCode,
      );
    });

    test('compareTo orders by year, then month, then day', () {
      final dates = [
        HijriDate(1401, 1, 1),
        HijriDate(1400, 12, 30),
        HijriDate(1400, 1, 1),
        HijriDate(1400, 1, 15),
      ]..sort((a, b) => a.compareTo(b));

      expect(dates, [
        HijriDate(1400, 1, 1),
        HijriDate(1400, 1, 15),
        HijriDate(1400, 12, 30),
        HijriDate(1401, 1, 1),
      ]);
    });
  });

  group('HijriDate.toString', () {
    test('formats as zero-padded YYYY-MM-DD', () {
      expect(HijriDate(1447, 3, 21).toString(), '1447-03-21');
    });

    test('zero-pads single-digit month and day', () {
      expect(HijriDate(1400, 1, 5).toString(), '1400-01-05');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/hijri/hijri_date_test.dart`
Expected: FAIL — `hijri_date.dart` does not exist / `HijriDate` undefined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/src/hijri/hijri_date.dart`:

```dart
/// A date in the Hijri (Islamic) calendar.
///
/// Uses the tabular Islamic calendar, civil epoch variant — a
/// deterministic, table-free arithmetic calendar (the same algorithm used
/// by ICU's `islamic-civil` calendar and glibc). **This is a computed
/// calendar, not a moon-sighting calendar**: it will not always agree with
/// locally announced Hijri dates or the Umm al-Qura civil calendar used in
/// Saudi Arabia, which can differ by a day or two around month boundaries.
///
/// Conversion operates on date components only. [fromGregorian] reads only
/// a [DateTime]'s `year`/`month`/`day` (time-of-day and timezone are
/// ignored), and [toGregorian] returns local (non-UTC) midnight.
///
/// Correctness is defined for Hijri years from 1 AH onward (Gregorian
/// dates from approximately 622 CE onward); behavior before the Hijri
/// epoch is unspecified.
class HijriDate implements Comparable<HijriDate> {
  /// Creates a [HijriDate], validating [month] (1-12) and [day] (1 to the
  /// number of days in that month/year) and throwing [ArgumentError] if
  /// either is out of range.
  HijriDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be between 1 and 12');
    }
    final maxDay = _daysInMonth(year, month);
    if (day < 1 || day > maxDay) {
      throw ArgumentError.value(
        day,
        'day',
        'must be between 1 and $maxDay for month $month of year $year',
      );
    }
  }

  /// Converts [date]'s year/month/day components (ignoring time-of-day and
  /// timezone) to a [HijriDate].
  factory HijriDate.fromGregorian(DateTime date) {
    final jdn = _gregorianToJdn(date.year, date.month, date.day);
    final (year, month, day) = _jdnToHijri(jdn);
    return HijriDate(year, month, day);
  }

  /// The Hijri year.
  final int year;

  /// The Hijri month, 1-12.
  final int month;

  /// The Hijri day of month.
  final int day;

  /// Converts this Hijri date to a Gregorian [DateTime] at local midnight.
  DateTime toGregorian() {
    final jdn = _hijriToJdn(year, month, day);
    final (y, m, d) = _jdnToGregorian(jdn);
    return DateTime(y, m, d);
  }

  static bool _isLeapYear(int year) => (11 * year + 14) % 30 < 11;

  static int _daysInMonth(int year, int month) {
    if (month == 12 && _isLeapYear(year)) return 30;
    return month.isOdd ? 30 : 29;
  }

  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  static (int, int, int) _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + (m ~/ 10);
    return (year, month, day);
  }

  static (int, int, int) _jdnToHijri(int jdn) {
    var l = jdn - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * l) ~/ 709;
    final day = l - (709 * month) ~/ 24;
    final year = 30 * n + j - 30;
    return (year, month, day);
  }

  static int _hijriToJdn(int year, int month, int day) {
    return (11 * year + 3) ~/ 30 +
        354 * year +
        30 * month -
        (month - 1) ~/ 2 +
        day +
        1948440 -
        385;
  }

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  int compareTo(HijriDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/hijri/hijri_date_test.dart`
Expected: PASS (all tests).

If the two epoch-anchor tests or any round-trip test fails, treat it as a
possible genuine arithmetic bug in the transcribed formulas (compare very
carefully against the spec's formulas, term by term) before assuming the
test itself is wrong — but if after careful comparison the implementation
matches the spec's formulas exactly and a specific assertion still looks
wrong, report `DONE_WITH_CONCERNS` with your reasoning rather than editing
either the formulas or the test blindly. This project has a history of
catching this class of issue at review time (see git log for "tanween" and
"FB1D" fixes) — flagging is the correct move, not guessing.

- [ ] **Step 5: Commit**

```bash
git add lib/src/hijri/hijri_date.dart test/hijri/hijri_date_test.dart
git commit -m "feat: add HijriDate Gregorian/Hijri calendar conversion"
```

---

### Task 2: Barrel export

**Files:**
- Modify: `lib/arabic_dev_utils.dart`

**Interfaces:**
- Consumes: `HijriDate` (Task 1).
- Produces: `HijriDate` reachable via `import 'package:arabic_dev_utils/arabic_dev_utils.dart';`.

- [ ] **Step 1: Add the export**

In `lib/arabic_dev_utils.dart`, add one line alongside the existing five exports:

```dart
export 'src/hijri/hijri_date.dart';
```

The full file should read:

```dart
/// Utilities for developers building Arabic and RTL Flutter/Dart
/// applications: text normalization, invisible-character cleanup,
/// Arabic-aware search, digit conversion, RTL direction helpers, and
/// Hijri/Gregorian calendar conversion.
library;

export 'src/text/arabic_text.dart';
export 'src/search/arabic_search.dart';
export 'src/numbers/arabic_numbers.dart';
export 'src/rtl/arabic_direction.dart';
export 'src/rtl/arabic_directionality.dart';
export 'src/hijri/hijri_date.dart';
```

(Note the doc comment above `library;` also gains "and Hijri/Gregorian
calendar conversion" at the end — update it to match exactly.)

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: PASS — all tests from Task 1 plus every pre-existing test.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/arabic_dev_utils.dart
git commit -m "feat: export HijriDate from the package barrel"
```

---

### Task 3: Version bump and CHANGELOG

**Files:**
- Modify: `pubspec.yaml`
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing consumed by later tasks — this is a bookkeeping-only task.

- [ ] **Step 1: Bump the version**

In `pubspec.yaml`, change:

```yaml
version: 0.1.0
```

to:

```yaml
version: 0.2.0
```

- [ ] **Step 2: Add a CHANGELOG entry**

Read the current `CHANGELOG.md` first. Add a new entry **above** the existing `## 0.1.0` section (newest first):

```markdown
## 0.2.0

- `HijriDate`: conversion between the Gregorian calendar and the tabular
  (civil-epoch) Hijri calendar, via `HijriDate.fromGregorian` and
  `toGregorian()`. This is a computed calendar, not a moon-sighting
  calendar — see the class dartdoc for details.

```

- [ ] **Step 3: Fetch dependencies to confirm the version bump resolves cleanly**

Run: `flutter pub get`
Expected: resolves successfully with no errors.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to 0.2.0 for HijriDate"
```

---

### Task 4: README update

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: `HijriDate.fromGregorian`, `.toGregorian()` (Task 1).
- Produces: nothing consumed by later tasks — documentation only.

- [ ] **Step 1: Add a Hijri example to the quickstart code block**

Read the current `README.md` first, to see the exact quickstart block. Add
these two lines to the end of the fenced quickstart code block (after the
`ArabicDirectionality(...)` example, before the closing ` ``` `):

```dart

// Hijri calendar
HijriDate.fromGregorian(DateTime(2024, 3, 20)); // a HijriDate
HijriDate(1445, 9, 10).toGregorian(); // a DateTime
```

- [ ] **Step 2: Add a Features subsection**

Add a new subsection after the existing `### RTL/direction (\`ArabicDirection\`)`
subsection (keep the same `###`-level heading style as the other four):

```markdown
### Hijri calendar (`HijriDate`)
- `HijriDate.fromGregorian(DateTime)` / `.toGregorian()` — convert between
  the Gregorian calendar and the tabular (civil-epoch) Hijri calendar
- This is a **computed** calendar, not a moon-sighting calendar — it will
  not always agree with locally announced Hijri dates or the Umm al-Qura
  civil calendar used in Saudi Arabia, which can differ by a day or two
  around month boundaries
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: document HijriDate in README"
```

---

### Task 5: Example app reference section

**Files:**
- Modify: `example/lib/main.dart`

**Interfaces:**
- Consumes: `HijriDate.fromGregorian`, `.toGregorian()` (Task 1); `_ReferenceSection`, `_TransformRow`, `_Tag` (existing widgets already in this file — do not redefine them).

- [ ] **Step 1: Add the import**

Read the current `example/lib/main.dart` first. At the top of the file,
the existing import is:

```dart
import 'package:arabic_dev_utils/arabic_dev_utils.dart';
```

`HijriDate` is exported from that same barrel (Task 2), so no new import
line is needed — just use `HijriDate` directly.

- [ ] **Step 2: Add a fifth `_ReferenceSection`**

In the `build` method of `_HomePageState`, after the existing `Direction`
`_ReferenceSection` block and before the `const SizedBox(height: 24)` /
"Package version" footer, add:

```dart
              _ReferenceSection(
                label: 'Hijri calendar',
                description:
                    'Converts between Gregorian and the tabular '
                    '(civil-epoch) Hijri calendar — a computed calendar, '
                    'not a moon-sighting one.',
                children: [
                  _TransformRow(
                    before: '2024-03-20',
                    after: HijriDate.fromGregorian(
                      DateTime(2024, 3, 20),
                    ).toString(),
                    caption: 'HijriDate.fromGregorian(DateTime(2024, 3, 20))',
                  ),
                  const SizedBox(height: 12),
                  _TransformRow(
                    before: '1445-09-10',
                    after: HijriDate(
                      1445,
                      9,
                      10,
                    ).toGregorian().toIso8601String().split('T').first,
                    caption: 'HijriDate(1445, 9, 10).toGregorian()',
                  ),
                ],
              ),
```

- [ ] **Step 3: Fetch dependencies and analyze**

Run: `cd example && flutter pub get && flutter analyze && cd ..`
Expected: resolves cleanly, `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add example/lib/main.dart
git commit -m "feat: add HijriDate demo to example app"
```

---

### Task 6: Final verification

**Files:** none (verification only).

**Interfaces:** none.

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: 0 failures across the whole suite (pre-existing tests plus Task 1's new `test/hijri/` tests).

- [ ] **Step 2: Run static analysis on the package and the example**

Run: `flutter analyze && cd example && flutter analyze && cd ..`
Expected: `No issues found!` in both.

- [ ] **Step 3: Confirm no Flutter import leaked into `hijri_date.dart`**

Run: `grep -n "package:flutter" lib/src/hijri/hijri_date.dart`
Expected: no output (empty). `hijri_date.dart` must stay pure Dart.

- [ ] **Step 4: Run `dart pub publish --dry-run`**

Run: `dart pub publish --dry-run`
Expected: no errors; the only acceptable warning is "1 checked-in file is
modified in git" if this step runs before Task 6's own commit, or no
warnings at all if run after. No validation errors.

- [ ] **Step 5: Verify dartdoc coverage**

Run: `dart doc .`
Expected: completes with 0 missing-documentation warnings. (If the
SDK-bundled `dartdoc` crashes with an unrelated `RangeError` — a known
pre-existing toolchain issue with this Flutter SDK version, documented in
this project's git history — install and use a newer one instead: `dart
pub global activate dartdoc` then `dart pub global run dartdoc`.) If any
public member of `HijriDate` is missing a dartdoc comment, add it.

- [ ] **Step 6: Commit final state (if verification produced any fixes)**

```bash
git status
```

If any fixes were made during verification, stage and commit them with a
message describing what was fixed. If verification produced no changes,
no commit is needed.
