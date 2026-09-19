/// La cuenta de turnos y las partes. Dart puro: no importa `flutter/` y no
/// mide tiempo, que es cosa de [MatchClock]. Lo único que lo mueve son las
/// acciones de la mesa: pasar turno, declarar un Time-Out y corregir a mano.
library;

import 'match_clock.dart' show Player;

/// Un número por jugador, de 1 a 16. La numeración es corrida: la primera
/// parte va de 1 a 8 y la segunda de 9 a 16, y así la parte se lee en el
/// propio número sin ningún indicador aparte (ADR-0010).
class TurnCount {
  /// Los turnos de tablero que dura una parte. No se configura: es la regla
  /// (ADR-0008).
  static const turnsPerHalf = 8;

  /// Las partes que dura un partido. La prórroga queda fuera (ADR-0008).
  static const halves = 2;

  /// Los turnos de tablero desde los que un Time-Out hace retroceder en vez de
  /// avanzar. Van enumerados y no como un umbral porque así los escribe el
  /// reglamento.
  static const _retreatingTurns = {6, 7, 8};

  final Map<Player, int> _shown = {Player.one: 1, Player.two: 1};

  Player? _active;
  int _half = 1;

  /// Quién juega primero en la parte en curso. Dice quién es el segundo, que
  /// es con quien termina la parte.
  Player? _firstOfHalf;

  /// Si el segundo jugador de la parte ya ha entrado. Estrena su número en vez
  /// de incrementarlo, y por eso los dos van desfasados: el segundo llega a
  /// cada número cuando el primero ya ha pasado. Va aparte del número porque
  /// un Time-Out puede moverlo antes de que nadie pase (ADR-0010).
  bool _hasSecondEntered = false;

  /// Nulo antes de empezar, igual que en [MatchClock].
  Player? get activePlayer => _active;

  int get half => _half;

  /// El número de cara al jugador, que es el que se muestra.
  int of(Player player) => _shown[player]!;

  /// El turno que está en la mesa, de 1 a 8, que es el que leen las reglas.
  /// El mostrado 9 es el tablero 1 y el 16 el tablero 8 (ADR-0010).
  int boardTurnOf(Player player) => ((of(player) - 1) % turnsPerHalf) + 1;

  /// El toque inicial: empieza el jugador que recibe la patada inicial.
  void start(Player receiver) {
    if (_active != null) return;
    _active = receiver;
    _firstOfHalf = receiver;
  }

  /// Pasa el turno al otro jugador, incrementando su número salvo la primera
  /// vez de cada parte. Cuando el segundo jugador pasa su turno 8 de tablero
  /// la parte termina, y la siguiente empieza en el 9 pase lo que pase en la
  /// anterior: la invierten las reglas, así que quien recibió en la primera
  /// patea y juega segundo (ADR-0008).
  void passTurn() {
    final active = _active;
    if (active == null) return;

    if (_endsHalf(active)) {
      // Con la segunda parte no hay siguiente: el partido termina ahí y la
      // cuenta se queda en el 16. El acta que lo cierra es de otro ticket.
      if (_half < halves) _startNextHalf();
      return;
    }

    final entering = _opponentOf(active);
    // La primera vez de cada parte el segundo estrena su número igualando al
    // primero en vez de incrementar el suyo: así quedan desfasados, y una
    // corrección a mano hecha antes de ese pase no se pierde.
    _shown[entering] = _hasSecondEntered ? of(entering) + 1 : of(active);
    _hasSecondEntered = true;
    _active = entering;
  }

  /// La parte termina cuando el segundo jugador de la parte, que es el rival
  /// de quien la empezó, pasa su turno 8 de tablero.
  bool _endsHalf(Player active) =>
      active != _firstOfHalf && boardTurnOf(active) == turnsPerHalf;

  /// La siguiente parte empieza en el 9 pase lo que pase en la anterior, y la
  /// invierten las reglas: quien recibió en la primera patea y juega segundo
  /// (ADR-0008).
  void _startNextHalf() {
    _half += 1;
    final start = (_half - 1) * turnsPerHalf + 1;
    for (final player in Player.values) {
      _shown[player] = start;
    }
    final firstOfNextHalf = _opponentOf(_firstOfHalf!);
    _firstOfHalf = firstOfNextHalf;
    _hasSecondEntered = false;
    _active = firstOfNextHalf;
  }

  /// Un Time-Out declarado por los jugadores: la aplicación no conoce la
  /// tirada, la recoge (ADR-0010). Lee la ficha del equipo pateador, que es el
  /// jugador inactivo, y si su turno de tablero es 6, 7 u 8 ambos retroceden
  /// un espacio; en cualquier otro caso ambos avanzan uno. Sin topes: una
  /// parte puede durar siete turnos o nueve, como en la mesa.
  void timeOut() {
    final active = _active;
    if (active == null) return;

    final kicker = _opponentOf(active);
    final step = _retreatingTurns.contains(boardTurnOf(kicker)) ? -1 : 1;
    for (final player in Player.values) {
      _shown[player] = of(player) + step;
    }
  }

  /// La corrección a mano, que es la salida para lo que la aplicación no ve,
  /// como un turno que nadie pasó (ADR-0008).
  void adjust(Player player, int delta) {
    _shown[player] = of(player) + delta;
  }

  /// Devuelve la cuenta y la parte a su estado inicial.
  void reset() {
    for (final player in Player.values) {
      _shown[player] = 1;
    }
    _half = 1;
    _firstOfHalf = null;
    _hasSecondEntered = false;
    _active = null;
  }

  static Player _opponentOf(Player player) =>
      player == Player.one ? Player.two : Player.one;
}
