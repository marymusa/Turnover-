/// Los tres tiempos configurables y dónde se guardan. El ADR-0003 fija qué
/// se guarda en el dispositivo y qué no: los tres tiempos y el nombre del
/// jugador uno, nada más.
library;

import 'package:flutter/foundation.dart';

import 'match_clock.dart';

/// Los tiempos por defecto del glosario: cuatro minutos de turno, quince de
/// reserva y treinta segundos de aviso previo.
const defaultTurn = Duration(minutes: 4);
const defaultReserve = Duration(minutes: 15);
const defaultWarning = Duration(seconds: 30);

/// Dónde se guardan los ajustes, visto desde el dominio. La implementación
/// real toca la plataforma; en los tests se sustituye por una en memoria.
///
/// Guarda segundos y no `Duration` porque lo que hay debajo son valores
/// sueltos, y convertir es cosa de quien los entiende.
abstract interface class SettingsStore {
  /// Nulo si nunca se ha guardado nada bajo esa clave.
  Future<int?> readSeconds(String key);

  Future<void> writeSeconds(String key, int seconds);

  /// Nulo si nunca se ha guardado nada bajo esa clave.
  Future<String?> readText(String key);

  /// Escribir nulo borra la clave, que es lo que distingue no haber guardado
  /// nada de haber guardado la cadena vacía.
  Future<void> writeText(String key, String? text);
}

/// Las claves con las que cada tiempo vive en el almacén. Cambiarlas pierde lo
/// que hubiera guardado, así que se quedan como están.
const _turnKey = 'turn_seconds';
const _reserveKey = 'reserve_seconds';
const _warningKey = 'warning_seconds';

class MatchSettings extends ChangeNotifier {
  MatchSettings(this._store);

  final SettingsStore _store;

  Duration _turn = defaultTurn;
  Duration _reserve = defaultReserve;
  Duration _warning = defaultWarning;

  Duration get turn => _turn;
  Duration get reserve => _reserve;
  Duration get warning => _warning;

  /// Lee lo guardado. Lo que no esté guardado se queda con su valor por
  /// defecto, que es el que ya tiene.
  Future<void> load() async {
    _turn = await _read(_turnKey) ?? _turn;
    _reserve = await _read(_reserveKey) ?? _reserve;
    _warning = await _read(_warningKey) ?? _warning;
    notifyListeners();
  }

  /// Guarda solo los tiempos que se pasan; los demás se quedan como estaban.
  /// Avisa una sola vez al final, para que quien escuche redimensione el
  /// partido de una vez y no una por tiempo.
  Future<void> save({
    Duration? turn,
    Duration? reserve,
    Duration? warning,
  }) async {
    if (turn != null) {
      _turn = turn;
      await _store.writeSeconds(_turnKey, turn.inSeconds);
    }
    if (reserve != null) {
      _reserve = reserve;
      await _store.writeSeconds(_reserveKey, reserve.inSeconds);
    }
    if (warning != null) {
      _warning = warning;
      await _store.writeSeconds(_warningKey, warning.inSeconds);
    }
    notifyListeners();
  }

  Future<Duration?> _read(String key) async {
    final seconds = await _store.readSeconds(key);
    return seconds == null ? null : Duration(seconds: seconds);
  }
}

/// Ata el partido a los ajustes: cada cambio lo redimensiona, que es lo que
/// pide el ticket. Redimensionar no reinicia, y de eso ya se encarga
/// [MatchClock.reconfigure].
///
/// Devuelve con qué soltarse, para que quien ate pueda desatar.
VoidCallback applySettingsTo(MatchClock clock, MatchSettings settings) {
  void apply() => clock.reconfigure(
    turn: settings.turn,
    reserve: settings.reserve,
    warning: settings.warning,
  );

  settings.addListener(apply);
  return () => settings.removeListener(apply);
}
