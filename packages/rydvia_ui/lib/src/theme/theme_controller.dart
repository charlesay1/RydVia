import 'package:flutter/material.dart';

/// Implement with the host app's existing persistent settings store.
abstract interface class RydViaThemeStore {
  Future<String?> read();
  Future<void> write(String value);
}

/// Restore before runApp to avoid an initial flash in the wrong theme.
/// Persistence failures propagate; callers should show a retry message.
class RydViaThemeController extends ChangeNotifier {
  RydViaThemeController(this.store);

  final RydViaThemeStore store;
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  bool _restored = false;
  bool _busy = false;
  bool get restored => _restored;

  Future<void> restore() async {
    if (_busy || _restored)
      throw StateError('Restore once before changing theme.');
    _busy = true;
    try {
      final value = await store.read();
      _mode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      _restored = true;
      notifyListeners();
    } finally {
      _busy = false;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (!_restored || _busy)
      throw StateError('Theme preferences are not ready.');
    if (mode == _mode) return;
    _busy = true;
    try {
      await store.write(mode.name);
      _mode = mode;
      notifyListeners();
    } finally {
      _busy = false;
    }
  }
}
