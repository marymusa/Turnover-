/// Reglas del cronómetro. Dart puro: no importa `flutter/` y no genera tiempo
/// por su cuenta, lo recibe en [MatchClock.advance].
library;

enum Player { one, two }

/// Cuál de los dos relojes del jugador activo está corriendo.
enum ClockKind { turn, reserve }

/// Pasar a segundo plano lleva a [paused], que es el mismo estado que produce
/// el botón y no uno nuevo (ADR-0001).
enum MatchState { notStarted, running, paused }

/// Las tres bocinas del glosario, de menor a mayor intensidad, y el aviso
/// previo de reserva. La vibración que le corresponde a cada una la decide
/// quien escucha, no este módulo.
enum Horn { turnWarning, turnExpired, reserveWarning, reserveExpired }

/// Aquello de lo que el cronómetro deja constancia: una bocina y de quién es.
class MatchEvent {
  const MatchEvent(this.horn, this.player);

  final Horn horn;
  final Player player;

  @override
  bool operator ==(Object other) =>
      other is MatchEvent && other.horn == horn && other.player == player;

  @override
  int get hashCode => Object.hash(horn, player);

  @override
  String toString() => '$horn($player)';
}

class MatchClock {
  MatchClock({
    required Duration turn,
    required Duration reserve,
    required this._warning,
  }) : _turn = turn,
       _reserve = reserve,
       _turnClock = {Player.one: turn, Player.two: turn},
       _reserveClock = {Player.one: reserve, Player.two: reserve};

  Duration _turn;
  Duration _reserve;
  Duration _warning;

  final Map<Player, Duration> _turnClock;
  final Map<Player, Duration> _reserveClock;

  /// Los eventos ya emitidos del jugador activo, para no repetirlos. El turno
  /// se olvida al pasar turno; la reserva dura todo el partido.
  final Set<Horn> _emittedThisTurn = {};
  final Map<Player, Set<Horn>> _emittedThisMatch = {
    Player.one: {},
    Player.two: {},
  };

  Player? _active;
  MatchState _state = MatchState.notStarted;

  MatchState get state => _state;

  /// Nulo antes de empezar. Al pausar sigue siendo el mismo: pausado no cambia
  /// de quién es el turno.
  Player? get activePlayer => _active;

  Duration get warning => _warning;

  /// Nulo si no corre ninguno, sea porque el partido no ha empezado o porque
  /// está pausado. En overtime sigue corriendo la reserva.
  ClockKind? get runningClock {
    final active = _active;
    if (active == null || _state != MatchState.running) return null;
    return _turnClock[active]! > Duration.zero
        ? ClockKind.turn
        : ClockKind.reserve;
  }

  /// El toque inicial: elige quién recibe la patada inicial y arranca. Solo
  /// hace algo con el partido sin empezar, porque después de empezar cualquier
  /// toque pasa turno y reanudar es cosa de [resume].
  void start(Player receiver) {
    if (_state != MatchState.notStarted) return;
    _active = receiver;
    _state = MatchState.running;
  }

  void pause() {
    if (_state == MatchState.running) _state = MatchState.paused;
  }

  void resume() {
    if (_state == MatchState.paused) _state = MatchState.running;
  }

  /// Consume [elapsed] del jugador activo: primero el turno y, en cuanto se
  /// agota, la reserva. Un solo avance puede atravesar las dos cosas, y por eso
  /// puede devolver más de un evento.
  List<MatchEvent> advance(Duration elapsed) {
    final active = _active;
    if (active == null || _state != MatchState.running) return const [];

    var remaining = elapsed;
    final turnClock = _turnClock[active]!;
    if (turnClock > Duration.zero) {
      if (turnClock > remaining) {
        _turnClock[active] = turnClock - remaining;
        return _eventsFor(active);
      }
      _turnClock[active] = Duration.zero;
      remaining -= turnClock;
    }

    _reserveClock[active] = _reserveClock[active]! - remaining;
    return _eventsFor(active);
  }

  /// Los eventos que corresponden al estado actual de los relojes y que no se
  /// hayan emitido ya.
  List<MatchEvent> _eventsFor(Player active) {
    final events = <MatchEvent>[];

    /// Emite una sola vez mientras se cumpla el umbral. Si deja de cumplirse,
    /// porque reconfigurar ha ampliado el reloj, el evento se olvida y vuelve
    /// a llegar cuando el reloj baje otra vez.
    void at(bool reached, Horn horn, Set<Horn> emitted) {
      if (!reached) {
        emitted.remove(horn);
        return;
      }
      if (emitted.add(horn)) events.add(MatchEvent(horn, active));
    }

    final turnClock = _turnClock[active]!;
    final reserveClock = _reserveClock[active]!;

    final thisMatch = _emittedThisMatch[active]!;
    at(turnClock <= _warning, Horn.turnWarning, _emittedThisTurn);
    at(turnClock <= Duration.zero, Horn.turnExpired, _emittedThisTurn);
    at(reserveClock <= _warning, Horn.reserveWarning, thisMatch);
    at(reserveClock <= Duration.zero, Horn.reserveExpired, thisMatch);

    return events;
  }

  /// La única acción del jugador activo. Funciona también con la reserva
  /// consumiéndose: lo único que lo impide es que esté pausado.
  void passTurn() {
    final active = _active;
    if (active == null || _state != MatchState.running) return;
    _turnClock[active] = _turn;
    _emittedThisTurn.clear();
    _active = active == Player.one ? Player.two : Player.one;
  }

  /// Redimensiona, no reinicia: lo gastado se conserva. Ampliar la reserva de
  /// quince a veinte con seis gastados deja catorce. Lo que no se pasa se
  /// queda como estaba.
  void reconfigure({Duration? turn, Duration? reserve, Duration? warning}) {
    if (turn != null) {
      _resize(_turnClock, from: _turn, to: turn, keepSpent: true);
      _turn = turn;
    }
    if (reserve != null) {
      _resize(_reserveClock, from: _reserve, to: reserve, keepSpent: false);
      _reserve = reserve;
    }
    if (warning != null) _warning = warning;
  }

  /// Conserva lo gastado sumando la diferencia.
  ///
  /// Con [keepSpent], un reloj ya agotado se queda agotado: ampliar el turno a
  /// media partida no le devuelve turno a quien ya está consumiendo reserva,
  /// que es la única forma de que el turno no resucite. La reserva no lleva esa
  /// salvedad, porque el overtime es una magnitud y no un final: ampliarla saca
  /// del overtime a quien estuviera dentro.
  void _resize(
    Map<Player, Duration> clocks, {
    required Duration from,
    required Duration to,
    required bool keepSpent,
  }) {
    final difference = to - from;
    for (final player in Player.values) {
      final left = clocks[player]!;
      if (keepSpent && left <= Duration.zero) continue;
      final resized = left + difference;
      clocks[player] = keepSpent && resized < Duration.zero
          ? Duration.zero
          : resized;
    }
  }

  /// Pone a cero los relojes y deja el partido sin empezar. La configuración
  /// se conserva; el nombre del jugador dos lo restaura quien guarda los
  /// nombres (ADR-0003), que no es este módulo.
  void reset() {
    for (final player in Player.values) {
      _turnClock[player] = _turn;
      _reserveClock[player] = _reserve;
      _emittedThisMatch[player]!.clear();
    }
    _emittedThisTurn.clear();
    _active = null;
    _state = MatchState.notStarted;
  }

  Duration turnOf(Player player) => _turnClock[player]!;

  Duration reserveOf(Player player) => _reserveClock[player]!;
}
