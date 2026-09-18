import 'package:arabic_dev_utils/arabic_dev_utils.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

/// Demo app showing all four arabic_dev_utils modules: text normalization,
/// search, number conversion, and RTL direction.
class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'arabic_dev_utils example',
      home: const HomePage(),
    );
  }
}

/// Home page hosting the four module demos.
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
    const sampleText = 'أَحْمَد يعمل في London 2024';

    return Scaffold(
      appBar: AppBar(title: const Text('arabic_dev_utils example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('1. ArabicText'),
          Text('Input: $sampleText'),
          Text('isArabic: ${ArabicText.isArabic(sampleText)}'),
          Text('isMixed: ${ArabicText.isMixed(sampleText)}'),
          Text('normalize: ${ArabicText.normalize(sampleText)}'),
          Text('wordCount: ${ArabicText.wordCount(sampleText)}'),
          const SizedBox(height: 24),
          _SectionTitle('2. ArabicSearch (live)'),
          ArabicDirectionality(
            basedOn: 'ابحث عن اسم',
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'ابحث عن اسم',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._results.map(
            (name) => ArabicDirectionality(
              basedOn: name,
              child: ListTile(title: Text(name)),
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('3. ArabicNumbers'),
          Text(
            'toArabicDigits("السعر 100 ريال"): '
            '${ArabicNumbers.toArabicDigits("السعر 100 ريال")}',
          ),
          Text(
            'toEnglishDigits("١٢٣"): '
            '${ArabicNumbers.toEnglishDigits("١٢٣")}',
          ),
          Text(
            'format(1234): '
            '${ArabicNumbers.format(1234, locale: 'ar_EG')}',
          ),
          const SizedBox(height: 24),
          _SectionTitle('4. ArabicDirection'),
          Text(
            'dominantDirection("مرحبا hello"): '
            '${ArabicDirection.dominantDirection("مرحبا hello")}',
          ),
          ArabicDirectionality(
            basedOn: sampleText,
            child: Text(sampleText),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
