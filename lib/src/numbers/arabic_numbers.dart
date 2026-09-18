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
  /// [NumberFormat.decimalPattern]. The digit set and separators depend on
  /// the exact locale code: `'ar'` alone uses Western (0-9) digits under
  /// this intl version, while a country-qualified code like `'ar_EG'`
  /// produces Arabic-Indic (٠-٩) digits with Arabic grouping/decimal
  /// separators. Pass the locale that matches what you need.
  ///
  /// This is a thin, discoverability wrapper — `package:intl` already does
  /// correct locale-aware number formatting, and this method exists so
  /// consumers of this package don't have to know to reach for `intl`
  /// separately, not because `intl` is inadequate.
  static String format(num value, {String locale = 'ar'}) =>
      NumberFormat.decimalPattern(locale).format(value);
}
