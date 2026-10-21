import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rydvia_api/rydvia_api.dart';
import 'package:rydvia_design_system/rydvia_design_system.dart';
import 'package:rydvia_models/rydvia_models.dart';
import 'auth_controller.dart';
import 'ui/welcome_screen.dart';
import 'ui/otp_screen.dart';
import 'ui/onboarding_screen.dart';
import 'ui/home_screen.dart';
import 'ui/legal_screen.dart';

class RydViaMobileApp extends StatefulWidget {
  const RydViaMobileApp({
    super.key,
    required this.role,
    required this.theme,
    required this.auth,
    required this.services,
  });
  final ProductRole role;
  final RydViaThemeController theme;
  final AuthController auth;
  final ServicesRepository services;
  @override
  State<RydViaMobileApp> createState() => _RydViaMobileAppState();
}

class _RydViaMobileAppState extends State<RydViaMobileApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      unawaited(widget.auth.refreshAccess());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.auth.dispose();
    widget.theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.theme,
    builder: (context, child) => MaterialApp(
      title: 'RydVia ${widget.role.name}',
      debugShowCheckedModeBanner: false,
      theme: RydViaTheme.light(),
      darkTheme: RydViaTheme.dark(),
      themeMode: widget.theme.mode,
      themeAnimationDuration:
          WidgetsBinding
              .instance
              .platformDispatcher
              .accessibilityFeatures
              .disableAnimations
          ? Duration.zero
          : RydViaMotion.theme,
      routes: {
        '/terms': (_) => const LegalScreen(title: 'Terms & Conditions'),
        '/privacy': (_) => const LegalScreen(title: 'Privacy Policy'),
      },
      home: ListenableBuilder(
        listenable: widget.auth,
        builder: (context, child) => PopScope(
          canPop: widget.auth.stage != AuthStage.code,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && widget.auth.stage == AuthStage.code)
              widget.auth.editPhone();
          },
          child: Scaffold(
            appBar: AppBar(
              title: RydViaBrandSlot(product: widget.role.name),
              actions: [
                PopupMenuButton<ThemeMode>(
                  tooltip: 'Appearance',
                  initialValue: widget.theme.mode,
                  icon: const Icon(Icons.contrast_outlined),
                  onSelected: (mode) async {
                    try {
                      await widget.theme.setMode(mode);
                    } catch (_) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Appearance could not be saved. Try again.',
                            ),
                          ),
                        );
                    }
                  },
                  itemBuilder: (_) => ThemeMode.values
                      .map(
                        (mode) =>
                            PopupMenuItem(value: mode, child: Text(mode.name)),
                      )
                      .toList(),
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(RydViaSpacing.s20),
                    child: _stage(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _stage() {
    final auth = widget.auth;
    return switch (auth.stage) {
      AuthStage.welcome => WelcomeScreen(auth: auth),
      AuthStage.code => OtpScreen(auth: auth),
      AuthStage.checking =>
        auth.message != null
            ? RydViaErrorState(
                message: auth.message!,
                onRetry: auth.busy ? null : auth.refreshAccess,
              )
            : const RydViaLoadingState(label: 'Restoring your session'),
      AuthStage.onboarding => OnboardingScreen(auth: auth),
      AuthStage.pendingApproval => Column(
        children: [
          const RydViaEmptyState(
            title: 'Approval required',
            message:
                'This account does not yet have access to this product. Submit your profile for review; access is granted by the RydVia team.',
          ),
          if (auth.message != null) Text(auth.message!),
          TextButton(
            onPressed: auth.busy ? null : auth.editProfile,
            child: const Text('Update profile / request review'),
          ),
          TextButton(
            onPressed: auth.busy ? null : auth.refreshAccess,
            child: const Text('Check approval status'),
          ),
          TextButton(
            onPressed: auth.busy ? null : auth.signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
      AuthStage.ready => HomeScreen(
        role: widget.role,
        services: widget.services,
        auth: auth,
      ),
    };
  }
}
