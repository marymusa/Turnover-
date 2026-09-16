/// Qué aviso le corresponde a cada bocina del reloj. Dart puro: describe el
/// efecto, no lo produce. Quién lo produce es [AlertDevice].
library;

import 'match_clock.dart';

/// Las tres bocinas empaquetadas, de menor a mayor intensidad. Son tres para
/// cuatro eventos: los dos avisos previos comparten la suave.
enum AlertSound {
  soft('audio/horn_soft.wav'),
  strong('audio/horn_strong.wav'),
  strongest('audio/horn_strongest.wav');

  const AlertSound(this.asset);

  /// La ruta dentro de `assets/`, tal como la espera `AssetSource`.
  final String asset;
}

/// Un aviso completo: la bocina que suena y las pulsaciones que la acompañan.
class Alert {
  const Alert(this.sound, this.pulses);

  final AlertSound sound;

  /// Una, dos o tres según la gravedad. Cuánto dura cada una y qué las separa
  /// lo decide el aparato, no este módulo.
  final int pulses;
}

/// La jerarquía de intensidad del glosario: suave a los treinta segundos de
/// turno y de reserva, más fuerte al agotarse el turno, y la más fuerte de las
/// tres al agotarse la reserva.
Alert alertFor(Horn horn) => switch (horn) {
  Horn.turnWarning => const Alert(AlertSound.soft, 1),
  Horn.reserveWarning => const Alert(AlertSound.soft, 1),
  Horn.turnExpired => const Alert(AlertSound.strong, 2),
  Horn.reserveExpired => const Alert(AlertSound.strongest, 3),
};
