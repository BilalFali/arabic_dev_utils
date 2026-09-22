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
        HijriDate(1401, 12, 30),
        HijriDate(1400, 1, 1),
        HijriDate(1400, 1, 15),
      ]..sort((a, b) => a.compareTo(b));

      expect(dates, [
        HijriDate(1400, 1, 1),
        HijriDate(1400, 1, 15),
        HijriDate(1401, 1, 1),
        HijriDate(1401, 12, 30),
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
