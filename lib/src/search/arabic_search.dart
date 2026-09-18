import '../text/arabic_text.dart';

/// Arabic-aware search utilities built on [ArabicText] normalization.
class ArabicSearch {
  ArabicSearch._();

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Returns true if [query] matches somewhere inside [text], ignoring
  /// diacritics, tatweel, alef variants, yeh variants, teh marbuta, and
  /// invisible characters. An empty [query] never matches.
  static bool matches({required String query, required String text}) {
    final normalizedQuery = normalizeForSearch(query);
    if (normalizedQuery.isEmpty) return false;
    return normalizeForSearch(text).contains(normalizedQuery);
  }

  /// Normalizes [text] for search: applies [ArabicText.normalize] with
  /// `normalizeTeh: true`, then strips invisible characters via
  /// [ArabicText.stripInvisibleChars]. This is more aggressive than
  /// [ArabicText.normalize]'s default because search needs to treat teh
  /// marbuta and heh as equivalent, unlike display or linguistic use.
  static String normalizeForSearch(String text) {
    final normalized = ArabicText.normalize(text, normalizeTeh: true);
    return ArabicText.stripInvisibleChars(normalized);
  }

  /// Splits [text] into normalized, non-empty, whitespace-separated tokens.
  static List<String> tokenize(String text) {
    final normalized = normalizeForSearch(text);
    if (normalized.trim().isEmpty) return const [];
    return normalized
        .split(_whitespace)
        .where((token) => token.isNotEmpty)
        .toList();
  }

  /// Sorts [candidates] by match quality against [query]: an exact
  /// normalized match first, then a normalized-prefix match, then a
  /// normalized-contains match. Non-matching candidates are excluded. Ties
  /// preserve the original order of [candidates].
  static List<String> rank(String query, List<String> candidates) {
    final normalizedQuery = normalizeForSearch(query);
    final scored = <(int score, int index, String candidate)>[];

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      final score = _matchScore(normalizedQuery, normalizeForSearch(candidate));
      if (score != null) {
        scored.add((score, i, candidate));
      }
    }

    scored.sort((a, b) {
      final byScore = a.$1.compareTo(b.$1);
      return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
    });

    return scored.map((entry) => entry.$3).toList();
  }

  static int? _matchScore(String normalizedQuery, String normalizedCandidate) {
    if (normalizedQuery.isEmpty) return null;
    if (normalizedCandidate == normalizedQuery) return 0;
    if (normalizedCandidate.startsWith(normalizedQuery)) return 1;
    if (normalizedCandidate.contains(normalizedQuery)) return 2;
    return null;
  }
}
