/// The dominant reading direction of a piece of text.
enum ArabicTextDirection {
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
    '[\u0590-\u05FF\u0600-\u06FF\u0700-\u074F\u0750-\u077F\u08A0-\u08FF'
    '\uFB1D-\uFDFF\uFE70-\uFEFC]',
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

  /// Returns the dominant [ArabicTextDirection] of [text] based on the
  /// presence of right-to-left and left-to-right strong-directional
  /// characters. LTR detection covers Latin script (A-Z, a-z) only — other
  /// left-to-right scripts (Cyrillic, CJK, etc.) are treated as neutral.
  static ArabicTextDirection dominantDirection(String text) {
    final hasRtl = _rtlChar.hasMatch(text);
    final hasLtr = _ltrChar.hasMatch(text);
    if (hasRtl && hasLtr) return ArabicTextDirection.mixed;
    if (hasRtl) return ArabicTextDirection.rtl;
    if (hasLtr) return ArabicTextDirection.ltr;
    return ArabicTextDirection.neutral;
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
