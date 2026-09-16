/// El adaptador que guarda los ajustes en el dispositivo. Nada del dominio
/// entra aquí: solo se leen y se escriben enteros bajo una clave.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/match_settings.dart';

class PlatformSettingsStore implements SettingsStore {
  PlatformSettingsStore() : _preferences = SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<int?> readSeconds(String key) => _preferences.getInt(key);

  @override
  Future<void> writeSeconds(String key, int seconds) =>
      _preferences.setInt(key, seconds);
}
