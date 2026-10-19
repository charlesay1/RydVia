import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rydvia_ui/rydvia_ui.dart';

const services = [
  RydViaService(id: 'ride', label: 'Ride', group: RydViaServiceGroup.ride),
  RydViaService(
    id: 'deliver',
    label: 'Deliver',
    group: RydViaServiceGroup.deliver,
  ),
  RydViaService(id: 'move', label: 'Move', group: RydViaServiceGroup.move),
];

Widget host(Widget child, {bool dark = false, double scale = 1}) => MaterialApp(
  theme: RydViaTheme.light(),
  darkTheme: RydViaTheme.dark(),
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  ),
);

void main() {
  test(
    'missing flags fail closed, snapshots cannot be mutated, IDs are unique',
    () {
      final flags = {'ride': true};
      final catalog = RydViaServiceCatalog(
        services: services,
        availability: flags,
      );
      flags['move'] = true;
      expect(catalog.enabled.map((s) => s.id), ['ride']);
      expect(() => catalog.availability['move'] = true, throwsUnsupportedError);
      expect(
        () => RydViaServiceCatalog(
          services: [services.first, services.first],
          availability: {},
        ),
        throwsArgumentError,
      );
    },
  );

  testWidgets('disabled services disappear and remaining tiles reflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? chosen;
    Widget grid(Map<String, bool> flags) => host(
      RydViaServiceGrid(
        catalog: RydViaServiceCatalog(services: services, availability: flags),
        onSelected: (service) => chosen = service.id,
      ),
    );
    await tester.pumpWidget(
      grid({'ride': true, 'deliver': true, 'move': true}),
    );
    final previousPosition = tester.getTopLeft(
      find.byKey(const ValueKey('deliver')),
    );
    await tester.pumpWidget(
      grid({'ride': false, 'deliver': true, 'move': true}),
    );
    expect(find.text('Ride'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('deliver'))).dx,
      lessThan(previousPosition.dx),
    );
    await tester.tap(find.text('Deliver'));
    expect(chosen, 'deliver');
    await tester.pumpWidget(grid({}));
    expect(find.text('Services are unavailable'), findsOneWidget);
  });

  for (final width in [320.0, 768.0, 1280.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'components fit width $width, dark=$dark, double text scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            host(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RydViaServiceGrid(
                    catalog: RydViaServiceCatalog(
                      services: services,
                      availability: {
                        'ride': true,
                        'deliver': true,
                        'move': true,
                      },
                    ),
                    onSelected: (_) {},
                  ),
                  RydViaVehicleCard(
                    name: 'Comfort',
                    eta: '3 min',
                    capacity: '4 seats',
                    price: 'GHS 120.00',
                    description: 'Comfortable everyday travel',
                    selected: true,
                    onPressed: () {},
                  ),
                  const RydViaTextField(label: 'Pickup'),
                  RydViaSearchField(label: 'Destination', onChanged: (_) {}),
                  RydViaButton(label: 'Confirm booking', onPressed: () {}),
                  const RydViaDriverCard(
                    name: 'Alex',
                    vehicle: 'Sedan',
                    registration: 'RV 100',
                    rating: '4.9',
                  ),
                  const RydViaTripCard(
                    pickup: 'Airport',
                    destination: 'Office',
                    status: 'Scheduled',
                    formattedPrice: 'GHS 120.00',
                  ),
                ],
              ),
              dark: dark,
              scale: 2,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('loading disables confirmation and errors offer retry', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        Column(
          children: [
            RydViaButton(
              label: 'Confirm',
              loading: true,
              onPressed: () => taps++,
            ),
            RydViaErrorState(
              message: 'Unable to load services',
              onRetry: () => taps++,
            ),
          ],
        ),
      ),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Try again'));
    expect(taps, 1);
    expect(find.text('Unable to load services'), findsOneWidget);
  });

  testWidgets('reduced motion renders a static loading indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Column(
            children: [
              const RydViaLoadingState(),
              RydViaButton(label: 'Confirm', loading: true, onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Loading'), findsOneWidget);
  });

  testWidgets('service controls have labels, tap targets, and text contrast', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        RydViaServiceGrid(
          catalog: RydViaServiceCatalog(
            services: services,
            availability: {'ride': true},
          ),
          onSelected: (_) {},
        ),
      ),
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
