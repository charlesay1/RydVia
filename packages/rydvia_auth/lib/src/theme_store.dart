import 'package:shared_preferences/shared_preferences.dart';
import 'package:rydvia_core/rydvia_core.dart';
import 'package:rydvia_design_system/rydvia_design_system.dart';

class PreferenceThemeStore implements RydViaThemeStore {
  const PreferenceThemeStore(this.preferences);
  final SharedPreferences preferences;
  @override
  Future<String?> read() async => preferences.getString('rydvia.theme');
  @override
  Future<void> write(String value) async {
    if (!await preferences.setString('rydvia.theme', value)) {
      throw const AppFailure(
        'settings',
        'Theme preference could not be saved.',
      );
    }
  }
}
