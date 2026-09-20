/// Cómo se escribe un reloj en pantalla. Dart puro, sin `flutter/`.
library;

/// `m:ss`, con el signo delante cuando el reloj está en overtime.
///
/// Lo que queda se redondea hacia arriba y lo pasado hacia abajo, de forma que
/// el cero aparece justo cuando el reloj se agota y no un segundo antes. El
/// signo va con los segundos ya redondeados: el primer instante pasado sigue
/// siendo `0:00`, porque un cero con signo se leería como que el reloj ya va
/// en contra cuando todavía no.
String formatClock(Duration left) {
  final seconds = left.isNegative
      ? left.inMilliseconds ~/ Duration.millisecondsPerSecond
      : (left.inMilliseconds / Duration.millisecondsPerSecond).ceil();
  final absolute = seconds.abs();
  final minutes = absolute ~/ Duration.secondsPerMinute;
  final rest = (absolute % Duration.secondsPerMinute).toString().padLeft(
    2,
    '0',
  );
  return '${seconds < 0 ? '-' : ''}$minutes:$rest';
}

/// Lo que ha durado algo, para el acta: `h:mm:ss` a partir de la hora y
/// `m:ss` por debajo.
///
/// No vale [formatClock] y por eso son dos. Aquel cuenta lo que queda, y por
/// eso redondea hacia arriba, para que el cero caiga justo al agotarse el
/// reloj; aquí no queda nada ni se agota nada, se cuenta lo ya transcurrido,
/// que se trunca porque el segundo en curso todavía no ha pasado.
///
/// La hora aparece sola y no está siempre. Un partido de Blood Bowl la pasa,
/// pero lo jugado por cada uno rara vez, y escribir `0:38:04` donde caben
/// `38:04` obliga a leer tres números para encontrar los dos que importan.
String formatElapsed(Duration elapsed) {
  final seconds = elapsed.inSeconds;
  final minutes = seconds ~/ Duration.secondsPerMinute;
  final restSeconds = (seconds % Duration.secondsPerMinute).toString().padLeft(
    2,
    '0',
  );
  if (minutes < Duration.minutesPerHour) return '$minutes:$restSeconds';

  final hours = minutes ~/ Duration.minutesPerHour;
  final restMinutes = (minutes % Duration.minutesPerHour).toString().padLeft(
    2,
    '0',
  );
  return '$hours:$restMinutes:$restSeconds';
}
