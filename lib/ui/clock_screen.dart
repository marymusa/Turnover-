import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../domain/alert_player.dart';
import '../domain/awake_guard.dart';
import '../domain/match_clock.dart';
import '../domain/match_ticker.dart';
import '../domain/player_names.dart';
import '../l10n/app_localizations.dart';
import 'clock_theme.dart';
import 'paused_veil.dart';
import 'player_half.dart';
import 'rename_dialog.dart';
import 'reset_dialog.dart';
import 'settings_button.dart';
import 'seam_controls.dart';

/// La cara del cronómetro. Lo único que hace es pintar lo que dice
/// [MatchClock] y devolverle los toques: aquí no vive ninguna regla.
class ClockScreen extends StatefulWidget {
  const ClockScreen({
    required this.clock,
    required this.names,
    required this.alerts,
    required this.screen,
    required this.onOpenSettings,
    super.key,
  });

  final MatchClock clock;

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
    widget.names.resetOpponent();
    _ticker.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final clock = _clock;
    return Scaffold(
      backgroundColor: ClockTheme.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_ticker, widget.names]),
          // Todo lo que dependa del estado del partido se lee aquí dentro: lo
          // que se calcule fuera se queda con el valor del primer pintado.
          builder: (context, _) => Stack(
            children: [
              Column(
                children: [
                  _Half(
                    clock: clock,
                    name: _nameOf(context, Player.two),
                    player: Player.two,
                    isUpsideDown: true,
                    onTap: _tapHalf,
                    onRename: clock.state == MatchState.notStarted ? _rename : null,
                  ),
                  _Half(
                    clock: clock,
                    name: _nameOf(context, Player.one),
                    player: Player.one,
                    isUpsideDown: false,
                    onTap: _tapHalf,
                    onRename: clock.state == MatchState.notStarted ? _rename : null,
                  ),
                ],
              ),
              // El acceso a los ajustes solo existe antes de empezar: con el
              // partido en marcha no hay ningún tiempo que tocar sin querer.
              if (clock.state == MatchState.notStarted)
                Positioned(
                  top: 0,
                  right: 0,
                  child: SettingsButton(onPressed: widget.onOpenSettings),
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
                      onReset: _reset,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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

/// Lee del reloj lo que le toca a un jugador y se lo pasa a [PlayerHalf].
class _Half extends StatelessWidget {
  const _Half({
    required this.clock,
    required this.name,
    required this.player,
    required this.isUpsideDown,
    required this.onTap,
    required this.onRename,
  });

  final MatchClock clock;
  final String name;
  final Player player;
  final bool isUpsideDown;
  final void Function(Player) onTap;

  /// Nulo con el partido empezado: renombrar se pacta antes de empezar.
  final void Function(Player)? onRename;

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
        isStarted: clock.state != MatchState.notStarted,
        isUpsideDown: isUpsideDown,
        onTap: () => onTap(player),
      ),
    );
  }
}
