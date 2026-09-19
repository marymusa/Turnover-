import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/domain/turn_count.dart';

void main() {
  group('la cuenta', () {
    test('empieza con los dos jugadores en 1', () {
      final count = TurnCount();

      expect(count.of(Player.one), 1);
      expect(count.of(Player.two), 1);
    });

    test('la primera vez de cada parte no incrementa a quien entra', () {
      final count = TurnCount()..start(Player.one);
      count.passTurn();

      expect(count.of(Player.one), 1);
      expect(count.of(Player.two), 1);
    });

    test('pasar turno incrementa el del jugador que entra', () {
      final count = TurnCount()..start(Player.one);
      count.passTurn();
      count.passTurn();

      expect(count.of(Player.one), 2);
      expect(count.of(Player.two), 1);
    });

    // Los dos van desfasados: el segundo llega a cada número cuando el primero
    // ya ha pasado.
    test('los dos van desfasados un turno', () {
      final count = TurnCount()..start(Player.one);
      for (var i = 0; i < 5; i++) {
        count.passTurn();
      }

      expect(count.of(Player.one), 3);
      expect(count.of(Player.two), 3);
    });
  });

  group('el turno de tablero', () {
    test('en la primera parte coincide con el mostrado', () {
      final count = TurnCount()..start(Player.one);
      count.passTurn();
      count.passTurn();

      expect(count.boardTurnOf(Player.one), 2);
    });

    test('el mostrado 9 es el tablero 1', () {
      final count = TurnCount()..start(Player.one);
      _playHalf(count);

      expect(count.of(Player.two), 9);
      expect(count.boardTurnOf(Player.two), 1);
    });

    // La segunda parte no rueda a una tercera, así que se juega hasta su
    // último turno en vez de esperar a que la parte cambie.
    test('el mostrado 16 es el tablero 8', () {
      final count = TurnCount()..start(Player.one);
      _playHalf(count);
      for (var i = 0; i < 15; i++) {
        count.passTurn();
      }

      expect(count.half, 2);
      expect(count.of(Player.one), 16);
      expect(count.boardTurnOf(Player.one), 8);
    });
  });

  group('las partes', () {
    test('la parte termina cuando el segundo pasa su turno 8 de tablero', () {
      final count = TurnCount()..start(Player.one);

      // El primer paso no incrementa, así que hacen falta dieciséis para que
      // los dos lleguen al 8 y el segundo lo pase.
      for (var i = 0; i < 15; i++) {
        count.passTurn();
        expect(count.half, 1);
      }
      count.passTurn();

      expect(count.half, 2);
    });

    test('la segunda parte empieza en el 9', () {
      final count = TurnCount()..start(Player.one);
      _playHalf(count);

      expect(count.of(Player.one), 9);
      expect(count.of(Player.two), 9);
    });

    // Time-Out desde el turno 1 hace que ambos avancen y la parte dure siete.
    test('una parte de siete turnos termina en el turno 7 y la segunda '
        'empieza igual en el 9', () {
      final count = TurnCount()..start(Player.one);
      count.timeOut();

      expect(count.of(Player.one), 2);
      expect(count.of(Player.two), 2);

      // Desde el 2, catorce pasos llevan al segundo a pasar su turno 8.
      for (var i = 0; i < 14; i++) {
        count.passTurn();
      }

      expect(count.half, 2);
      expect(count.of(Player.one), 9);
      expect(count.of(Player.two), 9);
    });

    // El otro lado de "sin topes": un Time-Out que retrocede desde el turno 8
    // alarga la parte, que pasa a durar nueve turnos (ADR-0008).
    test('una parte de nueve turnos no termina al replicar el turno 8', () {
      final count = TurnCount()..start(Player.one);

      // Hasta dejar a Player.two activo con su turno 8, el que cerraría.
      for (var i = 0; i < 15; i++) {
        count.passTurn();
      }
      count.timeOut();

      expect(count.of(Player.one), 7);
      expect(count.of(Player.two), 7);

      // Los dos vuelven a subir al 8 y solo entonces se acaba.
      count.passTurn();
      expect(count.half, 1);
      count.passTurn();
      expect(count.half, 1);
      count.passTurn();

      expect(count.half, 2);
      expect(count.of(Player.one), 9);
    });

    test('la segunda parte arranca en el jugador que no recibió en la '
        'primera', () {
      final count = TurnCount()..start(Player.one);
      _playHalf(count);

      expect(count.activePlayer, Player.two);
    });

    // El orden se invierte, así que quien cierra la primera parte la abre
    // también: pasa su turno 8 y entra otra vez, dos turnos seguidos.
    test('quien cierra la primera parte juega también el primer turno de la '
        'segunda', () {
      final count = TurnCount()..start(Player.one);

      // Hasta dejar a Player.two activo con su turno 8, que es el que cierra.
      for (var i = 0; i < 15; i++) {
        count.passTurn();
      }
      expect(count.activePlayer, Player.two);
      expect(count.boardTurnOf(Player.two), 8);

      count.passTurn();

      expect(count.half, 2);
      expect(count.activePlayer, Player.two);
      expect(count.of(Player.two), 9);
    });
  });

  // El reloj no conoce las partes y alterna por su cuenta, así que en el
  // cambio de parte se iba a otro jugador que la cuenta: a partir de ahí cada
  // mitad de la pantalla llevaba la cuenta de la otra. Quien sabe a quién le
  // toca es esto, y por eso lo dice.
  group('a quién le toca después de pasar', () {
    test('dentro de una parte es el oponente', () {
      final count = TurnCount()..start(Player.one);

      expect(count.playerAfterPassing, Player.two);
    });

    test('al cerrar una parte repite quien la cierra', () {
      final count = TurnCount()..start(Player.one);
      for (var i = 0; i < 15; i++) {
        count.passTurn();
      }
      expect(count.activePlayer, Player.two);

      expect(count.playerAfterPassing, Player.two);
    });

    test('coincide con quien queda activo tras pasar, reciba quien reciba', () {
      for (final receiver in Player.values) {
        final count = TurnCount()..start(receiver);
        for (var pass = 0; pass < 20; pass++) {
          final expected = count.playerAfterPassing;
          count.passTurn();
          expect(
            count.activePlayer,
            expected,
            reason: 'pase $pass recibiendo $receiver',
          );
        }
      }
    });
  });

  // Lo que el diálogo de confirmación tiene que decir antes de aplicar nada.
  // Es la misma lectura que hace [timeOut], expuesta para poder anunciarla: si
  // se dedujera aparte, el aviso y la regla podrían no coincidir.
  group('hacia dónde mueve un Time-Out', () {
    test('avanza desde un turno de tablero que no es 6, 7 ni 8', () {
      final count = _seeded(one: 5, two: 4, active: Player.one);

      expect(count.boardTurnOf(Player.two), 4);
      expect(count.timeOutRetreats, isFalse);
    });

    test('retrocede desde los turnos de tablero 6, 7 y 8', () {
      for (final kickerTurn in [6, 7, 8]) {
        final count = _seeded(
          one: kickerTurn + 1,
          two: kickerTurn,
          active: Player.one,
        );

        expect(count.timeOutRetreats, isTrue, reason: 'tablero $kickerTurn');
      }
    });

    // El mostrado 9 es el tablero 1, así que avanza: es lo que distingue leer
    // el turno de tablero de leer el número de la pantalla (ADR-0010).
    test('desde el mostrado 9 avanza, porque es el tablero 1', () {
      final count = _seeded(one: 9, two: 9, active: Player.two);

      expect(count.timeOutRetreats, isFalse);
    });

    // Lee al pateador y no al activo, que es lo único que UC7 distingue.
    test('lee al pateador y no al jugador activo', () {
      final count = _seeded(one: 6, two: 5, active: Player.one);

      expect(count.boardTurnOf(Player.one), 6);
      expect(count.boardTurnOf(Player.two), 5);
      expect(count.timeOutRetreats, isFalse);
    });

    test('coincide siempre con lo que hace timeOut', () {
      for (var turn = 1; turn <= 16; turn++) {
        final count = _seeded(one: turn, two: turn, active: Player.one);
        final retreats = count.timeOutRetreats!;
        final before = count.of(Player.one);
        count.timeOut();

        expect(
          count.of(Player.one) - before,
          retreats ? -1 : 1,
          reason: 'mostrado $turn',
        );
      }
    });

    test('nulo antes de empezar, que es cuando no hay pateador', () {
      expect(TurnCount().timeOutRetreats, isNull);
    });
  });

  group('Time-Out', () {
    // Los siete casos del ADR-0010, que son su tabla de la verdad. UC7 es el
    // único que distingue leer al pateador de leer al jugador activo.
    for (final useCase in _timeOutCases) {
      test(useCase.name, () {
        final count = _seeded(
          one: useCase.one,
          two: useCase.two,
          active: useCase.active,
        );

        count.timeOut();

        expect(count.of(Player.one), useCase.expectedOne);
        expect(count.of(Player.two), useCase.expectedTwo);
      });
    }

    test('no cambia de jugador activo ni de parte', () {
      final count = _seeded(one: 4, two: 3, active: Player.one);

      count.timeOut();

      expect(count.activePlayer, Player.one);
      expect(count.half, 1);
    });
  });

  group('la corrección a mano', () {
    test('sube y baja la cuenta de un solo jugador', () {
      final count = TurnCount()..start(Player.one);

      count.adjust(Player.one, 1);
      expect(count.of(Player.one), 2);
      expect(count.of(Player.two), 1);

      count.adjust(Player.one, -1);
      expect(count.of(Player.one), 1);
    });

    // Es justo para lo que está: un turno que nadie pasó. Corregirlo antes de
    // que el segundo entre no puede comerse su primer incremento.
    test('corregir antes del primer pase no se come el turno del segundo', () {
      final count = TurnCount()..start(Player.one);

      count.adjust(Player.one, 1);
      count.passTurn();

      expect(count.of(Player.one), 2);
      expect(count.of(Player.two), 2);
    });
  });

  group('reset', () {
    test('devuelve la cuenta y la parte a su estado inicial', () {
      final count = TurnCount()..start(Player.one);
      _playHalf(count);
      count.passTurn();

      count.reset();

      expect(count.of(Player.one), 1);
      expect(count.of(Player.two), 1);
      expect(count.half, 1);
      expect(count.activePlayer, isNull);
    });
  });
}

/// Un caso de la tabla de Time-Out del ADR-0010.
class _TimeOutCase {
  const _TimeOutCase({
    required this.name,
    required this.one,
    required this.two,
    required this.active,
    required this.expectedOne,
    required this.expectedTwo,
  });

  final String name;
  final int one;
  final int two;
  final Player active;
  final int expectedOne;
  final int expectedTwo;
}

const _timeOutCases = [
  _TimeOutCase(
    name: 'UC1: 9 y 9 con p2 activo, el pateador en tablero 1, avanzan',
    one: 9,
    two: 9,
    active: Player.two,
    expectedOne: 10,
    expectedTwo: 10,
  ),
  _TimeOutCase(
    name: 'UC2: 8 y 8 con p1 activo, el pateador en tablero 8, retroceden',
    one: 8,
    two: 8,
    active: Player.one,
    expectedOne: 7,
    expectedTwo: 7,
  ),
  _TimeOutCase(
    name: 'UC3: 1 y 1 con p1 activo, el pateador en tablero 1, avanzan',
    one: 1,
    two: 1,
    active: Player.one,
    expectedOne: 2,
    expectedTwo: 2,
  ),
  _TimeOutCase(
    name: 'UC4: 9 y 9 con p1 activo, el pateador en tablero 1, avanzan',
    one: 9,
    two: 9,
    active: Player.one,
    expectedOne: 10,
    expectedTwo: 10,
  ),
  _TimeOutCase(
    name: 'UC5: 7 y 6 con p1 activo, el pateador en tablero 6, retroceden',
    one: 7,
    two: 6,
    active: Player.one,
    expectedOne: 6,
    expectedTwo: 5,
  ),
  _TimeOutCase(
    name: 'UC6: 4 y 3 con p1 activo, el pateador en tablero 3, avanzan',
    one: 4,
    two: 3,
    active: Player.one,
    expectedOne: 5,
    expectedTwo: 4,
  ),
  // El que no puede faltar: el activo p1 está en tablero 6, que retrocedería,
  // y el pateador p2 en tablero 5, que avanza. Los otros seis dan el mismo
  // resultado con las dos lecturas.
  _TimeOutCase(
    name: 'UC7: 6 y 5 con p1 activo, el pateador en tablero 5, avanzan',
    one: 6,
    two: 5,
    active: Player.one,
    expectedOne: 7,
    expectedTwo: 6,
  ),
];

/// Una cuenta puesta a mano en un punto concreto, que es como se llega a los
/// casos de la tabla sin jugar la parte entera.
TurnCount _seeded({
  required int one,
  required int two,
  required Player active,
}) {
  final count = TurnCount()..start(active);
  count.adjust(Player.one, one - count.of(Player.one));
  count.adjust(Player.two, two - count.of(Player.two));
  return count;
}

/// Pasa turno hasta que la parte se acaba, sea cual sea su longitud.
void _playHalf(TurnCount count) {
  final half = count.half;
  var passes = 0;
  while (count.half == half && passes < _maxPassesPerHalf) {
    count.passTurn();
    passes += 1;
  }
  // Agotar el tope es que la parte no terminó nunca. Sin esto el test seguiría
  // adelante y fallaría más tarde por otra cosa, escondiendo la causa.
  expect(
    count.half,
    isNot(half),
    reason: 'la parte no terminó en $_maxPassesPerHalf pases',
  );
}

/// Un tope para no colgar el test: una parte no dura tanto ni con Time-Outs.
const _maxPassesPerHalf = 40;
