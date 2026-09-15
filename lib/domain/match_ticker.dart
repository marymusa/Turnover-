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
  List<MatchEvent> tick(Duration now) {
    final origin = _origin;
    _origin = clock.state == MatchState.running ? now : null;

    final events = origin == null || clock.state != MatchState.running
        ? const <MatchEvent>[]
        : clock.advance(now - origin);

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
