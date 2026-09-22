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

  /// Whether this date has the same [year], [month], and [day] as [other].
  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  /// A hash code consistent with [operator ==].
  @override
  int get hashCode => Object.hash(year, month, day);

  /// Compares this date to [other] chronologically, by year, then month,
  /// then day.
  @override
  int compareTo(HijriDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  /// Formats this date as `YYYY-MM-DD`.
  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
