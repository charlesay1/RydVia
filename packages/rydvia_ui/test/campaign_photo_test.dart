import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rydvia_ui/rydvia_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all canonical campaign assets are bundled and decode at full resolution',
    () async {
      for (final asset in ['customer', 'driver', 'business', 'ecosystem']) {
        final bytes = await rootBundle.load(
          'packages/rydvia_ui/assets/photography/$asset.webp',
        );
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 1536);
        expect(frame.image.height, 1024);
        frame.image.dispose();
        codec.dispose();
      }
    },
  );
  testWidgets(
    'missing image keeps the photographic frame and decorative semantics quiet',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: RydViaCampaignPhoto(
                asset: 'missing',
                fallbackIcon: Icons.route_outlined,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.route_outlined), findsOneWidget);
      expect(tester.getSize(find.byType(AspectRatio)), const Size(300, 200));
      expect(find.byType(ExcludeSemantics), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
