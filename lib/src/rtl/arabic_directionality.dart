import 'package:flutter/widgets.dart';

import 'arabic_direction.dart' as detect;

/// Wraps [child] in a [Directionality] whose text direction is inferred
/// from [basedOn] using [detect.ArabicDirection.dominantDirection].
///
/// This exists as a convenience layer: `package:intl` already exposes a
/// `Bidi` class for direction detection, but `ArabicDirectionality` is
/// easier to discover and use for the common case of "set this widget's
/// direction from a string" without looking up `Bidi`'s API.
///
/// [detect.TextDirection.mixed] and [detect.TextDirection.neutral] both
/// resolve to [TextDirection.ltr], since there is no single correct choice
/// for genuinely mixed or non-directional text.
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
    final direction = detect.ArabicDirection.dominantDirection(basedOn);
    final resolved = direction == detect.TextDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    return Directionality(textDirection: resolved, child: child);
  }
}
