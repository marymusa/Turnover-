import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../domain/alert_player.dart';
import '../domain/awake_guard.dart';
import '../domain/match_clock.dart';
import '../domain/match_ticker.dart';
import '../domain/player_names.dart';
import '../domain/turn_count.dart';
import '../l10n/app_localizations.dart';
import 'clock_colors.dart';
import 'clock_theme.dart';
import 'league_crest.dart';
import 'leave_dialog.dart';
import 'paused_veil.dart';
import 'player_half.dart';
import 'rename_dialog.dart';
import 'reset_dialog.dart';
import 'settings_button.dart';
import 'seam_controls.dart';
import 'time_out_dialog.dart';
import 'turn_count_row.dart';

/// La cara del cronómetro. Lo único que hace es pintar lo que dice
/// [MatchClock] y devolverle los toques: aquí no vive ninguna regla.
class ClockScreen extends StatefulWidget {
  const ClockScreen({
    required this.clock,
    required this.names,
    required this.alerts,
    required this.screen,
    required this.onOpenSettings,
    this.count,
    super.key,
  });

  final MatchClock clock;

  /// La cuenta de turnos. Entra desde fuera por lo mismo que el reloj: las
  /// capturas la siembran para llegar a un turno cualquiera sin pasar dieciséis
  /// veces por la pantalla. Nula es la de un partido que empieza.
  final TurnCount? count;

  /// Los nombres de los dos jugadores. Se cambian desde aquí en cualquier
  /// momento, también con el partido empezado.
  final PlayerNames names;

  /// Quien convierte en sonido y vibración lo que emite el reloj. El reloj no
  /// lo conoce: los eventos pasan por aquí.
  final AlertPlayer alerts;

  /// La pantalla del aparato, que se mantiene encendida mientras un reloj
  /// corre. Quien decide cuándo es [AwakeGuard], no este widget.
  final Screen screen;

  /// Abre los ajustes. Solo se llega antes de empezar: los tiempos se eligen
  /// con el partido parado, y lo que sí se cambia a media partida son los
  /// nombres, que son una etiqueta y no tocan el reloj.
  final VoidCallback onOpenSettings;

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// El reloj del que se lee todo, el que se pinta y el que avanza. Sale del
  /// ticker y no de `widget`, para que no puedan ser dos distintos.
  MatchClock get _clock => _ticker.clock;

  late final MatchTicker _ticker = MatchTicker(widget.clock);
  late final Ticker _frames = createTicker(_onFrame);
  late final AwakeGuard _awake = AwakeGuard(widget.clock, widget.screen);

  /// La cuenta de turnos, que va a la par del reloj: el reloj mide el tiempo y
  /// esto cuenta los turnos, y las dos se mueven con las mismas acciones de la
  /// mesa. No es un reloj, así que no pasa por el ticker: quien la repinta es
  /// el `setState` de cada acción.
  late final TurnCount _count = widget.count ?? TurnCount();

  /// Si la presentación del escudo ya ha terminado. La invitación a empezar
  /// espera a que lo haga: mientras se dibuja la costura, la pantalla está
  /// contando otra cosa, y dos animaciones a la vez se estorban.
  bool _isRevealed = false;

  /// El aviso se dispara y no se espera: lo que tarde el aparato en sonar no
  /// puede retrasar el toque de reloj siguiente.
  ///
  /// La pantalla se ajusta al reloj aquí, en un solo sitio, y no en cada
  /// manejador de toque: así ningún control que se añada después puede
  /// olvidarse de hacerlo. [AwakeGuard] solo cruza a la plataforma cuando
  /// cambia, de modo que llamarlo en cada fotograma no cuesta nada.
  void _onFrame(Duration now) {
    unawaited(widget.alerts.handle(_ticker.tick(now)));
    unawaited(_awake.sync());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Arrancar aquí y no en la inicialización del campo: `late` es perezoso y
    // un Ticker que nadie lee no llega a existir, así que el reloj no correría.
    _frames.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frames.dispose();
    _ticker.dispose();
    // Lo pedido a la pantalla no puede sobrevivir a quien lo pidió.
    unawaited(_awake.release());
    super.dispose();
  }

  /// Traduce el ciclo de vida de la plataforma a las dos únicas cosas que le
  /// importan al dominio: se deja el primer plano o se vuelve a él. Cualquier
  /// estado que no sea [AppLifecycleState.resumed] es estar fuera.
  ///
  /// El [MatchTicker.refresh] rehace el origen del ticker: sin él, lo que
  /// durase el rato fuera se le cobraría al jugador activo en el primer toque
  /// de vuelta.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      state == AppLifecycleState.resumed
          ? _awake.onReturnedToForeground()
          : _awake.onLeftForeground(),
    );
    _ticker.refresh();
  }

  /// El toque de una mitad: antes de empezar elige quién recibe la patada
  /// inicial, y después pasa turno. Pausado no hace nada, que es lo que
  /// bloquea pasar turno desde las mitades.
  void _tapHalf(Player player) {
    final clock = _clock;
    switch (clock.state) {
      case MatchState.notStarted:
        clock.start(player);
        _count.start(player);
      case MatchState.running:
        _passTurnOnBoth();
      case MatchState.paused:
        return;
    }
    _ticker.refresh();
  }

  void _togglePause() {
    final clock = _clock;
    if (clock.state == MatchState.paused) {
      clock.resume();
    } else {
      clock.pause();
    }
    _ticker.refresh();
  }

  void _passTurn() {
    _passTurnOnBoth();
    _ticker.refresh();
  }

  /// Pasa turno en los dos a la vez, que es la única forma de que no se
  /// separen. Quien dice a quién le toca es la cuenta, porque es la que conoce
  /// las partes: al cerrar una, quien la cierra la abre también y juega dos
  /// turnos seguidos, y el reloj por su cuenta habría alternado.
  ///
  /// El orden importa: la cuenta se lee antes de moverla, porque después ya ha
  /// entrado el siguiente.
  void _passTurnOnBoth() {
    _clock.passTurn(next: _count.playerAfterPassing);
    _count.passTurn();
  }

  /// El Time-Out que declaran los jugadores desde el velo: quita la pausa y
  /// aplica la regla (ADR-0010). La aplicación no conoce la tirada, la recoge.
  ///
  /// Se pregunta antes porque mueve las dos cuentas y no hay forma de
  /// deshacerlo, igual que reiniciar. Mientras se decide el partido sigue
  /// pausado, que es como llegó: el velo solo se va si se confirma.
  ///
  /// El `setState` es lo que repinta la cuenta: reanudar devuelve el ticker a
  /// su latido, pero el primer pintado de vuelta tiene que traer ya el número
  /// nuevo.
  Future<void> _timeOut() async {
    // La dirección se lee antes de preguntar y sale de la cuenta, que es quien
    // luego la aplica: deducirla aquí sería una segunda lectura de la regla, y
    // dos lecturas pueden acabar diciendo cosas distintas.
    final retreats = _count.timeOutRetreats;
    if (retreats == null) return;
    if (!await askToApplyTimeOut(context, retreats: retreats)) return;
    setState(() {
      _count.timeOut();
      _clock.resume();
    });
    _ticker.refresh();
  }

  /// Cambiar el nombre no toca ningún reloj, así que no refresca el ticker.
  /// Quien decide cuándo se puede es la mitad, que solo ofrece el gesto con el
  /// partido sin empezar.
  Future<void> _rename(Player player) async {
    final name = await askForName(
      context,
      current: widget.names.nameOf(player),
    );
    if (name == null) return;
    await widget.names.rename(player, name);
  }

  /// Reiniciar pierde el partido en curso, así que se pregunta antes de tocar
  /// nada. Lo que sobrevive, los tiempos y el nombre del jugador uno,
  /// sobrevive porque nadie lo toca: el reloj conserva su configuración al
  /// reiniciarse y aquí solo se devuelve a su valor por defecto el nombre del
  /// oponente (ADR-0003).
  Future<void> _reset() async {
    if (!await askToReset(context)) return;
    _clock.reset();
    _count.reset();
    widget.names.resetOpponent();
    // Reiniciar devuelve la pantalla a antes de empezar, y la costura se
    // presenta otra vez: la invitación vuelve a esperar a que termine, como
    // la primera vez.
    setState(() => _isRevealed = false);
    _ticker.refresh();
  }

  /// Volver con el partido empezado no pausa: cierra la aplicación, y con ella
  /// se va el partido, que no se guarda en ninguna parte (ADR-0003). Como el
  /// gesto no dice nada de eso, se pregunta antes.
  ///
  /// Se pausa mientras se decide, porque el reloj del jugador activo seguiría
  /// corriendo durante el diálogo y pensárselo le costaría tiempo. Si se queda,
  /// sigue pausado: reanudar es suyo, y el velo ya dice cómo.
  Future<void> _leave(bool didPop) async {
    if (didPop) return;
    _clock.pause();
    _ticker.refresh();
    if (await askToLeave(context)) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_ticker, widget.names]),
      // Todo lo que dependa del estado del partido se lee aquí dentro: lo
      // que se calcule fuera se queda con el valor del primer pintado. El
      // PopScope entra también, que por quedarse fuera nacía con el partido
      // sin empezar y dejaba salir sin preguntar.
      builder: (context, _) {
        final clock = _clock;
        return PopScope(
          // Antes de empezar no hay nada que perder: volver sale sin más.
          canPop: clock.state == MatchState.notStarted,
          onPopInvokedWithResult: (didPop, _) => unawaited(_leave(didPop)),
          child: Scaffold(
            backgroundColor: ClockColors.of(context).background,
            body: SafeArea(
              child: Stack(
                children: [
                  // La mitad del margen que a las tarjetas les falta contra el
                  // borde de la pantalla. Va aquí y no dentro de la mitad
                  // porque dentro la giraría el `RotatedBox` de la de arriba,
                  // y acabaría en el lado que no es.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: ClockTheme.halfCardVerticalInset,
                    ),
                    child: Column(
                      children: [
                        _Half(
                          clock: clock,
                          name: _nameOf(context, Player.two),
                          player: Player.two,
                          isUpsideDown: true,
                          onTap: _tapHalf,
                          onRename: clock.state == MatchState.notStarted
                              ? _rename
                              : null,
                          isRevealed: _isRevealed,
                        ),
                        _Half(
                          clock: clock,
                          name: _nameOf(context, Player.one),
                          player: Player.one,
                          isUpsideDown: false,
                          onTap: _tapHalf,
                          onRename: clock.state == MatchState.notStarted
                              ? _rename
                              : null,
                          isRevealed: _isRevealed,
                        ),
                      ],
                    ),
                  ),
                  // Las dos cuentas, cada una al pie de su tarjeta. Van encima
                  // de las mitades y no dentro de su columna: dentro habría que
                  // contarlas en `ClockTheme.naturalHalfHeight`, y apretarían
                  // los relojes en una pantalla corta a cambio de nada, porque
                  // el sitio que ocupan está vacío.
                  //
                  // Sin toque propio: la fila es un indicador, y lo que se
                  // pulsa debajo de ella es la mitad, que pasa turno.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _TurnCounts(
                        count: _count,
                        isStarted: clock.state != MatchState.notStarted,
                      ),
                    ),
                  ),
                  // El velo tapa las dos mitades, para que el toque no les llegue,
                  // pero queda por debajo de la costura: el botón de pausa y el de
                  // reinicio se siguen pudiendo pulsar con el partido pausado.
                  if (clock.state == MatchState.paused)
                    Positioned.fill(
                      child: PausedVeil(
                        onResume: _togglePause,
                        onTimeOut: _timeOut,
                      ),
                    ),
                  // Antes de empezar la costura está vacía, y el escudo de la
                  // liga la ocupa. Se va en cuanto arranca el partido, que es
                  // cuando los controles la necesitan.
                  if (clock.state == MatchState.notStarted)
                    Positioned.fill(
                      child: LeagueCrest(
                        onRevealed: () => setState(() => _isRevealed = true),
                      ),
                    ),
                  // El acceso a los ajustes solo existe antes de empezar: con el
                  // partido en marcha no hay ningún tiempo que tocar sin querer.
                  //
                  // Va en la costura, al lado del escudo, que es el hueco que no
                  // pertenece a ninguna de las dos mitades: pegado a una esquina
                  // caía dentro de la tarjeta del rival y parecía suya. El
                  // escudo se queda centrado y esto se aparta a su derecha.
                  if (clock.state == MatchState.notStarted)
                    Positioned.fill(
                      child: Center(
                        child: Transform.translate(
                          offset: const Offset(ClockTheme.settingsOffset, 0),
                          child: SettingsButton(
                            onPressed: widget.onOpenSettings,
                          ),
                        ),
                      ),
                    ),
                  // La costura solo existe con el partido empezado.
                  if (clock.state != MatchState.notStarted)
                    Positioned.fill(
                      child: Center(
                        child: SeamControls(
                          isPaused: clock.state == MatchState.paused,
                          onPassTurn: _passTurn,
                          onTogglePause: _togglePause,
                          onReset: _reset,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Resuelve aquí el nombre por defecto, que está localizado y por eso no
  /// puede vivir en [PlayerNames].
  String _nameOf(BuildContext context, Player player) {
    final strings = AppLocalizations.of(context)!;
    return widget.names.nameOf(player) ??
        switch (player) {
          Player.one => strings.playerOne,
          Player.two => strings.playerTwo,
        };
  }
}

/// Las dos cuentas, cada una al pie de la tarjeta de su jugador.
///
/// El reparto va con dos [Expanded], que es el mismo que hace la pantalla con
/// las mitades: así cada fila cae justo donde acaba su tarjeta. El pie de cada
/// jugador es el que ve él, no el de la pantalla, de modo que la de arriba va
/// girada con su mitad y el suyo cae contra el borde superior.
class _TurnCounts extends StatelessWidget {
  const _TurnCounts({required this.count, required this.isStarted});

  final TurnCount count;
  final bool isStarted;

  @override
  Widget build(BuildContext context) {
    // El mismo margen vertical que la pantalla le pone a las tarjetas: es lo
    // que hace que los dos [Expanded] caigan justo donde caen las dos mitades,
    // y con ellos las filas al pie de cada tarjeta y no al de la pantalla.
    //
    // El de la tarjeta lo pone la propia fila, que es quien sabe lo que se
    // despega de la pared por dentro. Aquí solo se reparte el alto.
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ClockTheme.halfCardVerticalInset,
      ),
      child: Column(
        children: [
          Expanded(
            child: RotatedBox(
              quarterTurns: 2,
              child: _CountFor(
                count: count,
                player: Player.two,
                isStarted: isStarted,
              ),
            ),
          ),
          Expanded(
            child: _CountFor(
              count: count,
              player: Player.one,
              isStarted: isStarted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lee de la cuenta lo que le toca a un jugador y se lo pasa a [TurnCountRow],
/// que es lo mismo que hace [_Half] con el reloj.
class _CountFor extends StatelessWidget {
  const _CountFor({
    required this.count,
    required this.player,
    required this.isStarted,
  });

  final TurnCount count;
  final Player player;
  final bool isStarted;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    final isActive = count.activePlayer == player;
    return Align(
      alignment: Alignment.bottomCenter,
      child: TurnCountRow(
        turn: count.of(player),
        half: count.half,
        isActive: isActive,
        // El fondo real de la mitad, que es con el que se recorta el número de
        // la casilla en curso. La mitad que espera comparte el suyo.
        surface: isActive
            ? colors.activeOf(player)
            : colors.inactive,
        isStarted: isStarted,
      ),
    );
  }
}

/// Lee del reloj lo que le toca a un jugador y se lo pasa a [PlayerHalf].
class _Half extends StatelessWidget {
  const _Half({
    required this.clock,
    required this.name,
    required this.player,
    required this.isUpsideDown,
    required this.onTap,
    required this.onRename,
    required this.isRevealed,
  });

  final MatchClock clock;
  final String name;
  final Player player;
  final bool isUpsideDown;
  final void Function(Player) onTap;

  /// Nulo con el partido empezado: renombrar se pacta antes de empezar.
  final void Function(Player)? onRename;

  /// Si la presentación del escudo ya ha terminado, que es cuando la mitad
  /// puede ofrecer el toque inicial.
  final bool isRevealed;

  @override
  Widget build(BuildContext context) {
    // El Expanded va aquí, que es el hijo directo de la columna: las dos
    // mitades tienen que repartirse la pantalla por igual.
    return Expanded(
      child: PlayerHalf(
        name: name,
        onRename: onRename == null ? null : () => onRename!(player),
        turn: clock.turnOf(player),
        reserve: clock.reserveOf(player),
        remainingFraction: clock.remainingFractionOf(player),
        isActive: clock.activePlayer == player,
        activeColor: player == Player.one
            ? ClockColors.of(context).active
            : ClockColors.of(context).activeOpponent,
        isStarted: clock.state != MatchState.notStarted,
        isUpsideDown: isUpsideDown,
        isRevealed: isRevealed,
        onTap: () => onTap(player),
      ),
    );
  }
}
