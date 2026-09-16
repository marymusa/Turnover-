/// Los nombres de los dos jugadores. Son una etiqueta y no tocan ningún
/// reloj: se cambian en cualquier momento, también con el partido empezado.
///
/// La asimetría del ADR-0003 vive aquí entera: el nombre del jugador uno se
/// guarda en el dispositivo y el del dos no, porque el móvil es de uno de los
/// dos y el otro es un oponente diferente cada vez.
library;

import 'package:flutter/foundation.dart';

import 'match_clock.dart';
import 'match_settings.dart';

/// La clave con la que el nombre del jugador uno vive en el almacén.
const _playerOneKey = 'player_one_name';

class PlayerNames extends ChangeNotifier {
  PlayerNames(this._store);

  final SettingsStore _store;

  /// Nulo es no haber puesto nombre, no es el nombre vacío. Quien pinta
  /// resuelve entonces el valor por defecto, que está localizado y por eso no
  /// puede vivir aquí.
  final Map<Player, String?> _names = {Player.one: null, Player.two: null};

  String? nameOf(Player player) => _names[player];

  Future<void> load() async {
    _names[Player.one] = await _store.readText(_playerOneKey);
    notifyListeners();
  }

  /// Un nombre en blanco es volver al valor por defecto: quien borra el campo
  /// entero está pidiendo eso, no un nombre vacío.
  Future<void> rename(Player player, String? name) async {
    final trimmed = name?.trim();
    _names[player] = trimmed == null || trimmed.isEmpty ? null : trimmed;
    if (player == Player.one) {
      await _store.writeText(_playerOneKey, _names[Player.one]);
    }
    notifyListeners();
  }

  /// Lo que le toca a los nombres cuando se reinicia el cronómetro: el del
  /// jugador dos vuelve a su valor por defecto y el del uno se conserva.
  void resetOpponent() {
    _names[Player.two] = null;
    notifyListeners();
  }
}
