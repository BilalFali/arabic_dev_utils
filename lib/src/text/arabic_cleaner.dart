import 'package:meta/meta.dart';

/// Internal helper backing [ArabicText.stripInvisibleChars]. Not part of
/// the public API — use `ArabicText.stripInvisibleChars` instead.
@internal
class ArabicCleaner {
  ArabicCleaner._();

  /// Matches zero-width joiner/non-joiner, zero-width space, and
  /// bidirectional control characters that are invisible when rendered
  /// but affect string equality, search, and diffing.
  static final RegExp invisibleChars = RegExp(
    '[​-‏‪-‮⁦-⁩]',
  );

  /// Removes all characters matched by [invisibleChars] from [text].
  static String strip(String text) => text.replaceAll(invisibleChars, '');
}
