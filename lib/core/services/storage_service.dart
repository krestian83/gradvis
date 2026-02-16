import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences].
class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);
}
