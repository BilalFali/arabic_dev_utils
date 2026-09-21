import 'package:arabic_dev_utils/src/rtl/arabic_directionality.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('resolves RTL directionality from Arabic basedOn text',
      (tester) async {
    await tester.pumpWidget(
      const ArabicDirectionality(
        basedOn: 'مرحبا',
        child: Text('مرحبا', textDirection: TextDirection.rtl),
      ),
    );

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality),
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('resolves LTR directionality from Latin basedOn text',
      (tester) async {
    await tester.pumpWidget(
      const ArabicDirectionality(
        basedOn: 'hello',
        child: Text('hello', textDirection: TextDirection.ltr),
      ),
    );

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality),
    );
    expect(directionality.textDirection, TextDirection.ltr);
  });

  testWidgets('falls back to LTR for neutral basedOn text', (tester) async {
    await tester.pumpWidget(
      const ArabicDirectionality(
        basedOn: '123',
        child: Text('123', textDirection: TextDirection.ltr),
      ),
    );

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality),
    );
    expect(directionality.textDirection, TextDirection.ltr);
  });

  testWidgets(
      'resolves LTR directionality for mixed text starting with Latin',
      (tester) async {
    await tester.pumpWidget(
      const ArabicDirectionality(
        basedOn: 'hello مرحبا',
        child: Text('hello مرحبا', textDirection: TextDirection.ltr),
      ),
    );

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality),
    );
    expect(directionality.textDirection, TextDirection.ltr);
  });

  testWidgets(
      'resolves RTL directionality for mixed text starting with Arabic',
      (tester) async {
    await tester.pumpWidget(
      const ArabicDirectionality(
        basedOn: 'أحمد يعمل في London',
        child: Text('أحمد يعمل في London', textDirection: TextDirection.rtl),
      ),
    );

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality),
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });
}
