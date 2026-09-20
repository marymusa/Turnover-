/// Reglas del cronómetro. Dart puro: no importa `flutter/` y no genera tiempo
/// por su cuenta, lo recibe en [MatchClock.advance].
library;

enum Player { one, two }

/// Cuál de los dos relojes del jugador activo está corriendo.
enum ClockKind { turn, reserve }

/// Pasar a segundo plano lleva a [paused], que es el mismo estado que produce
/// el botón y no uno nuevo (ADR-0001).
///
/// [finished] es el del acta, y se entra al pasar el turno 16 del segundo
/// jugador. No se sale: un partido terminado no se reanuda, y lo único que
/// lleva fuera es [MatchClock.reset]. Que el partido haya terminado no lo sabe
/// el reloj, que no conoce las partes, sino la cuenta, que se lo dice con
/// [MatchClock.finish].
enum MatchState { notStarted, running, paused, finished }

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

  /// Lo que cada jugador ha tenido corriendo alguno de sus dos relojes, el de
  /// turno y el de tiempo extra juntos.
  ///
  /// Se acumula en vez de deducirse de [turnOf] y [reserveOf]: el turno vuelve
  /// a su valor entero en cada pase, así que lo jugado no queda en ninguno de
  /// los dos y hoy no lo sabe nadie.
  final Map<Player, Duration> _played = {
    Player.one: Duration.zero,
    Player.two: Duration.zero,
  };

  /// El tiempo de juego total: lo que han corrido los dos relojes y, además,
  /// lo que el partido ha estado parado.
  ///
  /// Lo parado tiene que caer en algún sitio y no es de ningún jugador, así
  /// que cae aquí. De aquí sale restando, en [stoppedTime].
  Duration _total = Duration.zero;

  /// Lo que cada jugador consumió en cada uno de sus turnos, en el orden en
  /// que los jugó. El acta lo pinta turno a turno, que es donde se ve el turno
  /// en el que alguien se quedó pensando.
  ///
  /// Van por orden y sin número de turno: el número es de [TurnCount], que es
  /// quien conoce las partes y a quien un Time-Out se lo mueve. Aquí el turno
  /// enésimo es el enésimo que jugó, y con eso basta para dibujarlo. Sin
  /// Time-Out los dos coinciden; con él, la lista es más corta o más larga
  /// que dieciséis, que es exactamente lo que pasó en la mesa.
  final Map<Player, List<Duration>> _turns = {
    Player.one: [],
    Player.two: [],
  };

  /// Lo que el jugador activo lleva consumido en el turno en curso. No se
  /// puede sacar de [turnOf]: en cuanto el turno se agota sigue corriendo el
  /// tiempo extra, y lo de este turno son los dos juntos.
  Duration _playedThisTurn = Duration.zero;

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

  /// Lo que este jugador ha jugado en todo el partido, turno y tiempo extra
  /// juntos. Es lo comparable del acta: quién jugó 38 minutos frente a quién
  /// jugó 22.
  ///
  /// El overtime cuenta como lo demás: es tiempo con su reloj corriendo, y
  /// que el tiempo extra se le haya acabado no se lo quita a nadie.
  Duration playedOf(Player player) => _played[player]!;

  /// Todo lo que ha durado el partido de puertas adentro: lo que han jugado
  /// los dos y lo que ha estado parado.
  ///
  /// De puertas adentro porque solo se cuenta el primer plano (ADR-0001). El
  /// rato que la aplicación pase en segundo plano no entra aquí, igual que no
  /// entra en ningún otro reloj.
  Duration get totalTime => _total;

  /// Lo que el partido ha estado parado, que es la diferencia entre el total
  /// y lo que han jugado los dos. Con los despliegues fuera de alcance es
  /// solo el tiempo de pausa.
  ///
  /// Se resta en vez de acumularse aparte para que los cuatro tiempos del
  /// acta cuadren por construcción: con dos acumuladores que se mueven por su
  /// cuenta, cuadrar pasa a depender de que nadie se olvide de sumar en uno
  /// de los dos sitios.
  Duration get stoppedTime =>
      _total - _played[Player.one]! - _played[Player.two]!;

  /// Lo que este jugador consumió en cada uno de sus turnos, por orden. El
  /// turno en curso no está: entra al pasarlo, que es cuando se sabe lo que
  /// duró.
  List<Duration> turnsOf(Player player) =>
      List.unmodifiable(_turns[player]!);

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

  /// El partido ha terminado y da paso al acta. Lo decide la cuenta, que es
  /// quien sabe que el segundo jugador acaba de pasar su turno 16: el reloj
  /// no conoce las partes y aquí solo se entera.
  ///
  /// No hay vuelta atrás, que es lo que distingue terminar de pausar: de aquí
  /// solo se sale con [reset]. Sin empezar no hay nada que terminar.
  void finish() {
    if (_state == MatchState.notStarted) return;
    _state = MatchState.finished;
  }

  /// Suma [elapsed] al tiempo de juego total sin dárselo a ningún jugador:
  /// es lo que el partido ha estado parado, y no es de nadie.
  ///
  /// Entra por su propia puerta y no por [advance] porque lo parado no
  /// consume ningún reloj: lo único que mueve es el total, que es de donde
  /// [stoppedTime] lo saca de vuelta.
  ///
  /// Solo cuenta pausado. Sin empezar y terminado no hay partido que medir, y
  /// corriendo el tiempo ya es de alguien.
  void advanceStopped(Duration elapsed) {
    if (_state != MatchState.paused) return;
    _total += elapsed;
  }

  /// Consume [elapsed] del jugador activo: primero el turno y, en cuanto se
  /// agota, la reserva. Un solo avance puede atravesar las dos cosas, y por eso
  /// puede devolver más de un evento.
  List<MatchEvent> advance(Duration elapsed) {
    final active = _active;
    if (active == null || _state != MatchState.running) return const [];

    // Lo jugado se apunta entero y antes de repartirlo, porque es el tiempo
    // que el jugador ha tenido el reloj corriendo y da igual cuál de los dos
    // lo absorba: un mismo avance puede atravesar el turno y seguir en el
    // tiempo extra, y las dos partes son suyas.
    _played[active] = _played[active]! + elapsed;
    _playedThisTurn += elapsed;
    _total += elapsed;

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
    // El turno que se cierra queda apuntado antes de tocar nada: es lo que el
    // acta dibuja, y una vez que entre el siguiente ya no se puede saber.
    _turns[active]!.add(_playedThisTurn);
    _playedThisTurn = Duration.zero;
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
      _played[player] = Duration.zero;
      _turns[player]!.clear();
      _emittedThisMatch[player]!.clear();
    }
    _emittedThisTurn.clear();
    _playedThisTurn = Duration.zero;
    _total = Duration.zero;
    _active = null;
    _state = MatchState.notStarted;
  }

  Duration turnOf(Player player) => _turnClock[player]!;

  Duration reserveOf(Player player) => _reserveClock[player]!;
}
