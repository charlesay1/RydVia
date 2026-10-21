import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rydvia_ui/rydvia_ui.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('development brand slot at large text, dark=$dark', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? RydViaTheme.dark() : RydViaTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              appBar: AppBar(title: const RydViaBrandSlot(product: 'business')),
            ),
          ),
        );
        expect(find.text('DEV'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            'RydVia · business. Development brand placeholder; official artwork pending.',
          ),
          findsOneWidget,
        );
        expect(find.byType(Image), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
