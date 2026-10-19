import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rydvia_ui/rydvia_ui.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

class MemoryStore implements RydViaThemeStore {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String next) async {
    if (fail) throw StateError('Storage unavailable');
    value = next;
  }
}

void main() {
  test('official brand palette stays locked', () {
    expect(RydViaColors.primaryIndigo, const Color(0xFF4C6BFF));
    expect(RydViaColors.midnightNavy, const Color(0xFF0F1B3D));
    expect(RydViaColors.violetBlue, const Color(0xFF6366F1));
    expect(RydViaColors.warmCoral, const Color(0xFFFF8A6B));
    expect(RydViaColors.charcoal, const Color(0xFF1F2937));
    expect(RydViaColors.warmOffWhite, const Color(0xFFFAF7F2));
  });

  for (final brightness in Brightness.values) {
    test('$brightness theme provides readable text and semantic colors', () {
      final theme = brightness == Brightness.dark
          ? RydViaTheme.dark()
          : RydViaTheme.light();
      final scheme = theme.colorScheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, brightness);
      expect(
        theme.textTheme.bodyLarge!.fontFamily,
        'packages/rydvia_ui/Manrope',
      );
      for (final pair in [
        [scheme.onSurface, scheme.surface],
        [scheme.onSurfaceVariant, scheme.surface],
        [scheme.onSurface, theme.scaffoldBackgroundColor],
        [scheme.onSurfaceVariant, theme.scaffoldBackgroundColor],
        [scheme.onPrimary, scheme.primary],
        [scheme.primary, scheme.surface],
        [scheme.onSecondary, scheme.secondary],
        [scheme.onTertiary, scheme.tertiary],
        [scheme.onError, scheme.error],
        [scheme.onErrorContainer, scheme.errorContainer],
      ]) {
        expect(contrast(pair[0], pair[1]), greaterThanOrEqualTo(4.5));
      }
      final semantic = theme.extension<RydViaSemanticColors>()!;
      expect(
        contrast(semantic.success, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(semantic.warning, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(semantic.focus, scheme.surface), greaterThanOrEqualTo(3));
    });
  }

  test(
    'system defaults, invalid preferences, overrides and restart persistence',
    () async {
      final store = MemoryStore()..value = 'invalid';
      final controller = RydViaThemeController(store);
      addTearDown(controller.dispose);
      expect(controller.mode, ThemeMode.system);
      await controller.restore();
      expect(controller.mode, ThemeMode.system);
      for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
        await controller.setMode(mode);
        final restarted = RydViaThemeController(store);
        await restarted.restore();
        expect(restarted.mode, mode);
        restarted.dispose();
      }
    },
  );

  test('failed persistence keeps the current mode and allows retry', () async {
    final store = MemoryStore();
    final controller = RydViaThemeController(store);
    addTearDown(controller.dispose);
    await controller.restore();
    store.fail = true;
    await expectLater(controller.setMode(ThemeMode.dark), throwsStateError);
    expect(controller.mode, ThemeMode.system);
    store.fail = false;
    await controller.setMode(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);
  });

  testWidgets(
    'system follows device brightness and override persists across brightness changes',
    (tester) async {
      final store = MemoryStore();
      final controller = RydViaThemeController(store);
      addTearDown(controller.dispose);
      await controller.restore();
      final dispatcher = tester.binding.platformDispatcher;
      addTearDown(dispatcher.clearPlatformBrightnessTestValue);
      dispatcher.platformBrightnessTestValue = Brightness.light;
      Brightness? actual;
      await tester.pumpWidget(
        ListenableBuilder(
          listenable: controller,
          builder: (context, child) => MaterialApp(
            theme: RydViaTheme.light(),
            darkTheme: RydViaTheme.dark(),
            themeMode: controller.mode,
            home: Builder(
              builder: (context) {
                actual = Theme.of(context).brightness;
                return const Scaffold(body: Text('RydVia'));
              },
            ),
          ),
        ),
      );
      expect(actual, Brightness.light);
      dispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(actual, Brightness.dark);
      await controller.setMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(actual, Brightness.light);
      dispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      dispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(actual, Brightness.light);
    },
  );

  testWidgets('theme duration respects reduced motion', (tester) async {
    Duration? duration;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              duration = RydViaTheme.animationDuration(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(duration, Duration.zero);
  });
}
