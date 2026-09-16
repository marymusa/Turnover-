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

  group('la vibración', () {
    test('sube de intensidad con la gravedad', () {
      expect(alertFor(Horn.turnWarning).vibration, VibrationLevel.soft);
      expect(alertFor(Horn.reserveWarning).vibration, VibrationLevel.soft);
      expect(alertFor(Horn.turnExpired).vibration, VibrationLevel.strong);
      expect(
        alertFor(Horn.reserveExpired).vibration,
        VibrationLevel.strongest,
      );
    });

    // La vibración acompaña a la bocina en la misma intensidad: no hay aviso
    // que suene fuerte y vibre flojo.
    test('va a la par de la bocina', () {
      for (final horn in Horn.values) {
        final alert = alertFor(horn);
        expect(alert.vibration.name, alert.sound.name);
      }
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
