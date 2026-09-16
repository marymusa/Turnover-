import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/alert_player.dart';
import 'package:turnover/domain/awake_guard.dart';
import 'package:turnover/domain/match_alerts.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/domain/match_settings.dart';
import 'package:turnover/main.dart';
import 'package:turnover/ui/clock_screen.dart';

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

    testWidgets('tocar un nombre lo cambia', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await _rename(tester, from: 'Player 1', to: 'Ivan');

      expect(find.text('Ivan'), findsOneWidget);
      expect(find.text('Player 1'), findsNothing);
    });

    // Los nombres son una etiqueta: cambiarlos no toca ningún reloj, así que
    // no hay ningún momento del partido en el que dejen de poder cambiarse.
    testWidgets('se puede renombrar con el partido empezado', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      _clockOnScreen(tester).start(Player.one);
      await tester.pump();

      await _rename(tester, from: 'Opponent', to: 'Nurgle');

      expect(find.text('Nurgle'), findsOneWidget);
      expect(_clockOnScreen(tester).state, MatchState.running);
    });

    // Tocar el nombre no puede pasar turno ni elegir quién recibe.
    testWidgets('tocar el nombre no arranca el partido', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await tester.tap(find.text('Player 1'));
      await _settle(tester);

      expect(_clockOnScreen(tester).state, MatchState.notStarted);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
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
  await tester.tap(find.text(from));
  await _settle(tester);
  await tester.enterText(find.byType(TextField), to);
  await tester.tap(find.text(confirm ? 'Save' : 'Cancel'));
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
