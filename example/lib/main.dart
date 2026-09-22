import 'package:arabic_dev_utils/arabic_dev_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const ExampleApp());

/// Ink-and-gold-leaf palette, grounded in the manuscript tradition the
/// package's subject matter comes from: dark ink ground, warm paper text,
/// a single restrained gold accent reserved for live/interactive elements.
class _Palette {
  const _Palette._();

  static const ink = Color(0xFF14231F);
  static const surface = Color(0xFF1C302A);
  static const gold = Color(0xFFC9A227);
  static const paper = Color(0xFFF3EFE3);
  static const sage = Color(0xFF6E8A82);
}

/// Demo app showing all four arabic_dev_utils modules: text normalization,
/// search, number conversion, and RTL direction.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return MaterialApp(
      title: 'Arabic Dev Utils',
      theme: base.copyWith(
        scaffoldBackgroundColor: _Palette.ink,
        colorScheme: base.colorScheme.copyWith(
          surface: _Palette.ink,
          primary: _Palette.gold,
          onSurface: _Palette.paper,
          secondary: _Palette.sage,
        ),
        textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
          bodyColor: _Palette.paper,
          displayColor: _Palette.paper,
        ),
        dividerColor: _Palette.sage.withValues(alpha: 0.18),
      ),
      home: const HomePage(),
    );
  }
}

/// Home page hosting the four module demos: a live search hero up top,
/// then Text, Numbers, and Direction as a quiet reference list below.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _names = [
    'أحمد محمد',
    'إسراء علي',
    'محمد أحمد',
    'فاطمة الزهراء',
    'يوسف إبراهيم',
    'مريم حسن',
  ];

  static const _sampleText = 'أَحْمَد يعمل في London 2024';
  static const _priceText = 'السعر 100 ريال';

  final _searchController = TextEditingController();
  List<String> _results = _names;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _searchController.text;
    setState(() {
      _results = query.isEmpty ? _names : ArabicSearch.rank(query, _names);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _Header(),
              const SizedBox(height: 28),
              _SearchHero(
                controller: _searchController,
                results: _results,
              ),
              const SizedBox(height: 32),
              _ReferenceSection(
                label: 'Text',
                description:
                    'Normalizes diacritics, alef/yeh variants, and '
                    'invisible characters that break equality checks.',
                children: [
                  _TransformRow(
                    before: _sampleText,
                    after: ArabicText.normalize(_sampleText),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag(
                        'Arabic script',
                        active: ArabicText.isArabic(_sampleText),
                      ),
                      _Tag(
                        'Mixed script',
                        active: ArabicText.isMixed(_sampleText),
                      ),
                      _Tag(
                        '${ArabicText.wordCount(_sampleText)} words',
                        active: true,
                      ),
                    ],
                  ),
                ],
              ),
              _ReferenceSection(
                label: 'Numbers',
                description:
                    'Converts between digit systems and wraps intl for '
                    'locale-aware formatting.',
                children: [
                  _TransformRow(
                    before: _priceText,
                    after: ArabicNumbers.toArabicDigits(_priceText),
                  ),
                  const SizedBox(height: 12),
                  _TransformRow(
                    before: '1234',
                    after: ArabicNumbers.format(1234, locale: 'ar_EG'),
                    caption: "format(1234, locale: 'ar_EG')",
                  ),
                ],
              ),
              _ReferenceSection(
                label: 'Direction',
                description:
                    'Detects RTL, LTR, and mixed text, and sets widget '
                    'directionality automatically.',
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      _Tag(
                        ArabicDirection.dominantDirection(_sampleText).name,
                        active: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _Palette.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _Palette.sage.withValues(alpha: 0.35),
                      ),
                    ),
                    child: ArabicDirectionality(
                      basedOn: _sampleText,
                      child: const Text(
                        _sampleText,
                        style: TextStyle(color: _Palette.paper, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              _ReferenceSection(
                label: 'Hijri calendar',
                description:
                    'Converts between Gregorian and the tabular '
                    '(civil-epoch) Hijri calendar — a computed calendar, '
                    'not a moon-sighting one.',
                children: [
                  _TransformRow(
                    before: '2024-03-20',
                    after: HijriDate.fromGregorian(
                      DateTime(2024, 3, 20),
                    ).toString(),
                    caption: 'HijriDate.fromGregorian(DateTime(2024, 3, 20))',
                  ),
                  const SizedBox(height: 12),
                  _TransformRow(
                    before: '1445-09-10',
                    after: HijriDate(
                      1445,
                      9,
                      10,
                    ).toGregorian().toIso8601String().split('T').first,
                    caption: 'HijriDate(1445, 9, 10).toGregorian()',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Package version 0.1.0',
                  style: TextStyle(
                    color: _Palette.sage.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bilingual title lockup and one-line pitch.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Arabic Dev Utils',
                style: TextStyle(
                  color: _Palette.gold,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'عربي',
                style: TextStyle(
                  color: _Palette.paper,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A toolkit for Arabic text, search, numbers, and RTL '
            'in Flutter and Dart.',
            style: TextStyle(
              color: _Palette.sage,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// The live search demo — the package's most characteristic interaction,
/// so it leads the page.
class _SearchHero extends StatelessWidget {
  const _SearchHero({required this.controller, required this.results});

  final TextEditingController controller;
  final List<String> results;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: _Palette.gold, width: 2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search',
              style: TextStyle(
                color: _Palette.paper,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Matching ignores diacritics and script variants — '
              'try typing without them.',
              style: TextStyle(color: _Palette.sage, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            ArabicDirectionality(
              basedOn: 'ابحث عن اسم',
              child: TextField(
                controller: controller,
                style: const TextStyle(color: _Palette.paper, fontSize: 17),
                cursorColor: _Palette.gold,
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم',
                  hintStyle: TextStyle(
                    color: _Palette.sage.withValues(alpha: 0.7),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: _Palette.sage.withValues(alpha: 0.35),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: _Palette.gold, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'No names match that search.',
                  style: TextStyle(color: _Palette.sage, fontSize: 14),
                ),
              )
            else
              ...results.asMap().entries.map((entry) {
                final isLast = entry.key == results.length - 1;
                return ArabicDirectionality(
                  basedOn: entry.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: _Palette.sage.withValues(alpha: 0.18),
                              ),
                            ),
                    ),
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: _Palette.paper,
                        fontSize: 17,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// A labeled reference block: a section title, one-line description, and
/// whatever demo content it owns. Differentiated by content, not by a
/// repeated card shell.
class _ReferenceSection extends StatelessWidget {
  const _ReferenceSection({
    required this.label,
    required this.description,
    required this.children,
  });

  final String label;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Container(
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: _Palette.sage.withValues(alpha: 0.4)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _Palette.paper,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(color: _Palette.sage, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Shows a before/after transformation with a gold arrow between them —
/// the actual thing each module does, not a description of it.
class _TransformRow extends StatelessWidget {
  const _TransformRow({
    required this.before,
    required this.after,
    this.caption,
  });

  final String before;
  final String after;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (caption != null) ...[
          Text(
            caption!,
            style: TextStyle(color: _Palette.sage, fontSize: 12),
          ),
          const SizedBox(height: 4),
        ],
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            ArabicDirectionality(
              basedOn: before,
              child: Text(
                before,
                style: TextStyle(
                  color: _Palette.paper.withValues(alpha: 0.6),
                  fontSize: 15,
                ),
              ),
            ),
            const Text(
              '→',
              style: TextStyle(
                color: _Palette.gold,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            ArabicDirectionality(
              basedOn: after,
              child: Text(
                after,
                style: const TextStyle(
                  color: _Palette.paper,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A small state pill — gold when true, dim outline when false. Reads at
/// a glance without spelling out "true"/"false".
class _Tag extends StatelessWidget {
  const _Tag(this.label, {required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? _Palette.gold : _Palette.sage.withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? _Palette.gold : _Palette.sage,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
