import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rydvia_auth/rydvia_auth.dart';
import 'package:rydvia_design_system/rydvia_design_system.dart';
import 'package:rydvia_models/rydvia_models.dart';
import 'auth_controller_test.dart' as fakes;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final loader = FontLoader('packages/rydvia_ui/Manrope')
      ..addFont(rootBundle.load('packages/rydvia_ui/fonts/Manrope.ttf'));
    await loader.load();
  });
  for (final role in ProductRole.values) {
    for (final width in [320.0, 390.0, 430.0, 768.0]) {
      testWidgets(
        '$role welcome fits $width at double text scale in dark mode',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = fakes.FakeAuth();
          final auth = fakes.controller(repo, role: role);
          addTearDown(auth.dispose);
          addTearDown(repo.events.close);
          await auth.initialize();
          await tester.pumpWidget(
            MaterialApp(
              theme: RydViaTheme.dark(),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(2)),
                child: Scaffold(
                  body: SafeArea(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: WelcomeScreen(auth: auth),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(find.text('Welcome to RydVia'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'OTP accepts paste and advances automatically; countdown disables resend',
    (tester) async {
      final repo = fakes.FakeAuth();
      final auth = fakes.controller(repo);
      addTearDown(auth.dispose);
      addTearDown(repo.events.close);
      await auth.initialize();
      await auth.sendCode('0241234567');
      await tester.pumpWidget(
        MaterialApp(
          theme: RydViaTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(child: OtpScreen(auth: auth)),
          ),
        ),
      );
      expect(
        tester.widget<TextButton>(find.byType(TextButton).first).onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      expect(repo.verifies, 1);
      expect(auth.stage, AuthStage.onboarding);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
