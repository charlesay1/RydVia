import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rydvia_api/rydvia_api.dart';
import 'package:rydvia_core/rydvia_core.dart';
import 'package:rydvia_design_system/rydvia_design_system.dart';
import 'package:rydvia_models/rydvia_models.dart';
import 'package:rydvia_logging/rydvia_logging.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';
import 'secure_session_store.dart';
import 'theme_store.dart';
import 'mobile_app.dart';

Future<void> launchRydVia(ProductRole role) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  try {
    config.validate();
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.publishableKey,
      debug: false,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStore('rydvia.${role.name}.session'),
      ),
    );
    final theme = RydViaThemeController(
      PreferenceThemeStore(await SharedPreferences.getInstance()),
    );
    await theme.restore();
    final client = Supabase.instance.client;
    final auth = AuthController(
      repository: SupabaseAuthRepository(client),
      role: role,
      config: config,
      logger: SafeLogger((event) {
        /* Configure an approved operational sink here. */
      }),
    );
    await auth.initialize();
    runApp(
      RydViaMobileApp(
        role: role,
        theme: theme,
        auth: auth,
        services: SupabaseServicesRepository(client),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        theme: RydViaTheme.light(),
        darkTheme: RydViaTheme.dark(),
        home: const Scaffold(
          body: SafeArea(
            child: Center(
              child: RydViaErrorState(
                message:
                    'RydVia could not start. Check service configuration and connectivity, then restart.',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
