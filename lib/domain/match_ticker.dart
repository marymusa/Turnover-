import 'package:flutter/foundation.dart';

import 'match_clock.dart';

/// Convierte una sucesión de instantes en avances del reloj y avisa a quien
/// escuche. El tiempo entra por [tick]: el ticker no lo genera, para que se
/// pueda probar sin esperar.
class MatchTicker extends ChangeNotifier {
  MatchTicker(this.clock);

  final MatchClock clock;

  /// El instante del último toque, mientras el reloj corra. Se olvida al
  /// pausar para que el rato pausado no se le cobre a nadie al reanudar.
  Duration? _origin;

  /// Consume lo transcurrido desde el toque anterior y devuelve las bocinas
  /// que salgan. El primer toque solo fija el origen.
  ///
  /// Pausado también se mide, aunque no salga ninguna bocina: el partido
  /// sigue durando y ese rato es el tiempo parado, que el acta nombra. Va por
  /// [MatchClock.advanceStopped], que lo suma al total sin dárselo a nadie.
  ///
  /// El mismo origen sirve para los dos, y puede hacerlo porque cada cambio
  /// de estado pasa por [refresh]: sin él, el rato de un lado se le cobraría
  /// al otro al cruzar de pausado a corriendo.
  List<MatchEvent> tick(Duration now) {
    final state = clock.state;
    final isCounting =
        state == MatchState.running || state == MatchState.paused;

    final origin = _origin;
    _origin = isCounting ? now : null;

    var events = const <MatchEvent>[];
    if (origin != null && isCounting) {
      final elapsed = now - origin;
      if (state == MatchState.running) {
        events = clock.advance(elapsed);
      } else {
        clock.advanceStopped(elapsed);
      }
    }

    notifyListeners();
    return events;
  }

  /// Un toque de pantalla ha cambiado el reloj sin que pase el tiempo. Olvida
  /// el origen, para que el rato que el jugador tarde en tocar no se le cobre
  /// a nadie en el siguiente toque de reloj.
  void refresh() {
    _origin = null;
    notifyListeners();
  }
}
