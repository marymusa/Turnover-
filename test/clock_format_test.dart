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
}
