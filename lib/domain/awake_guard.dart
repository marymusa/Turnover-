/// Lo que el ADR-0001 pide del mundo de fuera: la pantalla encendida mientras
/// un reloj corre, y el tiempo pausado en cuanto la aplicación deja de estar
/// en primer plano. La regla vive aquí y no en el widget, y el ciclo de vida
/// de cada plataforma se queda fuera: aquí solo se entra y se sale del primer
/// plano.
library;

import 'match_clock.dart';

/// La pantalla del aparato, vista desde el dominio. La implementación real
/// pide el wakelock; en los tests se sustituye por una que solo apunta lo que
/// le piden.
abstract interface class Screen {
  /// Mantener la pantalla encendida, o dejar que el móvil la bloquee.
  Future<void> keepOn(bool on);
}

class AwakeGuard {
  AwakeGuard(this._clock, this._screen);

  final MatchClock _clock;
  final Screen _screen;

  /// Lo que la pantalla está haciendo de verdad, no lo que se le ha pedido:
  /// solo se apunta cuando la llamada sale bien. Nulo mientras no se le ha
  /// pedido nada.
  bool? _keptOn;

  /// Ajusta la pantalla a lo que dice el reloj. Se llama después de cualquier
  /// cosa que pueda haber cambiado si un reloj corre.
  Future<void> sync() => _ask(_clock.runningClock != null);

  /// Suelta la pantalla para siempre, al terminar. No mira el reloj: lo pedido
  /// no puede sobrevivir a quien lo pidió, corra o no.
  Future<void> release() => _ask(false);

  /// Dejar el primer plano pausa el partido, por la razón que sea. Lleva al
  /// mismo estado que el botón, que es el único pausado que hay (ADR-0001).
  Future<void> onLeftForeground() {
    _clock.pause();
    return sync();
  }

  /// Volver no reanuda: los jugadores se encuentran el cronómetro pausado y lo
  /// reanudan ellos. La pantalla se ajusta igual, porque el partido puede
  /// haberse quedado sin empezar.
  Future<void> onReturnedToForeground() => sync();

  /// Pide a la pantalla solo lo que todavía no está haciendo, porque cada
  /// llamada cruza a la plataforma.
  ///
  /// Un fallo no se apunta: la plataforma puede no admitir el wakelock o
  /// rechazarlo, y darlo por hecho dejaría la pantalla encendida el resto de
  /// la partida sin volver a intentarlo nunca. Al no apuntarlo, el siguiente
  /// toque de reloj lo reintenta.
  Future<void> _ask(bool on) async {
    if (on == _keptOn) return;
    try {
      await _screen.keepOn(on);
      _keptOn = on;
    } on Exception {
      return;
    }
  }
}
