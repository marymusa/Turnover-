import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../domain/alert_player.dart';
import '../domain/awake_guard.dart';
import '../domain/match_clock.dart';
import '../domain/match_ticker.dart';
import 'clock_theme.dart';
import 'paused_veil.dart';
import 'player_half.dart';
import 'seam_controls.dart';

/// La cara del cronómetro. Lo único que hace es pintar lo que dice
/// [MatchClock] y devolverle los toques: aquí no vive ninguna regla.
class ClockScreen extends StatefulWidget {
  const ClockScreen({
    required this.clock,
    required this.alerts,
    required this.screen,
    super.key,
  });

  final MatchClock clock;

  /// Quien convierte en sonido y vibración lo que emite el reloj. El reloj no
  /// lo conoce: los eventos pasan por aquí.
  final AlertPlayer alerts;

  /// La pantalla del aparato, que se mantiene encendida mientras un reloj
  /// corre. Quien decide cuándo es [AwakeGuard], no este widget.
  final Screen screen;

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
      case MatchState.running:
        clock.passTurn();
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
    _clock.passTurn();
    _ticker.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final clock = _clock;
    return Scaffold(
      backgroundColor: ClockTheme.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _ticker,
          builder: (context, _) => Stack(
            children: [
              Column(
                children: [
                  _Half(
                    clock: clock,
                    player: Player.two,
                    isUpsideDown: true,
                    onTap: _tapHalf,
                  ),
                  _Half(
                    clock: clock,
                    player: Player.one,
                    isUpsideDown: false,
                    onTap: _tapHalf,
                  ),
                ],
              ),
              // El velo tapa las dos mitades, para que el toque no les llegue,
              // pero queda por debajo de la costura: el botón de pausa y el de
              // reinicio se siguen pudiendo pulsar con el partido pausado.
              if (clock.state == MatchState.paused)
                Positioned.fill(child: PausedVeil(onResume: _togglePause)),
              // La costura solo existe con el partido empezado.
              if (clock.state != MatchState.notStarted)
                Positioned.fill(
                  child: Center(
                    child: SeamControls(
                      isPaused: clock.state == MatchState.paused,
                      onPassTurn: _passTurn,
                      onTogglePause: _togglePause,
                      // El reinicio se cablea en la tarea que le toca,
                      // junto con el diálogo que describe la consecuencia.
                      // Aquí el control solo existe.
                      onReset: null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lee del reloj lo que le toca a un jugador y se lo pasa a [PlayerHalf].
class _Half extends StatelessWidget {
  const _Half({
    required this.clock,
    required this.player,
    required this.isUpsideDown,
    required this.onTap,
  });

  final MatchClock clock;
  final Player player;
  final bool isUpsideDown;
  final void Function(Player) onTap;

  @override
  Widget build(BuildContext context) {
    // El Expanded va aquí, que es el hijo directo de la columna: las dos
    // mitades tienen que repartirse la pantalla por igual.
    return Expanded(
      child: PlayerHalf(
        turn: clock.turnOf(player),
        reserve: clock.reserveOf(player),
        remainingFraction: clock.remainingFractionOf(player),
        isActive: clock.activePlayer == player,
        isStarted: clock.state != MatchState.notStarted,
        isUpsideDown: isUpsideDown,
        onTap: () => onTap(player),
      ),
    );
  }
}
