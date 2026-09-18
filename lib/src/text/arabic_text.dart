import 'arabic_cleaner.dart';

/// Arabic text normalization, classification, and counting utilities.
///
/// All methods are static and operate on plain [String] values — there is
/// no state to construct.
class ArabicText {
  ArabicText._();

  static final RegExp _arabicChar = RegExp(
    '[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-ﻼ]',
  );
  static final RegExp _latinChar = RegExp('[A-Za-z]');
  static final RegExp _arabicOnlyFullMatch = RegExp(
    r'^[؀-ۿݐ-ݿࢠ-ࣿﭐ-﷿ﹰ-ﻼ]+$',
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
