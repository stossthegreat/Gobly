import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores runtime app settings like the backend URL.
/// Kept separate from the user profile so dev settings don't pollute
/// the data we send to the agent.
class AppSettingsService extends ChangeNotifier {
  AppSettingsService._();
  static final AppSettingsService _instance = AppSettingsService._();
  static AppSettingsService get instance => _instance;

  static const _backendUrlKey = 'recimo_backend_url_v1';

  /// Compile-time default (overridable with --dart-define=BACKEND_URL=...)
  static const String _compileTimeDefault = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  String _backendUrl = '';
  String get backendUrl => _backendUrl;

  /// True if there's a usable backend URL configured
  bool get hasBackend => _backendUrl.isNotEmpty;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_backendUrlKey);
      if (stored != null && stored.isNotEmpty) {
        _backendUrl = stored;
      } else if (_compileTimeDefault.isNotEmpty) {
        _backendUrl = _compileTimeDefault;
      }
    } catch (_) {
      _backendUrl = '';
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setBackendUrl(String url) async {
    _backendUrl = _normalize(url);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_backendUrl.isEmpty) {
        await prefs.remove(_backendUrlKey);
      } else {
        await prefs.setString(_backendUrlKey, _backendUrl);
      }
    } catch (_) {}
  }

  /// Clean up and validate a URL: trim, add https:// if missing, strip trailing slash
  String _normalize(String url) {
    var cleaned = url.trim();
    if (cleaned.isEmpty) return '';
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }
}
