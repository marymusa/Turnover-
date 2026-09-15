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
  final rest = (absolute % Duration.secondsPerMinute).toString().padLeft(2, '0');
  return '${seconds < 0 ? '-' : ''}$minutes:$rest';
}
