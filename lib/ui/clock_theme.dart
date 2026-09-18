import 'package:flutter/material.dart';

/// Los colores y las medidas que fijó el prototipo B2. Viven juntos y en un
/// solo sitio porque la pantalla es una sola y todas se eligieron a la vez,
/// mirándolas en un móvil de verdad.
abstract final class ClockTheme {
  static const background = Color(0xFF0B0F19);
  static const inactive = Color(0xFF161B26);
  static const active = Color(0xFF1D4ED8);
  static const text = Color(0xFFF8FAFC);

  /// El azul del turno activo, para la mitad de abajo, y su complementario
  /// para la de arriba: cada jugador tiene su color y no hay que mirar dos
  /// veces para saber de quién es el turno.
  ///
  /// El naranja va quemado y no vivo. Con un naranja de los que salen en las
  /// paletas junto a este azul, la letra blanca se queda en 2:1 y no se lee;
  /// bajado hasta aquí llega a 7:1, parecido al 6,4:1 que tiene sobre el azul,
  /// y las dos mitades se leen igual de bien.
  static const activeOpponent = Color(0xFF9A3412);

  /// El turno agotado, sobre el reloj de reserva y su barra. Amarillo y no
  /// naranja desde que la mitad del rival es naranja: sobre ella, un naranja
  /// sobre otro dejaba de avisar de nada. Es el único color que pasa de 5:1
  /// sobre las dos mitades.
  static const reserve = Color(0xFFFDE047);

  /// Solo la lleva el control de pausa mientras está pausado, que es el único
  /// sitio donde hace falta decir "esto está detenido a propósito".
  static const paused = Color(0xFF16A34A);

  /// El turno encoge y la reserva crece al agotarse el turno. Ninguno de los
  /// dos se mueve de sitio: solo cambian de tamaño y de color.
  static const turnSize = 96.0;
  static const turnSizeSpent = 40.0;
  static const reserveSize = 26.0;
  static const reserveSizeSpent = 60.0;

  /// El nombre se lee, pero no compite con los relojes: es una etiqueta.
  static const nameSize = 16.0;

  /// El lápiz que anuncia el cambio de nombre, al lado del nombre, y la pista
  /// que lo acompaña. Menores que la letra del nombre: acompañan, no encabezan.
  static const renameIconSize = 14.0;
  static const renameHintSize = 11.0;

  static const passTurnSize = 74.0;
  static const passTurnIconSize = 30.0;
  static const advancedSize = 40.0;
  static const advancedIconSize = 15.0;

  /// El nombre que acompaña al icono de los ajustes. Menor que la letra de los
  /// nombres de jugador, que es la referencia de la pantalla antes de empezar:
  /// el acceso se tiene que encontrar, pero no encabeza nada.
  static const settingsLabelSize = 13.0;

  /// Lo que separa los tres controles de la costura.
  static const seamGap = 26.0;

  /// El jugador inactivo no se apaga del todo: se sigue leyendo desde el otro
  /// lado de la mesa.
  static const inactiveOpacity = 0.3;

  /// El velo de pausa deja ver los relojes por debajo: se pausa para hablar de
  /// la jugada, y el tiempo se sigue leyendo mientras se habla.
  static const veilOpacity = 0.82;
  static const veilTextSize = 19.0;

  /// Lo que el aviso del velo se aparta del centro, para no caer encima de la
  /// costura, que se sigue pudiendo pulsar por debajo.
  static const veilTextOffset = 86.0;

  static const barHeight = 6.0;
  static const barWidthFactor = 0.74;

  /// El hueco que comparten la barra y el nombre del reloj de tiempo extra.
  /// Lo manda el texto, que es el más alto de los dos: con la altura de la
  /// barra el nombre saldría partido.
  static const barSlotHeight = 16.0;

  /// El hueco del nombre que va encima del turno. Se reserva también con el
  /// partido empezado, cuando no hay nombre que pintar.
  static const labelSlotHeight = 16.0;

  /// Los dos nombres de reloj, el del turno y el del tiempo extra.
  static const clockLabelSize = 11.0;

  /// Lo que separa cada nombre del reloj que nombra. El mismo para los dos: el
  /// de turno quedaba pegado al suyo y el de tiempo extra suelto entre ambos,
  /// y a distancias distintas no parecían el mismo tipo de etiqueta.
  static const labelToClockGap = 8.0;

  /// Lo que baja el reloj de turno hasta el hueco de debajo, el que comparten
  /// la barra y el nombre del tiempo extra. Mayor que [labelToClockGap] a
  /// propósito: así el nombre queda más cerca del reloj que nombra, el de
  /// abajo, que del que tiene encima.
  static const clockToSlotGap = 18.0;

  /// La invitación a empezar. Por encima de los nombres de reloj y de la pista
  /// de renombrar: es lo único que hay que hacer en esta pantalla, y con su
  /// tamaño no se distinguía de una etiqueta más.
  static const startHintSize = 14.0;

  /// La línea central del campo, antes de empezar. Cruza la pantalla de lado a
  /// lado, como la del campo, y es más estrecha que las barras de los relojes:
  /// recuerda al campo sin disputarle nada a los números.
  static const halfwayLineHeight = 4.0;
  static const halfwayLineOpacity = 0.6;


  /// El escudo de la liga, en el centro del campo y solo antes de empezar. Va
  /// a plena opacidad: sus colores son los suyos, y apagarlos no lo vuelve
  /// discreto, lo vuelve deslavado.
  static const leagueLogoSize = 96.0;

  /// La presentación del escudo, en dos tiempos: el cometa recorre el contorno
  /// y, al cerrarlo, entran a la vez el escudo y la línea central mientras el
  /// trazo se apaga. Una sola vez, al abrir la pantalla.
  ///
  /// El cometa manda sobre lo demás: hasta que no cierra la silueta no entra
  /// nada, y lo que entra después lo hace junto.
  static const logoRevealColor = text;
  static const logoTraceDuration = Duration(milliseconds: 1500);
  static const logoSettleDuration = Duration(milliseconds: 700);

  /// Lo que mide la cabeza brillante, en píxeles de contorno recorrido, y el
  /// grosor de cada parte del trazo.
  static const logoRevealTailLength = 26.0;
  static const logoRevealHeadWidth = 2.5;
  static const logoRevealTrailWidth = 1.5;
  static const logoRevealTrailAlpha = 0.55;
}
