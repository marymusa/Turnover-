/// Traduce los eventos del reloj en avisos. Vive fuera de [MatchClock], que no
/// sabe que existen ni el sonido ni la vibración.
library;

import 'match_alerts.dart';
import 'match_clock.dart';

/// El aparato que produce el aviso de verdad. La implementación real toca la
/// plataforma; en los tests se sustituye por una que solo apunta lo que le
/// piden.
abstract interface class AlertDevice {
  Future<void> play(AlertSound sound);

  /// [pulses] son las pulsaciones seguidas que se piden, de una a tres.
  Future<void> vibrate(int pulses);
}

class AlertPlayer {
  const AlertPlayer(this._device);

  final AlertDevice _device;

  /// Dispara lo que corresponda a cada evento del avance. Los eventos vienen
  /// ya solo del jugador activo, porque el inactivo no tiene ningún reloj
  /// corriendo y el reloj no emite por él.
  Future<void> handle(List<MatchEvent> events) async {
    for (final event in events) {
      final alert = alertFor(event.horn);
      // Sonido y vibración salen a la vez, no uno detrás de otro: el jugador
      // tiene que notarlos juntos.
      await Future.wait([
        _quietly(() => _device.play(alert.sound)),
        _quietly(() => _device.vibrate(alert.pulses)),
      ]);
    }
  }

  /// Un aviso que no sale no es motivo para tumbar el partido: el aparato
  /// puede no tener vibrador o tener la salida de audio ocupada, y el reloj
  /// sigue corriendo igual. Solo se traga el fallo de la plataforma, y por eso
  /// envuelve una llamada al aparato y nada más.
  static Future<void> _quietly(Future<void> Function() effect) async {
    try {
      await effect();
    } on Exception {
      return;
    }
  }
}
