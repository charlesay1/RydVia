import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.g.dart';

@immutable
class RydViaSemanticColors extends ThemeExtension<RydViaSemanticColors> {
  const RydViaSemanticColors({
    required this.success,
    required this.warning,
    required this.focus,
  });

  final Color success;
  final Color warning;
  final Color focus;

  @override
  RydViaSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? focus,
  }) => RydViaSemanticColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    focus: focus ?? this.focus,
  );

  @override
  RydViaSemanticColors lerp(RydViaSemanticColors? other, double t) {
    if (other == null) return this;
    return RydViaSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
    );
  }
}

abstract final class RydViaTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static Duration animationDuration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : RydViaMotion.theme;

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark
        ? RydViaDarkTokens.background
        : RydViaLightTokens.background;
    final surface = dark ? RydViaDarkTokens.surface : RydViaLightTokens.surface;
    final text = dark ? RydViaDarkTokens.text : RydViaLightTokens.text;
    final secondary = dark
        ? RydViaDarkTokens.secondaryText
        : RydViaLightTokens.secondaryText;
    final border = dark ? RydViaDarkTokens.border : RydViaLightTokens.border;
    final focus = dark ? RydViaDarkTokens.focus : RydViaLightTokens.focus;
    final error = dark ? RydViaDarkTokens.error : RydViaLightTokens.error;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: RydViaColors.primaryIndigo,
          brightness: brightness,
        ).copyWith(
          primary: dark ? RydViaDarkTokens.action : RydViaLightTokens.action,
          onPrimary: dark
              ? RydViaDarkTokens.onAction
              : RydViaLightTokens.onAction,
          primaryContainer: RydViaColors.midnightNavy,
          onPrimaryContainer: RydViaColors.warmOffWhite,
          secondary: dark
              ? RydViaColors.warmCoral
              : RydViaColors.accessibleIndigo,
          onSecondary: dark ? RydViaColors.midnightNavy : RydViaColors.white,
          secondaryContainer: RydViaColors.midnightNavy,
          onSecondaryContainer: RydViaColors.warmOffWhite,
          tertiary: dark ? RydViaColors.warmCoral : RydViaColors.midnightNavy,
          onTertiary: dark
              ? RydViaColors.midnightNavy
              : RydViaColors.warmOffWhite,
          tertiaryContainer: RydViaColors.warmCoral,
          onTertiaryContainer: RydViaColors.midnightNavy,
          surface: surface,
          surfaceContainerLowest: background,
          surfaceContainerLow: surface,
          surfaceContainer: surface,
          surfaceContainerHigh: surface,
          surfaceContainerHighest: surface,
          onSurface: text,
          onSurfaceVariant: secondary,
          outline: secondary,
          outlineVariant: border,
          error: error,
          onError: dark ? RydViaColors.midnightNavy : RydViaColors.white,
          errorContainer: RydViaColors.dangerRed,
          onErrorContainer: RydViaColors.white,
          inverseSurface: dark
              ? RydViaColors.warmOffWhite
              : RydViaColors.darkSurface,
          onInverseSurface: dark
              ? RydViaColors.charcoal
              : RydViaColors.warmOffWhite,
          inversePrimary: dark
              ? RydViaColors.accessibleIndigo
              : RydViaColors.warmCoral,
          surfaceTint: Colors.transparent,
        );
    final textTheme = TextTheme(
      displayLarge: RydViaTypography.display,
      displayMedium: RydViaTypography.h1,
      displaySmall: RydViaTypography.h1,
      headlineLarge: RydViaTypography.h1,
      headlineMedium: RydViaTypography.h2,
      headlineSmall: RydViaTypography.h3,
      titleLarge: RydViaTypography.h3,
      titleMedium: RydViaTypography.label,
      titleSmall: RydViaTypography.label,
      bodyLarge: RydViaTypography.body,
      bodyMedium: RydViaTypography.body,
      bodySmall: RydViaTypography.caption,
      labelLarge: RydViaTypography.label,
      labelMedium: RydViaTypography.label,
      labelSmall: RydViaTypography.caption,
    ).apply(bodyColor: text, displayColor: text);
    final inputShape = OutlineInputBorder(
      borderRadius: BorderRadius.circular(RydViaRadius.input),
      borderSide: BorderSide(color: secondary),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Manrope',
      package: 'rydvia_ui',
      fontFamilyFallback: const ['Plus Jakarta Sans', 'Inter'],
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [
        RydViaSemanticColors(
          success: dark ? RydViaDarkTokens.success : RydViaLightTokens.success,
          warning: dark ? RydViaDarkTokens.warning : RydViaLightTokens.warning,
          focus: focus,
        ),
      ],
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: RydViaSpacing.s20,
                vertical: RydViaSpacing.s12,
              ),
              textStyle: RydViaTypography.label,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RydViaRadius.button),
              ),
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? BorderSide(
                        color: dark
                            ? RydViaColors.midnightNavy
                            : RydViaColors.white,
                        width: 3,
                      )
                    : BorderSide.none,
              ),
            ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: textTheme.bodyLarge?.copyWith(color: secondary),
        hintStyle: textTheme.bodyLarge?.copyWith(color: secondary),
        contentPadding: const EdgeInsets.all(RydViaSpacing.s16),
        border: inputShape,
        enabledBorder: inputShape,
        focusedBorder: inputShape.copyWith(
          borderSide: BorderSide(color: focus, width: 2),
        ),
        errorBorder: inputShape.copyWith(borderSide: BorderSide(color: error)),
        focusedErrorBorder: inputShape.copyWith(
          borderSide: BorderSide(color: error, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: RydViaElevation.flat,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border),
          borderRadius: BorderRadius.circular(RydViaRadius.card),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: background,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: background,
              ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RydViaRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RydViaRadius.card),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: RydViaColors.midnightNavy,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? RydViaColors.warmOffWhite
                : secondary,
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          RydViaTypography.caption.copyWith(color: text),
        ),
      ),
    );
  }
}
