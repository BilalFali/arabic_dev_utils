import 'package:arabic_dev_utils/src/search/arabic_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArabicSearch.normalizeForSearch', () {
    test('normalizes teh marbuta unlike ArabicText.normalize default', () {
      expect(ArabicSearch.normalizeForSearch('مدرسة'), 'مدرسه');
    });

    test('strips invisible characters', () {
      expect(ArabicSearch.normalizeForSearch('محمد‍علي'), 'محمدعلي');
    });

    test('applies diacritic/alef/yeh normalization', () {
      expect(ArabicSearch.normalizeForSearch('أَحْمَد'), 'احمد');
    });
  });

  group('ArabicSearch.matches', () {
    test('matches despite diacritics', () {
      expect(
        ArabicSearch.matches(query: 'احمد', text: 'أَحْمَد بن علي'),
        isTrue,
      );
    });

    test('matches despite alef variant differences', () {
      expect(
        ArabicSearch.matches(query: 'احمد', text: 'أحمد'),
        isTrue,
      );
    });

    test('matches despite teh marbuta vs heh differences', () {
      expect(
        ArabicSearch.matches(query: 'مدرسه', text: 'مدرسة'),
        isTrue,
      );
    });

    test('does not match unrelated text', () {
      expect(
        ArabicSearch.matches(query: 'محمد', text: 'أحمد بن علي'),
        isFalse,
      );
    });

    test('empty query does not match', () {
      expect(ArabicSearch.matches(query: '', text: 'أحمد'), isFalse);
    });
  });

  group('ArabicSearch.tokenize', () {
    test('splits normalized text into tokens', () {
      expect(
        ArabicSearch.tokenize('أَحْمَد   بن علي'),
        ['احمد', 'بن', 'علي'],
      );
    });

    test('returns empty list for empty string', () {
      expect(ArabicSearch.tokenize(''), <String>[]);
    });
  });

  group('ArabicSearch.rank', () {
    test('exact match ranks before prefix, prefix before contains', () {
      final result = ArabicSearch.rank('احمد', [
        'محمد احمد', // contains
        'احمدي', // prefix
        'احمد', // exact
      ]);
      expect(result, ['احمد', 'احمدي', 'محمد احمد']);
    });

    test('excludes non-matching candidates', () {
      final result = ArabicSearch.rank('احمد', ['علي', 'محمد']);
      expect(result, <String>[]);
    });

    test('ties keep original input order', () {
      final result = ArabicSearch.rank('علي', ['علي أحمد', 'علي محمد']);
      expect(result, ['علي أحمد', 'علي محمد']);
    });

    test('matches are diacritic-insensitive', () {
      final result = ArabicSearch.rank('احمد', ['أَحْمَد']);
      expect(result, ['أَحْمَد']);
    });
  });
}
