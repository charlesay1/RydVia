import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rydvia_auth/rydvia_auth.dart';
import 'package:rydvia_api/rydvia_api.dart';
import 'package:rydvia_design_system/rydvia_design_system.dart';
import 'package:rydvia_models/rydvia_models.dart';
import 'auth_controller_test.dart' as fakes;

class MemoryTheme implements RydViaThemeStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    value = next;
  }
}

class EmptyServices implements ServicesRepository {
  @override
  Future<List<ServiceAvailability>> fetchServices() async => [];
}

void main() {
  testWidgets(
    'restored session opens customer home, logout gates access, legal routes work',
    (tester) async {
      final repo = fakes.FakeAuth()..active = true;
      repo.profile = AccessProfile(
        userId: 'test-user',
        roles: ['customer'],
        onboarded: true,
      );
      final auth = fakes.controller(repo);
      await auth.initialize();
      final theme = RydViaThemeController(MemoryTheme());
      await theme.restore();
      await tester.pumpWidget(
        RydViaMobileApp(
          role: ProductRole.customer,
          theme: theme,
          auth: auth,
          services: EmptyServices(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Services are unavailable'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to RydVia'), findsOneWidget);
      expect(find.text('Services are unavailable'), findsNothing);
      final terms = find.widgetWithText(TextButton, 'Terms & Conditions');
      await tester.ensureVisible(terms);
      await tester.tap(terms);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Final legal text has not been supplied'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Welcome to RydVia'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await repo.events.close();
    },
  );
}
