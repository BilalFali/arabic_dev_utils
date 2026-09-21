import 'package:flutter/widgets.dart';

import 'arabic_direction.dart' as detect;

/// Wraps [child] in a [Directionality] whose text direction is inferred
/// from [basedOn] using [detect.ArabicDirection.isRtl] — the direction of
/// the first strong-directional character in [basedOn].
///
/// This exists as a convenience layer: `package:intl` already exposes a
/// `Bidi` class for direction detection, but `ArabicDirectionality` is
/// easier to discover and use for the common case of "set this widget's
/// direction from a string" without looking up `Bidi`'s API.
///
/// First-strong-character resolution is the standard approach used by
/// browsers' `dir="auto"` and ICU's bidi direction guessing: a sentence
/// that is mostly Arabic with an embedded Latin word or number (e.g.
/// `'أحمد يعمل في London'`) still reads as RTL overall, because it opens
/// with an Arabic character — the embedded Latin run is placed correctly
/// within that RTL paragraph by Flutter's own bidi text layout regardless
/// of the paragraph's base direction. Text with no strong-directional
/// character at all (digits/punctuation only, or an empty string) resolves
/// to [TextDirection.ltr], since there is no directional signal to read.
class ArabicDirectionality extends StatelessWidget {
  /// Creates an [ArabicDirectionality] that infers direction from
  /// [basedOn].
  const ArabicDirectionality({
    super.key,
    required this.child,
    required this.basedOn,
  });

  /// The widget to render inside the inferred [Directionality].
  final Widget child;

  /// The text used to infer the reading direction.
  final String basedOn;

  @override
  Widget build(BuildContext context) {
    final resolved = detect.ArabicDirection.isRtl(basedOn)
        ? TextDirection.rtl
        : TextDirection.ltr;
    return Directionality(textDirection: resolved, child: child);
  }
}
