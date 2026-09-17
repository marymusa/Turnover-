import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/match_clock.dart';

void main() {
  group('el turno', () {
    test('vuelve a su valor inicial en cada cambio de jugador', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 2));
      clock.passTurn();

      expect(clock.turnOf(Player.two), const Duration(minutes: 4));
    });
  });

  group('la reserva', () {
    test('no baja mientras el turno tiene tiempo', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 3));

      expect(clock.reserveOf(Player.one), const Duration(minutes: 15));
    });

    test('baja con el turno agotado, solo la del jugador activo', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 4));
      clock.advance(const Duration(minutes: 1));

      expect(clock.reserveOf(Player.one), const Duration(minutes: 14));
      expect(clock.reserveOf(Player.two), const Duration(minutes: 15));
    });

    test('el avance que agota el turno gasta el resto en la reserva', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 5));

      expect(clock.turnOf(Player.one), Duration.zero);
      expect(clock.reserveOf(Player.one), const Duration(minutes: 14));
    });

    test('atraviesa todo el partido sin recargarse', () {
      final clock = newClock();
      clock.start(Player.one);

      // Dieciséis turnos de cinco minutos: cada uno gasta el turno entero y un
      // minuto de reserva, y solo ocho son del jugador uno.
      for (var turn = 0; turn < 16; turn++) {
        clock.advance(const Duration(minutes: 5));
        clock.passTurn();
      }

      expect(clock.reserveOf(Player.one), const Duration(minutes: 7));
      expect(clock.reserveOf(Player.two), const Duration(minutes: 7));
    });
  });

  group('los eventos', () {
    test('el aviso de turno llega al quedar el margen configurado', () {
      final clock = newClock();
      clock.start(Player.one);

      expect(clock.advance(const Duration(minutes: 3, seconds: 29)), isEmpty);
      expect(clock.advance(const Duration(seconds: 1)), [
        const MatchEvent(Horn.turnWarning, Player.one),
      ]);
    });

    test('el aviso a cero no suena: cero es desactivado', () {
      final clock = MatchClock(
        turn: const Duration(minutes: 4),
        reserve: const Duration(minutes: 15),
        warning: Duration.zero,
      );
      clock.start(Player.one);

      // Al agotarse el turno suena que se ha agotado, y nada más: sin el aviso
      // previo, que a cero coincidiría con el final y sonaría dos veces.
      expect(clock.advance(const Duration(minutes: 4)), [
        const MatchEvent(Horn.turnExpired, Player.one),
      ]);
    });

    test('el aviso de reserva a cero tampoco suena', () {
      final clock = MatchClock(
        turn: const Duration(minutes: 4),
        reserve: const Duration(minutes: 15),
        warning: Duration.zero,
      );
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 4));

      expect(clock.advance(const Duration(minutes: 15)), [
        const MatchEvent(Horn.reserveExpired, Player.one),
      ]);
    });

    test('el aviso de turno no se repite en los avances siguientes', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 3, seconds: 30));

      expect(clock.advance(const Duration(seconds: 1)), isEmpty);
    });

    test('el turno agotado llega al llegar a cero', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 3, seconds: 30));

      expect(clock.advance(const Duration(seconds: 29)), isEmpty);
      expect(clock.advance(const Duration(seconds: 1)), [
        const MatchEvent(Horn.turnExpired, Player.one),
      ]);
      expect(clock.advance(const Duration(seconds: 1)), isEmpty);
    });

    test('un solo avance puede emitir el aviso y el turno agotado', () {
      final clock = newClock();
      clock.start(Player.one);

      expect(clock.advance(const Duration(minutes: 4)), [
        const MatchEvent(Horn.turnWarning, Player.one),
        const MatchEvent(Horn.turnExpired, Player.one),
      ]);
    });

    test('el aviso de reserva y la reserva agotada llegan en su momento', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 4));

      expect(clock.advance(const Duration(minutes: 14, seconds: 29)), isEmpty);
      expect(clock.advance(const Duration(seconds: 1)), [
        const MatchEvent(Horn.reserveWarning, Player.one),
      ]);
      expect(clock.advance(const Duration(seconds: 29)), isEmpty);
      expect(clock.advance(const Duration(seconds: 1)), [
        const MatchEvent(Horn.reserveExpired, Player.one),
      ]);
      expect(clock.advance(const Duration(seconds: 1)), isEmpty);
    });

    test('el turno vuelve a avisar después de pasar turno', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 4));
      clock.passTurn();

      expect(clock.advance(const Duration(minutes: 3, seconds: 30)), [
        const MatchEvent(Horn.turnWarning, Player.two),
      ]);
    });

    test('los avisos son del jugador activo, no del que espera', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 3, seconds: 30));
      clock.passTurn();

      expect(clock.advance(const Duration(minutes: 3, seconds: 30)), [
        const MatchEvent(Horn.turnWarning, Player.two),
      ]);
    });
  });

  group('pausar', () {
    test('el partido empieza sin empezar y corre al tocar', () {
      final clock = newClock();
      expect(clock.state, MatchState.notStarted);
      expect(clock.activePlayer, isNull);

      clock.start(Player.two);

      expect(clock.state, MatchState.running);
      expect(clock.activePlayer, Player.two);
    });

    test('avanzar pausado no mueve ningún reloj', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 4));
      clock.pause();

      expect(clock.advance(const Duration(minutes: 3)), isEmpty);
      expect(clock.turnOf(Player.one), Duration.zero);
      expect(clock.reserveOf(Player.one), const Duration(minutes: 15));
    });

    test('pausado bloquea pasar turno, y reanudar lo desbloquea', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.pause();
      clock.passTurn();

      expect(clock.activePlayer, Player.one);

      clock.resume();
      clock.passTurn();

      expect(clock.activePlayer, Player.two);
    });

    test('reanudar deja los relojes donde estaban', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 1));
      clock.pause();
      clock.resume();

      expect(clock.state, MatchState.running);
      expect(clock.turnOf(Player.one), const Duration(minutes: 3));
    });

    test('pasar turno no funciona antes de empezar', () {
      final clock = newClock();
      clock.passTurn();

      expect(clock.state, MatchState.notStarted);
      expect(clock.activePlayer, isNull);
    });
  });

  group('el overtime', () {
    test('el tiempo sigue en negativo una vez agotada la reserva', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 19));
      clock.advance(const Duration(minutes: 2));

      expect(clock.reserveOf(Player.one), const Duration(minutes: -2));
    });

    test('la reserva en negativo sigue bajando avance a avance', () {
      final clock = newClock();
      clock.start(Player.one);
      // Cuatro de turno y quince de reserva son diecinueve: el minuto que
      // sobra del primer avance ya es overtime.
      clock.advance(const Duration(minutes: 20));
      clock.advance(const Duration(seconds: 30));
      clock.advance(const Duration(seconds: 30));

      expect(clock.reserveOf(Player.one), const Duration(minutes: -2));
    });

    test('pasar turno funciona con la reserva consumiéndose', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 6));
      clock.passTurn();

      expect(clock.activePlayer, Player.two);
      expect(clock.turnOf(Player.one), const Duration(minutes: 4));
      expect(clock.reserveOf(Player.one), const Duration(minutes: 13));
    });

    test('pasar turno funciona con la reserva en negativo', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 21));
      clock.passTurn();

      expect(clock.activePlayer, Player.two);
      expect(clock.reserveOf(Player.one), const Duration(minutes: -2));
    });

    test('el jugador en negativo vuelve a gastar reserva en su turno', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 21));
      clock.passTurn();
      clock.passTurn();
      clock.advance(const Duration(minutes: 4));
      clock.advance(const Duration(minutes: 1));

      expect(clock.reserveOf(Player.one), const Duration(minutes: -3));
    });
  });

  group('reconfigurar', () {
    test('ampliar la reserva conserva lo gastado', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 10));

      clock.reconfigure(reserve: const Duration(minutes: 20));

      expect(clock.reserveOf(Player.one), const Duration(minutes: 14));
      expect(clock.reserveOf(Player.two), const Duration(minutes: 20));
    });

    test('recortar la reserva conserva lo gastado', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 10));

      clock.reconfigure(reserve: const Duration(minutes: 10));

      expect(clock.reserveOf(Player.one), const Duration(minutes: 4));
    });

    test('ampliar el turno conserva lo gastado en el turno en curso', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 1));

      clock.reconfigure(turn: const Duration(minutes: 5));

      expect(clock.turnOf(Player.one), const Duration(minutes: 4));
      expect(clock.turnOf(Player.two), const Duration(minutes: 5));
    });

    test('el turno nuevo es el que se restaura al pasar turno', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.reconfigure(turn: const Duration(minutes: 2));
      clock.advance(const Duration(minutes: 1));
      clock.passTurn();

      expect(clock.turnOf(Player.one), const Duration(minutes: 2));
    });

    test('cambiar el aviso mueve el momento del aviso de turno', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.reconfigure(warning: const Duration(minutes: 1));

      expect(clock.advance(const Duration(minutes: 3)), [
        const MatchEvent(Horn.turnWarning, Player.one),
      ]);
    });

    test('ampliar el turno no resucita un turno ya agotado', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 6));

      clock.reconfigure(turn: const Duration(minutes: 5));

      expect(clock.turnOf(Player.one), Duration.zero);
      expect(clock.runningClock, ClockKind.reserve);
      expect(clock.reserveOf(Player.one), const Duration(minutes: 13));
    });

    test('ampliar el turno vuelve a avisar al llegar al margen', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 3, seconds: 40));
      // Con el aviso ya dado, ampliar el turno devuelve al jugador por encima
      // del margen, así que el aviso tiene que volver a llegar.
      clock.reconfigure(turn: const Duration(minutes: 6));

      expect(clock.turnOf(Player.one), const Duration(minutes: 2, seconds: 20));
      expect(clock.advance(const Duration(minutes: 1)), isEmpty);
      expect(clock.advance(const Duration(seconds: 50)), [
        const MatchEvent(Horn.turnWarning, Player.one),
      ]);
    });

    test('ampliar la reserva agotada devuelve tiempo y la saca del overtime', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 21));

      clock.reconfigure(reserve: const Duration(minutes: 20));

      expect(clock.reserveOf(Player.one), const Duration(minutes: 3));
    });

    test('la reserva ampliada vuelve a avisar al agotarse otra vez', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 19));
      // Los avisos de reserva ya han llegado los dos. Ampliar a veinte deja
      // cinco minutos, por encima del margen, así que tienen que volver.
      clock.reconfigure(reserve: const Duration(minutes: 20));

      expect(clock.advance(const Duration(minutes: 4)), isEmpty);
      expect(clock.advance(const Duration(seconds: 30)), [
        const MatchEvent(Horn.reserveWarning, Player.one),
      ]);
      expect(clock.advance(const Duration(seconds: 30)), [
        const MatchEvent(Horn.reserveExpired, Player.one),
      ]);
    });

    test('lo que no se pasa se queda como estaba', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 10));

      clock.reconfigure(turn: const Duration(minutes: 6));

      expect(clock.reserveOf(Player.one), const Duration(minutes: 9));
      expect(clock.warning, const Duration(seconds: 30));
    });
  });

  group('empezar', () {
    test('el toque inicial no cambia de jugador con el partido empezado', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 2));

      clock.start(Player.two);

      expect(clock.activePlayer, Player.one);
      expect(clock.turnOf(Player.one), const Duration(minutes: 2));
    });

    test('el toque inicial no reanuda un partido pausado', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.pause();

      clock.start(Player.two);

      expect(clock.state, MatchState.paused);
      expect(clock.activePlayer, Player.one);
    });

    test('despues de reiniciar, el toque inicial vuelve a elegir', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.reset();

      clock.start(Player.two);

      expect(clock.activePlayer, Player.two);
      expect(clock.state, MatchState.running);
    });
  });

  group('reiniciar', () {
    test('devuelve el partido a sin empezar', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 10));

      clock.reset();

      expect(clock.state, MatchState.notStarted);
      expect(clock.activePlayer, isNull);
      expect(clock.turnOf(Player.one), const Duration(minutes: 4));
      expect(clock.turnOf(Player.two), const Duration(minutes: 4));
      expect(clock.reserveOf(Player.one), const Duration(minutes: 15));
      expect(clock.reserveOf(Player.two), const Duration(minutes: 15));
    });

    test('conserva la configuración', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.reconfigure(
        turn: const Duration(minutes: 3),
        reserve: const Duration(minutes: 10),
      );

      clock.reset();

      expect(clock.turnOf(Player.one), const Duration(minutes: 3));
      expect(clock.reserveOf(Player.one), const Duration(minutes: 10));
    });

    test('vuelve a emitir los eventos en el partido siguiente', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 19));

      clock.reset();
      clock.start(Player.one);

      expect(clock.advance(const Duration(minutes: 4)), [
        const MatchEvent(Horn.turnWarning, Player.one),
        const MatchEvent(Horn.turnExpired, Player.one),
      ]);
    });

    test('reiniciar pausado deja el partido sin empezar, no pausado', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.pause();

      clock.reset();

      expect(clock.state, MatchState.notStarted);
    });
  });

  group('qué reloj corre', () {
    test('antes de empezar no corre ninguno', () {
      expect(newClock().runningClock, isNull);
    });

    test('corre el turno mientras le quede tiempo', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 3));

      expect(clock.runningClock, ClockKind.turn);
    });

    test('corre la reserva con el turno agotado', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 4));

      expect(clock.runningClock, ClockKind.reserve);
    });

    test('sigue siendo la reserva en overtime', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 20));

      expect(clock.runningClock, ClockKind.reserve);
    });

    test('vuelve a ser el turno al pasar turno', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 5));
      clock.passTurn();

      expect(clock.runningClock, ClockKind.turn);
    });

    test('pausado no corre ninguno', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.pause();

      expect(clock.runningClock, isNull);
    });
  });

  group('lo que queda', () {
    test('es todo antes de gastar nada, y nada cuando no hay reloj corriendo', () {
      final clock = newClock();

      expect(clock.remainingFractionOf(Player.one), isNull);

      clock.start(Player.one);
      expect(clock.remainingFractionOf(Player.one), 1);
      expect(clock.remainingFractionOf(Player.two), isNull);
    });

    test('baja con el turno mientras el turno corre', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 1));

      expect(clock.remainingFractionOf(Player.one), 0.75);
    });

    test('pasa a medirse sobre la reserva al agotarse el turno', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 4));
      clock.advance(const Duration(minutes: 3));

      expect(clock.remainingFractionOf(Player.one), 0.8);
    });

    // La barra no se pinta hacia el otro lado: en overtime se queda vacía.
    test('en overtime es cero, no un negativo', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 20));

      expect(clock.remainingFractionOf(Player.one), 0);
    });

    test('no hay barra con el partido pausado', () {
      final clock = newClock();
      clock.start(Player.one);
      clock.pause();

      expect(clock.remainingFractionOf(Player.one), isNull);
    });
  });
}

MatchClock newClock() => MatchClock(
  turn: const Duration(minutes: 4),
  reserve: const Duration(minutes: 15),
  warning: const Duration(seconds: 30),
);
