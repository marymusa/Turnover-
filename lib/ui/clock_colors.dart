import 'package:flutter/material.dart';

import '../domain/match_clock.dart' show Player;

/// Los colores de la pantalla, en dos paletas: la oscura de siempre y una
/// clara para quien lleva el aparato en modo claro. No hay selector propio, la
/// elige el sistema.
///
/// Es una instancia y no constantes sueltas porque son dos. Las medidas siguen
/// en `ClockTheme`, que no cambia con la luz: lo que mide un dedo mide igual de
/// día que de noche.
///
/// Ninguna de las dos es una inversión de la otra. Los valores salieron de
/// medir contraste, y `test/clock_colors_test.dart` vuelve a medirlo para que
/// no se puedan retocar a ojo.
@immutable
class ClockColors {
  const ClockColors({
    required this.brightness,
    required this.background,
    required this.inactive,
    required this.active,
    required this.activeOpponent,
    required this.text,
    required this.activeText,
    required this.onSurface,
    required this.reserve,
    required this.inactiveReserve,
    required this.reportAccent,
    required this.reportAccentOpponent,
    required this.paused,
    required this.dialogSurface,
    required this.veilText,
    required this.controlSurface,
    required this.controlShadow,
    required this.halfCardBorder,
    required this.veilOpacity,
  });

  final Brightness brightness;

  /// El fondo de la pantalla, alrededor de las dos tarjetas.
  final Color background;

  /// La tarjeta del jugador que espera. Es lo único del cronómetro que cambia
  /// con la luz: la mitad activa lleva el color de su turno en las dos.
  final Color inactive;

  /// El azul del turno activo, para la mitad de abajo, y su complementario
  /// para la de arriba: cada jugador tiene su color y no hay que mirar dos
  /// veces para saber de quién es el turno.
  ///
  /// El par sobrevive al cambio de luz, los valores no. En las dos paletas es
  /// azul contra naranja, pero cada una tiene los suyos, medidos contra su
  /// propio fondo.
  final Color active;

  /// El naranja va quemado y no vivo. Con un naranja de los que salen en las
  /// paletas junto a este azul, la letra blanca se queda en 2:1 y no se lee.
  final Color activeOpponent;

  /// La letra que va encima de las tarjetas. Es clara en las dos paletas
  /// porque las tarjetas son oscuras en las dos.
  final Color text;

  /// La letra de la mitad cuyo turno corre, sobre el azul o el naranja. Es
  /// clara en las dos paletas, porque esas dos mitades van saturadas en las
  /// dos: lo que cambia con la luz es [text], la de la mitad que espera.
  final Color activeText;

  /// La letra que va encima del fondo de la pantalla y de los ajustes, que es
  /// lo único que cambia de claro a oscuro. En la paleta oscura coincide con
  /// [text]; en la clara es casi negra.
  final Color onSurface;

  /// El turno agotado, sobre el reloj de tiempo extra y su barra. Amarillo y
  /// no naranja desde que la mitad del rival es naranja: sobre ella, un
  /// naranja sobre otro dejaba de avisar de nada.
  ///
  /// Este es el de la mitad activa, sobre el azul o el naranja. Sobre ellos,
  /// que van saturados, solo destaca un color claro. Para la mitad que espera
  /// está [inactiveReserve]: ningún color pasa de 5:1 sobre las dos cosas a la
  /// vez, así que son dos y no uno.
  final Color reserve;

  /// Lo mismo, pero sobre la tarjeta del jugador que espera. Va aparte porque
  /// las dos mitades dejaron de compartir fondo: en la paleta clara la tarjeta
  /// inactiva es casi blanca, y sobre ella el amarillo se queda en 1,2:1 y no
  /// avisa de nada. En la oscura las dos siguen siendo el mismo amarillo.
  final Color inactiveReserve;

  /// El color con el que cada jugador sale en el acta: su pastilla, su tramo
  /// de la barra y su línea de la gráfica. Es la misma identidad que lleva su
  /// mitad durante el partido, y es lo que permite a quien lee la captura
  /// saber quién jugaba de qué lado.
  ///
  /// Los dos son además la paleta de una serie de datos, y como tal están
  /// medidos y no elegidos a ojo: caben en la banda de luminosidad de su modo,
  /// pasan el mínimo de croma, se separan de sobra bajo daltonismo (ΔE 30 en
  /// oscuro, 26 en claro, contra un objetivo de 8) y pasan el 3:1 contra el
  /// fondo. Quien los retoque tiene que volver a medirlos.
  ///
  /// Va aparte de [active] y [activeOpponent] por lo mismo que [reserve] va
  /// aparte de [inactiveReserve]: cambia el fondo. Aquellos se pintan como
  /// tarjeta entera y llevan la letra encima; estos son una marca pequeña
  /// sobre el fondo de la pantalla, y ahí el azul y el naranja de la paleta
  /// oscura se quedan en 2,9:1 y 2,6:1, por debajo del 3:1 que se le pide a
  /// un elemento gráfico. En la clara el fondo es casi blanco y los colores
  /// del partido pasan de sobra, así que allí son los mismos.
  final Color reportAccent;
  final Color reportAccentOpponent;

  /// Solo lo lleva el control de pausa mientras está pausado, que es el único
  /// sitio donde hace falta decir "esto está detenido a propósito".
  final Color paused;

  /// El fondo de los diálogos. En la paleta oscura es el mismo color que la
  /// tarjeta inactiva, que es de donde salió; en la clara no puede serlo,
  /// porque la tarjeta sigue siendo oscura y un diálogo oscuro en mitad de una
  /// pantalla clara se lee como un error y no como una pregunta. Va con
  /// [onSurface] encima, como el resto del marco.
  final Color dialogSurface;

  /// El aviso del velo. Va aparte porque el velo tiñe con [background], que es
  /// lo que cambia entre las dos paletas: sobre el velo claro la letra clara
  /// desaparecería.
  final Color veilText;

  /// El fondo de los controles redondos de la costura y del de los ajustes.
  ///
  /// Es un color entero y no una alfa sobre el fondo. Teñir el fondo con un
  /// 0,07 dejaba los botones en 1,15:1 contra él, y a esa distancia no se leen
  /// como botones puestos sobre la pantalla sino como manchas pegadas encima.
  /// Con superficie propia se apoyan en la pantalla en vez de flotar.
  final Color controlSurface;

  /// La sombra que los levanta de la pantalla. En la paleta clara es la que
  /// hace el trabajo: el blanco del botón sobre el gris del fondo se queda en
  /// 1,1:1, así que lo que lo despega no es el color sino la altura.
  final Color controlShadow;

  /// Lo que perfila la tarjeta del jugador que espera.
  ///
  /// Es un color entero y no una alfa sobre [text]. La tarjeta y el fondo de
  /// la pantalla se parecen mucho en las dos paletas, 1,1:1, así que lo que
  /// hace que se lea como una tarjeta y no como un trozo de fondo es el canto.
  /// Con una alfa de la letra clara, en la paleta clara salía blanco sobre
  /// blanco y la tarjeta desaparecía.
  final Color halfCardBorder;

  /// El velo de pausa deja ver los relojes por debajo: se pausa para hablar de
  /// la jugada, y el tiempo se sigue leyendo mientras se habla.
  final double veilOpacity;

  /// La de siempre, la que fijó el prototipo B2.
  static const dark = ClockColors(
    brightness: Brightness.dark,
    background: Color(0xFF0B0F19),
    inactive: Color(0xFF161B26),
    active: Color(0xFF1D4ED8),
    activeOpponent: Color(0xFF9A3412),
    text: Color(0xFFF8FAFC),
    activeText: Color(0xFFF8FAFC),
    onSurface: Color(0xFFF8FAFC),
    reserve: Color(0xFFFDE047),
    inactiveReserve: Color(0xFFFDE047),
    // El mismo azul y el mismo naranja, levantados del fondo casi negro: los
    // del partido se quedaban en 2,9:1 y 2,6:1 sobre él.
    //
    // El naranja no es el primero que se probó. Un 0xFFF97316 pasaba el
    // contraste pero se salía por arriba de la banda de luminosidad en que
    // tienen que caber los colores de una serie en modo oscuro, y una serie
    // fuera de banda destaca de más contra la otra. Este cae dentro y da 5,4:1
    // sobre el fondo.
    reportAccent: Color(0xFF3B82F6),
    reportAccentOpponent: Color(0xFFEA580C),
    paused: Color(0xFF16A34A),
    dialogSurface: Color(0xFF161B26),
    veilText: Color(0xFFF8FAFC),
    controlSurface: Color(0xFF232A38),
    controlShadow: Color(0xFF000000),
    halfCardBorder: Color(0xFF363A44),
    veilOpacity: 0.82,
  );

  /// La clara. Se aclaran el marco y la mitad del jugador que espera; la del
  /// turno que corre se queda con su color, que es lo que dice de quién es.
  ///
  /// El azul y el naranja se eligieron de nuevo apuntando a las razones de
  /// contraste que tenía la oscura, no a las máximas posibles: subidos hasta
  /// el tope, las dos mitades se volvían dos bloques casi negros sobre una
  /// página blanca, que es la paleta oscura con los márgenes aclarados.
  ///
  /// La mitad que espera sí se aclara, y con ella su letra y su aviso de turno
  /// agotado: por eso hay [text] y [activeText], y [reserve] e
  /// [inactiveReserve]. Las dos mitades dejaron de compartir fondo.
  static const light = ClockColors(
    brightness: Brightness.light,
    background: Color(0xFFF1F5F9),
    inactive: Color(0xFFFFFFFF),
    active: Color(0xFF234FC7),
    activeOpponent: Color(0xFF973E20),
    text: Color(0xFF0F172A),
    activeText: Color(0xFFF8FAFC),
    onSurface: Color(0xFF0F172A),
    reserve: Color(0xFFFDE047),
    inactiveReserve: Color(0xFF92400E),
    // Sobre el fondo claro los colores del partido pasan de sobra, así que la
    // pastilla del acta es exactamente el color con el que se jugó.
    reportAccent: Color(0xFF234FC7),
    reportAccentOpponent: Color(0xFF973E20),
    paused: Color(0xFF15803D),
    dialogSurface: Color(0xFFFFFFFF),
    veilText: Color(0xFF0F172A),
    controlSurface: Color(0xFFFFFFFF),
    controlShadow: Color(0xFF64748B),
    halfCardBorder: Color(0xFFCBD5E1),
    veilOpacity: 0.82,
  );

  /// El color que le toca a la mitad de un jugador mientras es su turno: el
  /// azul al uno y el naranja al dos. Va aquí y no en quien pinta porque es la
  /// paleta la que sabe de qué par se trata, y porque el reparto se preguntaba
  /// desde dos sitios.
  Color activeOf(Player player) =>
      player == Player.one ? active : activeOpponent;

  /// La pastilla que le toca a cada jugador en el acta, por lo mismo que
  /// [activeOf]: el reparto lo sabe la paleta, no quien pinta.
  Color reportAccentOf(Player player) =>
      player == Player.one ? reportAccent : reportAccentOpponent;

  /// La paleta que toca según lo que diga el aparato. Se lee del tema, que es
  /// quien ya sabe en qué modo está: así nadie tiene que consultar el sistema
  /// por su cuenta ni pasarse la paleta de widget en widget.
  static ClockColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light ? light : dark;

  /// El tema de Material armado con esta paleta. Lo que la aplicación pinta a
  /// mano no pasa por aquí; esto es para lo que resuelve Material por su
  /// cuenta, que sin decirle nada saldría de su paleta y no de la nuestra.
  ///
  /// El `brightness` es además lo que lee [of] para saber qué paleta toca, en
  /// vez de preguntar al sistema por su cuenta.
  ThemeData toTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: active,
        brightness: brightness,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      // El globo que sale al arrastrar un deslizador va en el azul activo, y
      // su letra la resolvía el esquema en un gris que encima de ese azul no
      // se leía. Va aquí y no en cada deslizador: es cosa del tema.
      //
      // La letra es [activeText] y no [text]: el globo va sobre el azul
      // saturado, como la mitad del turno que corre, y no sobre el marco.
      sliderTheme: SliderThemeData(
        valueIndicatorColor: active,
        valueIndicatorTextStyle: TextStyle(
          color: activeText,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
