import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../domain/match_clock.dart';
import '../domain/match_ticker.dart';
import 'clock_theme.dart';
import 'player_half.dart';
import 'seam_controls.dart';

/// La cara del cronómetro. Lo único que hace es pintar lo que dice
/// [MatchClock] y devolverle los toques: aquí no vive ninguna regla.
class ClockScreen extends StatefulWidget {
  const ClockScreen({required this.clock, super.key});

  final MatchClock clock;

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen>
    with SingleTickerProviderStateMixin {
  late final MatchTicker _ticker = MatchTicker(widget.clock);
  late final Ticker _frames = createTicker(_ticker.tick);

  @override
  void initState() {
    super.initState();
    // Arrancar aquí y no en la inicialización del campo: `late` es perezoso y
    // un Ticker que nadie lee no llega a existir, así que el reloj no correría.
    _frames.start();
  }

  @override
  void dispose() {
    _frames.dispose();
    _ticker.dispose();
    super.dispose();
  }

  /// El toque de una mitad: antes de empezar elige quién recibe la patada
  /// inicial, y después pasa turno. Pausado no hace nada, que es lo que
  /// bloquea pasar turno desde las mitades.
  void _tapHalf(Player player) {
    final clock = widget.clock;
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
    final clock = widget.clock;
    if (clock.state == MatchState.paused) {
      clock.resume();
    } else {
      clock.pause();
    }
    _ticker.refresh();
  }

  void _passTurn() {
    widget.clock.passTurn();
    _ticker.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final clock = widget.clock;
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
