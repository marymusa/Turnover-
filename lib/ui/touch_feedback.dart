/// El tacto: la respuesta al dedo del jugador, lo que confirma que un toque ha
/// entrado.
///
/// No es la vibración de las bocinas y no se parece en nada a ella. Aquella
/// avisa a alguien que no está mirando la pantalla y por eso sale por el canal
/// de avisos, con su código nativo y sus intensidades medidas (ADR-0005). Esta
/// contesta a un dedo que está encima del cristal, así que sale por el canal de
/// las hápticas de la vista, que es justo el que el jugador apaga con la casilla
/// de vibrar al tocar. Que esa casilla la silencie no es un fallo: es lo que el
/// jugador ha pedido (ADR-0014).
///
/// Todo el mapa está aquí y no repartido por los widgets. Lo que hay que poder
/// leer de un tirón no es qué intensidad lleva un botón suelto, sino la escala
/// entera: qué se considera un cambio de estado y qué no.
library;

import 'package:flutter/services.dart';

/// Lo que responde a cada gesto que cambia algo.
///
/// Solo los cambios de estado llevan tacto. Abrir un diálogo no cambia nada,
/// así que el botón que lo abre no responde y sí lo hace el que confirma
/// dentro; cancelar tampoco, porque deja las cosas como estaban. Ponerlo en
/// todo es lo que desaconsejan las guías de las dos plataformas, y con razón:
/// lo que se nota siempre deja de notarse.
abstract final class TouchFeedback {
  /// Pasar turno, y el toque que arranca el partido, que es el mismo gesto.
  ///
  /// Más fuerte que el resto a propósito. Es el único gesto que se hace en
  /// mitad de una partida y muchas veces sin mirar, así que es el único que
  /// tiene que poder confirmarse solo con el dedo.
  ///
  /// Sale igual desde la mitad del jugador que desde el botón de la costura:
  /// son la misma acción y notarlas distinto diría que no lo son.
  static Future<void> turnPassed() => HapticFeedback.mediumImpact();

  /// Pausar, reanudar y quitar el velo tocando en cualquier sitio.
  ///
  /// Cambian el estado del reloj, así que responden; flojo, porque quien los
  /// toca está mirando la pantalla y ya lo ve.
  static Future<void> clockToggled() => HapticFeedback.lightImpact();

  /// Confirmar un Time-Out, que mueve las dos cuentas y no se deshace desde la
  /// aplicación.
  static Future<void> confirmed() => HapticFeedback.mediumImpact();

  /// Confirmar lo que destruye el partido en curso: reiniciar.
  ///
  /// El más pesado que la plataforma sabe dar con este nombre, y nada más. La
  /// idea de que el peso sirviera de aviso no se sostiene y se cayó al
  /// probarlo: en Android `heavyImpact` es `CONTEXT_CLICK`, que es un golpe
  /// más flojo que el `KEYBOARD_TAP` de `mediumImpact`, así que reiniciar se
  /// nota menos que pasar turno. Los nombres describen iOS (ADR-0014).
  ///
  /// Se deja igual a propósito. Llamar a otra cosa para sacar el peso en
  /// Android sería usar una háptica para lo que no es: la que de verdad pega
  /// fuerte, `HapticFeedback.vibrate`, es la respuesta a una pulsación larga,
  /// y no significa "esto no se deshace". El aviso lo da el diálogo, que está
  /// escrito para eso.
  static Future<void> destroyed() => HapticFeedback.heavyImpact();

  /// Guardar un nombre y confirmar la salida.
  ///
  /// Salir no destruye un partido guardado, porque no se guarda ninguno
  /// (ADR-0003): termina la aplicación y ya está. Por eso no lleva el peso de
  /// reiniciar.
  static Future<void> accepted() => HapticFeedback.lightImpact();

  /// Que una pulsación larga ha entrado, antes de que se vea nada.
  ///
  /// La excepción a lo de que navegar no responde, y no es un descuido. Un
  /// toque se sabe dado porque el dedo ha bajado; una pulsación larga no tiene
  /// ningún momento visible en el que cruce su umbral, así que sin tacto solo
  /// se sabe que ha entrado cuando ya ha salido el diálogo. Es lo que hacen las
  /// dos plataformas con este gesto.
  static Future<void> gestureRecognised() => HapticFeedback.selectionClick();

  /// Cada paso de un deslizador.
  ///
  /// `selectionClick` y no un golpe: es lo que las dos plataformas usan para
  /// una rueda que pasa por sus posiciones, y aquí los deslizadores llevan
  /// `divisions`, o sea que son exactamente eso.
  static Future<void> detent() => HapticFeedback.selectionClick();
}
