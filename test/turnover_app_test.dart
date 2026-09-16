import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/alert_player.dart';
import 'package:turnover/domain/awake_guard.dart';
import 'package:turnover/domain/match_alerts.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/domain/match_settings.dart';
import 'package:turnover/main.dart';
import 'package:turnover/ui/clock_screen.dart';
import 'package:turnover/ui/player_half.dart';

import 'memory_settings_store.dart';

void main() {
  group('el dueño del reloj', () {
    // El partido se perdía porque el reloj se construía en `build`: un rebuild
    // del padre dejaba dos instancias vivas, la que pintaba la pantalla con el
    // turno entero y la que corría el ticker con el tiempo ya gastado.
    testWidgets('el partido sobrevive a un rebuild de TurnoverApp', (
      tester,
    ) async {
      final rebuilds = ValueNotifier(0);
      addTearDown(rebuilds.dispose);

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: rebuilds,
          builder: (context, _) => TurnoverApp(
            alerts: const AlertPlayer(_SilentDevice()),
            screen: const _IgnoredScreen(),
            store: MemorySettingsStore(),
          ),
        ),
      );

      final clock = _clockOnScreen(tester);
      clock.start(Player.one);
      // Dos toques de reloj: el primero solo fija el origen del ticker y el
      // segundo es el que consume.
      await tester.pump();
      await tester.pump(const Duration(seconds: 70));

      rebuilds.value++;
      await tester.pump();

      expect(_clockOnScreen(tester), same(clock));
      expect(_clockOnScreen(tester).state, MatchState.running);
      expect(
        _clockOnScreen(tester).turnOf(Player.one),
        lessThan(const Duration(minutes: 4)),
      );
    });
  });

  group('los nombres en la pantalla', () {
    // Se busca por el texto en inglés, que es el idioma al que cae el banco de
    // pruebas. Que el castellano exista lo prueba localization_test.

    testWidgets('por defecto son los del ADR-0003', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Opponent'), findsOneWidget);
    });

    testWidgets('una pulsación larga en la mitad lo cambia', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await _rename(tester, from: 'Player 1', to: 'Ivan');

      expect(find.text('Ivan'), findsOneWidget);
      expect(find.text('Player 1'), findsNothing);
    });

    testWidgets('renombra al jugador de la mitad que se pulsa', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await _rename(tester, from: 'Opponent', to: 'Nurgle');

      expect(find.text('Nurgle'), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);
    });

    // Los tiempos y los nombres se pactan con el partido parado: despues, la
    // mitad es pasar turno y nada mas, para que un dedo lento no abra un
    // dialogo en mitad del juego.
    testWidgets('no se renombra con el partido empezado', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      // Se empieza tocando, que es el camino real: es el toque el que hace
      // que la pantalla se vuelva a pintar sin el gesto de renombrar.
      await tester.tap(_halfShowing('Player 1'));
      await _settle(tester);

      await tester.longPress(_halfShowing('Opponent'));
      await _settle(tester);

      expect(find.text('Change name'), findsNothing);
      expect(_clockOnScreen(tester).state, MatchState.running);
    });

    // La pulsacion larga no puede elegir quien recibe de paso.
    testWidgets('la pulsación larga no arranca el partido', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await tester.longPress(_halfShowing('Player 1'));
      await _settle(tester);

      expect(_clockOnScreen(tester).state, MatchState.notStarted);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
    });

    // Tocar sigue siendo solo elegir quien recibe, tambien sobre el nombre.
    testWidgets('tocar el nombre arranca el partido', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await tester.tap(find.text('Player 1'));
      await _settle(tester);

      expect(find.text('Change name'), findsNothing);
      expect(_clockOnScreen(tester).activePlayer, Player.one);
    });

    testWidgets('el del jugador uno sobrevive a cerrar la aplicación', (
      tester,
    ) async {
      final store = MemorySettingsStore();
      await tester.pumpWidget(_app(store: store));
      await _settle(tester);
      await _rename(tester, from: 'Player 1', to: 'Ivan');

      await tester.pumpWidget(_app(store: store, key: const Key('again')));
      await _settle(tester);

      expect(find.text('Ivan'), findsOneWidget);
    });

    testWidgets('el del jugador dos no sobrevive a cerrar la aplicación', (
      tester,
    ) async {
      final store = MemorySettingsStore();
      await tester.pumpWidget(_app(store: store));
      await _settle(tester);
      await _rename(tester, from: 'Opponent', to: 'Nurgle');

      await tester.pumpWidget(_app(store: store, key: const Key('again')));
      await _settle(tester);

      expect(find.text('Opponent'), findsOneWidget);
      expect(find.text('Nurgle'), findsNothing);
    });

    testWidgets('borrar el nombre devuelve al valor por defecto', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _rename(tester, from: 'Player 1', to: 'Ivan');

      await _rename(tester, from: 'Ivan', to: '');

      expect(find.text('Player 1'), findsOneWidget);
    });

    testWidgets('cancelar deja el nombre como estaba', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await _rename(tester, from: 'Player 1', to: 'Ivan', confirm: false);

      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Ivan'), findsNothing);
    });
  });

  group('reiniciar el partido', () {
    // El reinicio se define por lo que no borra, y por eso se comprueba con
    // los tiempos cambiados y los dos nombres puestos: lo que sobrevive es
    // tan parte del trato como lo que se va.

    testWidgets('el control no existe antes de empezar', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      expect(_resetControl, findsNothing);
    });

    testWidgets('pide confirmación describiendo la consecuencia', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);

      await tester.tap(_resetControl);
      await _settle(tester);

      expect(find.text('Reset the timer?'), findsOneWidget);
      // La consecuencia entera, también lo que se pierde sin ser el partido:
      // el nombre del oponente es lo otro que no sobrevive.
      expect(
        find.textContaining('The match in progress will be lost'),
        findsOneWidget,
      );
      expect(
        find.textContaining("the opponent's name will go back to the default"),
        findsOneWidget,
      );
      // Preguntar no es hacer: hasta confirmar, el partido sigue donde estaba.
      expect(_clockOnScreen(tester).state, MatchState.running);
    });

    testWidgets('cancelar deja el partido intacto', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);
      final spent = _clockOnScreen(tester).turnOf(Player.one);

      await tester.tap(_resetControl);
      await _settle(tester);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);

      expect(_clockOnScreen(tester).state, MatchState.running);
      // Sigue gastando turno donde lo dejó: preguntar no detiene el reloj, así
      // que lo que importa es que no haya vuelto a los cuatro minutos.
      expect(
        _clockOnScreen(tester).turnOf(Player.one),
        lessThanOrEqualTo(spent),
      );
    });

    testWidgets('confirmar devuelve los relojes a su valor inicial', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);

      await _confirmReset(tester);

      final clock = _clockOnScreen(tester);
      expect(clock.turnOf(Player.one), const Duration(minutes: 4));
      expect(clock.reserveOf(Player.one), const Duration(minutes: 15));
      expect(clock.reserveOf(Player.two), const Duration(minutes: 15));
    });

    testWidgets('confirmar deja el partido esperando el toque inicial', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);

      await _confirmReset(tester);

      expect(_clockOnScreen(tester).state, MatchState.notStarted);
      expect(_clockOnScreen(tester).activePlayer, isNull);
      // Y el toque siguiente vuelve a elegir quién recibe: la invitación de
      // cada mitad ha vuelto, que es la señal de que el partido no ha
      // empezado.
      expect(find.text('Whoever taps here receives the ball'), findsNWidgets(2));
      await tester.tap(find.text('Whoever taps here receives the ball').last);
      await _settle(tester);
      expect(_clockOnScreen(tester).activePlayer, Player.one);
    });

    testWidgets('reiniciar pausado no deja el partido pausado', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);
      await tester.tap(find.bySemanticsLabel('Pause'));
      await _settle(tester);

      await _confirmReset(tester);

      expect(_clockOnScreen(tester).state, MatchState.notStarted);
      expect(find.text('Paused. Tap anywhere to resume'), findsNothing);
    });

    testWidgets('conserva la configuración de tiempos', (tester) async {
      final store = MemorySettingsStore();
      await store.writeSeconds('turn_seconds', 180);
      await store.writeSeconds('reserve_seconds', 600);
      await tester.pumpWidget(_app(store: store));
      await _settle(tester);
      await _startAndSpend(tester);

      await _confirmReset(tester);

      final clock = _clockOnScreen(tester);
      expect(clock.turnOf(Player.one), const Duration(minutes: 3));
      expect(clock.reserveOf(Player.one), const Duration(minutes: 10));
    });

    testWidgets('conserva el nombre del jugador uno', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _rename(tester, from: 'Player 1', to: 'Ivan');
      await _startAndSpend(tester);

      await _confirmReset(tester);

      expect(find.text('Ivan'), findsOneWidget);
    });

    testWidgets('devuelve el del jugador dos al valor por defecto', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _rename(tester, from: 'Opponent', to: 'Nurgle');
      await _startAndSpend(tester);

      await _confirmReset(tester);

      expect(find.text('Opponent'), findsOneWidget);
      expect(find.text('Nurgle'), findsNothing);
    });
  });
}

Widget _app({required SettingsStore store, Key? key}) => TurnoverApp(
  key: key,
  alerts: const AlertPlayer(_SilentDevice()),
  screen: const _IgnoredScreen(),
  store: store,
);

/// El ticker del cronómetro corre en todos los fotogramas, así que la
/// aplicación no llega nunca a asentarse: hay que pedir los fotogramas a mano.
Future<void> _settle(WidgetTester tester) async {
  // Bastante para que entre o salga el diálogo, que es la única animación
  // que hay que dejar terminar.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _rename(
  WidgetTester tester, {
  required String from,
  required String to,
  bool confirm = true,
}) async {
  await tester.longPress(_halfShowing(from));
  await _settle(tester);
  await tester.enterText(find.byType(TextField), to);
  await tester.tap(find.text(confirm ? 'Save' : 'Cancel'));
  await _settle(tester);
}

final _resetControl = find.bySemanticsLabel('Reset timer');

/// La mitad que pinta ese nombre. La pulsacion larga va sobre la mitad entera,
/// asi que hay que apuntar a ella y no al texto.
Finder _halfShowing(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(PlayerHalf));

/// Arranca el partido y gasta un rato, que es el estado desde el que reiniciar
/// significa algo: con los relojes intactos no se distingue de no hacer nada.
Future<void> _startAndSpend(WidgetTester tester) async {
  _clockOnScreen(tester).start(Player.one);
  await tester.pump();
  await tester.pump(const Duration(seconds: 70));
}

Future<void> _confirmReset(WidgetTester tester) async {
  await tester.tap(_resetControl);
  await _settle(tester);
  await tester.tap(find.text('Reset'));
  await _settle(tester);
}

MatchClock _clockOnScreen(WidgetTester tester) =>
    tester.widget<ClockScreen>(find.byType(ClockScreen)).clock;

class _SilentDevice implements AlertDevice {
  const _SilentDevice();

  @override
  Future<void> play(AlertSound sound) async {}

  @override
  Future<void> vibrate(int pulses) async {}
}

class _IgnoredScreen implements Screen {
  const _IgnoredScreen();

  @override
  Future<void> keepOn(bool on) async {}
}
