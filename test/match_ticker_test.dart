import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/domain/match_ticker.dart';

void main() {
  group('el ticker', () {
    test('no consume nada hasta que hay un segundo toque de reloj', () {
      final ticker = newTicker();
      ticker.clock.start(Player.one);

      ticker.tick(at(0));
      ticker.tick(at(3));

      expect(ticker.clock.turnOf(Player.one), const Duration(minutes: 4) - at(3));
    });

    // El primer toque solo fija el origen: lo que pasó antes de empezar a mirar
    // el reloj no lo ha gastado nadie.
    test('el primer toque solo fija el origen', () {
      final ticker = newTicker();
      ticker.clock.start(Player.one);

      ticker.tick(at(90));

      expect(ticker.clock.turnOf(Player.one), const Duration(minutes: 4));
    });

    test('avanza el tiempo transcurrido entre dos toques', () {
      final ticker = newTicker();
      ticker.clock.start(Player.one);

      ticker.tick(at(10));
      ticker.tick(at(11));
      ticker.tick(at(14));

      expect(ticker.clock.turnOf(Player.one), const Duration(minutes: 4) - at(4));
    });

    // El origen se rehace al reanudar; si no, el rato pausado se le cobraría
    // entero al jugador activo en el primer toque de vuelta.
    test('lo que dura la pausa no se le cobra a nadie', () {
      final ticker = newTicker();
      ticker.clock.start(Player.one);
      ticker.tick(at(0));

      ticker.clock.pause();
      ticker.tick(at(30));
      ticker.clock.resume();
      ticker.tick(at(30));
      ticker.tick(at(32));

      expect(ticker.clock.turnOf(Player.one), const Duration(minutes: 4) - at(2));
    });

    test('devuelve las bocinas que emite el reloj', () {
      final ticker = newTicker();
      ticker.clock.start(Player.one);
      ticker.tick(at(0));

      expect(ticker.tick(at(209)), isEmpty);
      expect(ticker.tick(at(210)), [
        const MatchEvent(Horn.turnWarning, Player.one),
      ]);
    });

    // Un toque de pantalla cambia el reloj sin que pase el tiempo, y la
    // pantalla tiene que enterarse igual.
    test('refresh avisa sin consumir tiempo', () {
      final ticker = newTicker();
      ticker.clock.start(Player.one);
      ticker.tick(at(0));
      ticker.tick(at(5));

      var notified = 0;
      ticker.addListener(() => notified++);
      ticker.refresh();

      expect(notified, 1);
      expect(ticker.clock.turnOf(Player.one), const Duration(minutes: 4) - at(5));
    });

    // Pasar turno rehace el origen: si no, lo que tarde el jugador en tocar se
    // le cobraría al siguiente en el primer toque de reloj.
    test('después de refresh el siguiente toque no cobra lo anterior', () {
      final ticker = newTicker();
      ticker.clock.start(Player.one);
      ticker.tick(at(0));
      ticker.tick(at(10));

      ticker.clock.passTurn();
      ticker.refresh();
      ticker.tick(at(14));

      expect(ticker.clock.turnOf(Player.two), const Duration(minutes: 4));
    });

    test('notifica a quien escuche en cada toque', () {
      final ticker = newTicker();
      var notified = 0;
      ticker.addListener(() => notified++);
      ticker.clock.start(Player.one);
      ticker.tick(at(0));
      ticker.tick(at(1));

      expect(notified, 2);
    });
  });
}

Duration at(int seconds) => Duration(seconds: seconds);

MatchTicker newTicker() => MatchTicker(
  MatchClock(
    turn: const Duration(minutes: 4),
    reserve: const Duration(minutes: 15),
    warning: const Duration(seconds: 30),
  ),
);
