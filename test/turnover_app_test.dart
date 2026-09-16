import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/alert_player.dart';
import 'package:turnover/domain/awake_guard.dart';
import 'package:turnover/domain/match_alerts.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/main.dart';
import 'package:turnover/ui/clock_screen.dart';

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
