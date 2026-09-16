import 'package:turnover/domain/match_settings.dart';

/// El almacén de los tests: lo mismo que el del dispositivo, pero en memoria
/// y sin cruzar a la plataforma.
class MemorySettingsStore implements SettingsStore {
  final Map<String, int> _numbers = {};
  final Map<String, String> _texts = {};

  @override
  Future<int?> readSeconds(String key) async => _numbers[key];

  @override
  Future<void> writeSeconds(String key, int seconds) async {
    _numbers[key] = seconds;
  }

  @override
  Future<String?> readText(String key) async => _texts[key];

  @override
  Future<void> writeText(String key, String? text) async {
    if (text == null) {
      _texts.remove(key);
      return;
    }
    _texts[key] = text;
  }
}
