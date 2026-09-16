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

/// Las tres intensidades de vibración, a la par de las tres bocinas. El
/// dominio nombra la intensidad y nada más: cuánto dura y con cuánta fuerza
/// sale lo decide el aparato, que es quien conoce el motor.
enum VibrationLevel { soft, strong, strongest }

/// Un aviso completo: la bocina que suena y la vibración que la acompaña.
class Alert {
  const Alert(this.sound, this.vibration);

  final AlertSound sound;

  final VibrationLevel vibration;
}

/// La jerarquía de intensidad del glosario: suave a los treinta segundos de
/// turno y de reserva, más fuerte al agotarse el turno, y la más fuerte de las
/// tres al agotarse la reserva.
Alert alertFor(Horn horn) => switch (horn) {
  Horn.turnWarning => const Alert(AlertSound.soft, VibrationLevel.soft),
  Horn.reserveWarning => const Alert(AlertSound.soft, VibrationLevel.soft),
  Horn.turnExpired => const Alert(AlertSound.strong, VibrationLevel.strong),
  Horn.reserveExpired => const Alert(
    AlertSound.strongest,
    VibrationLevel.strongest,
  ),
};
