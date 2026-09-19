/// Reglas del cronómetro. Dart puro: no importa `flutter/` y no genera tiempo
/// por su cuenta, lo recibe en [MatchClock.advance].
library;

enum Player { one, two }

/// Cuál de los dos relojes del jugador activo está corriendo.
enum ClockKind { turn, reserve }

/// Pasar a segundo plano lleva a [paused], que es el mismo estado que produce
/// el botón y no uno nuevo (ADR-0001).
enum MatchState { notStarted, running, paused }

/// Lo que el cronómetro llega a anunciar. Son seis avisos y no seis bocinas:
/// el turno y la reserva avisan cada uno dos veces antes de agotarse, pronto y
/// a punto de acabar, y esos cuatro suenan igual. Con qué bocina se anuncia
/// cada uno lo decide quien escucha, no este módulo.
enum Horn {
  turnWarningEarly,
  turnWarning,
  turnExpired,
  reserveWarningEarly,
  reserveWarning,
  reserveExpired,
}

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
    this._earlyWarning = Duration.zero,
  }) : _turn = turn,
       _reserve = reserve,
       _turnClock = {Player.one: turn, Player.two: turn},
       _reserveClock = {Player.one: reserve, Player.two: reserve};

  Duration _turn;
  Duration _reserve;
  Duration _warning;

  /// El margen del aviso temprano. Solo avisa mientras quede por encima de
  /// [_warning]: con los dos agarres del deslizador en la misma posición los
  /// dos valores coinciden, y entonces avisa [_warning] a secas, que es un
  /// aviso y no dos bocinas en el mismo instante. A cero es no tenerlo.
  Duration _earlyWarning;

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

  Duration get earlyWarning => _earlyWarning;

  /// Lo que le queda al reloj que corre, entre cero y uno, para quien quiera
  /// pintar una barra. Nulo si este jugador no tiene ningún reloj corriendo,
  /// porque entonces no hay barra que pintar. En overtime es cero: la barra se
  /// vacía y no se pinta hacia el otro lado.
  double? remainingFractionOf(Player player) {
    if (_active != player) return null;
    return switch (runningClock) {
      ClockKind.turn => _fraction(_turnClock[player]!, _turn),
      ClockKind.reserve => _fraction(_reserveClock[player]!, _reserve),
      null => null,
    };
  }

  static double _fraction(Duration left, Duration total) =>
      (left.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);

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

    // El aviso previo a cero está desactivado, no es un aviso que llegue justo
    // al final: sin esto coincidiría con el agotamiento y sonarían dos bocinas
    // en el mismo instante.
    final hasWarning = _warning > Duration.zero;

    // Por lo mismo, el temprano tampoco avisa si coincide con el tardío. Y se
    // mide contra [total], que es el reloj entero configurado y no lo que
    // queda: un margen que cubre el reloj entero sonaría en su origen, y avisar
    // al arrancar es no avisar de nada. Vale para los dos relojes, aunque hoy
    // solo lo llegue a recortar el turno: con el tope del deslizador en 55
    // segundos y los dos relojes en un minuto como mínimo, el tiempo extra no
    // alcanza a cubrirse entero. Bajar ese mínimo lo pondría en juego.
    bool hasEarly(Duration total) =>
        _earlyWarning > _warning && _earlyWarning < total;

    final thisMatch = _emittedThisMatch[active]!;
    at(
      hasEarly(_turn) && turnClock <= _earlyWarning,
      Horn.turnWarningEarly,
      _emittedThisTurn,
    );
    at(hasWarning && turnClock <= _warning, Horn.turnWarning, _emittedThisTurn);
    at(turnClock <= Duration.zero, Horn.turnExpired, _emittedThisTurn);
    at(
      hasEarly(_reserve) && reserveClock <= _earlyWarning,
      Horn.reserveWarningEarly,
      thisMatch,
    );
    at(hasWarning && reserveClock <= _warning, Horn.reserveWarning, thisMatch);
    at(reserveClock <= Duration.zero, Horn.reserveExpired, thisMatch);

    return events;
  }

  /// La única acción del jugador activo. Funciona también con la reserva
  /// consumiéndose: lo único que lo impide es que esté pausado.
  ///
  /// [next] dice a quién le toca. Por defecto al oponente, que es lo que pasa
  /// dentro de una parte. Al cambiar de parte no: el orden se invierte, así que
  /// quien cierra una la abre también y juega dos turnos seguidos. El reloj no
  /// conoce las partes, y quien las conoce, [TurnCount], se lo dice aquí.
  void passTurn({Player? next}) {
    final active = _active;
    if (active == null || _state != MatchState.running) return;
    _turnClock[active] = _turn;
    _emittedThisTurn.clear();
    _active = next ?? (active == Player.one ? Player.two : Player.one);
    // El que entra estrena turno aunque sea el mismo que salía: lo que reinicia
    // el reloj es entrar, no cambiar de jugador.
    _turnClock[_active!] = _turn;
  }

  /// Redimensiona, no reinicia: lo gastado se conserva. Ampliar la reserva de
  /// quince a veinte con seis gastados deja catorce. Lo que no se pasa se
  /// queda como estaba.
  void reconfigure({
    Duration? turn,
    Duration? reserve,
    Duration? warning,
    Duration? earlyWarning,
  }) {
    if (turn != null) {
      _resize(_turnClock, from: _turn, to: turn, keepSpent: true);
      _turn = turn;
    }
    if (reserve != null) {
      _resize(_reserveClock, from: _reserve, to: reserve, keepSpent: false);
      _reserve = reserve;
    }
    if (warning != null) _warning = warning;
    if (earlyWarning != null) _earlyWarning = earlyWarning;
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
