import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/match_alerts.dart';
import 'package:turnover/domain/match_clock.dart';

void main() {
  group('la bocina de cada evento', () {
    test('el aviso de turno usa la bocina suave', () {
      expect(alertFor(Horn.turnWarning).sound, AlertSound.soft);
    });

    // El aviso previo al fin de la reserva usa también la bocina suave: son
    // tres bocinas para cuatro eventos.
    test('el aviso de reserva usa la bocina suave', () {
      expect(alertFor(Horn.reserveWarning).sound, AlertSound.soft);
    });

    test('agotarse el turno usa la bocina media', () {
      expect(alertFor(Horn.turnExpired).sound, AlertSound.strong);
    });

    test('agotarse la reserva usa la bocina más fuerte', () {
      expect(alertFor(Horn.reserveExpired).sound, AlertSound.strongest);
    });
  });

  group('las pulsaciones', () {
    test('van de una a tres según la gravedad', () {
      expect(alertFor(Horn.turnWarning).pulses, 1);
      expect(alertFor(Horn.reserveWarning).pulses, 1);
      expect(alertFor(Horn.turnExpired).pulses, 2);
      expect(alertFor(Horn.reserveExpired).pulses, 3);
    });
  });

  group('el fichero de cada bocina', () {
    test('cada bocina tiene el suyo, y no se repiten', () {
      final assets = AlertSound.values.map((sound) => sound.asset).toList();
      expect(assets.toSet(), hasLength(AlertSound.values.length));
      expect(assets, everyElement(startsWith('audio/')));
    });
  });
}
