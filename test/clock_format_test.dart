import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/clock_format.dart';

void main() {
  group('formatClock', () {
    test('escribe los minutos sin relleno y los segundos con dos cifras', () {
      expect(formatClock(const Duration(minutes: 4)), '4:00');
      expect(formatClock(const Duration(minutes: 15)), '15:00');
      expect(formatClock(const Duration(minutes: 1, seconds: 7)), '1:07');
    });

    test('el reloj agotado es cero, no un negativo de cero', () {
      expect(formatClock(Duration.zero), '0:00');
    });

    test('el overtime lleva el signo delante', () {
      expect(formatClock(const Duration(seconds: -5)), '-0:05');
      expect(formatClock(const Duration(minutes: -2, seconds: -30)), '-2:30');
    });

    // Un segundo empezado es un segundo que todavía se está gastando, así que
    // el reloj no lo da por consumido hasta que termina.
    test('redondea hacia arriba lo que queda', () {
      expect(formatClock(const Duration(milliseconds: 4200)), '0:05');
      expect(formatClock(const Duration(milliseconds: 1)), '0:01');
    });

    // Simétrico a lo anterior: en overtime lo que crece es lo ya gastado, y un
    // segundo empezado todavía no se ha pasado del todo.
    test('en overtime redondea hacia abajo lo pasado', () {
      expect(formatClock(const Duration(milliseconds: -4200)), '-0:04');
    });

    // El signo aparece con el primer segundo pasado, no antes: un cero con
    // signo se leería como que el reloj ya va en contra cuando aún no.
    test('el primer instante de overtime todavía es cero', () {
      expect(formatClock(const Duration(milliseconds: -1)), '0:00');
      expect(formatClock(const Duration(milliseconds: -999)), '0:00');
      expect(formatClock(const Duration(seconds: -1)), '-0:01');
    });
  });

  group('formatElapsed', () {
    test('por debajo de la hora se escribe como un reloj', () {
      expect(formatElapsed(Duration.zero), '0:00');
      expect(formatElapsed(const Duration(minutes: 22, seconds: 14)), '22:14');
      expect(formatElapsed(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    // La hora aparece cuando la hay y no antes: lo jugado por cada uno rara
    // vez la pasa, y `0:38:04` obliga a leer tres números para encontrar los
    // dos que importan.
    test('a partir de la hora aparece, con los minutos a dos cifras', () {
      expect(formatElapsed(const Duration(hours: 1)), '1:00:00');
      expect(
        formatElapsed(const Duration(hours: 1, minutes: 2, seconds: 30)),
        '1:02:30',
      );
      expect(
        formatElapsed(const Duration(hours: 2, minutes: 45, seconds: 9)),
        '2:45:09',
      );
    });

    // Al revés que [formatClock], que redondea hacia arriba porque cuenta lo
    // que queda: aquí se cuenta lo ya transcurrido, y el segundo en curso
    // todavía no ha pasado.
    test('trunca lo transcurrido en vez de redondearlo hacia arriba', () {
      expect(formatElapsed(const Duration(milliseconds: 4900)), '0:04');
      expect(formatElapsed(const Duration(milliseconds: 999)), '0:00');
    });

    // Los cuatro tiempos del acta se truncan a la vez y lo parado sale de
    // restar los otros tres ya truncados, así que lo que se enseña suma
    // aunque las duraciones traigan trozos de segundo.
    test('los cuatro tiempos del acta cuadran ya truncados', () {
      const playedByOne = Duration(minutes: 38, milliseconds: 900);
      const playedByTwo = Duration(minutes: 22, milliseconds: 900);
      const stopped = Duration(minutes: 4, milliseconds: 900);
      final total = playedByOne + playedByTwo + stopped;

      // Los tres trozos de segundo que cada uno pierde al truncarse suman uno
      // entero, y ese entero cae en lo parado, que es lo que se resta.
      final stoppedSeconds =
          total.inSeconds - playedByOne.inSeconds - playedByTwo.inSeconds;

      expect(formatElapsed(playedByOne), '38:00');
      expect(formatElapsed(playedByTwo), '22:00');
      expect(formatElapsed(Duration(seconds: stoppedSeconds)), '4:02');
      expect(formatElapsed(total), '1:04:02');
      expect(
        playedByOne.inSeconds + playedByTwo.inSeconds + stoppedSeconds,
        total.inSeconds,
      );
    });
  });
}
