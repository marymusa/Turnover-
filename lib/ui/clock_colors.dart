import 'package:flutter/material.dart';

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
    required this.onSurface,
    required this.reserve,
    required this.paused,
    required this.dialogSurface,
    required this.veilText,
    required this.advancedFillAlpha,
    required this.advancedIconAlpha,
    required this.advancedAloneFillAlpha,
    required this.advancedAloneIconAlpha,
    required this.halfCardBorderAlpha,
    required this.veilOpacity,
    required this.inactiveOpacity,
  });

  final Brightness brightness;

  /// El fondo de la pantalla, alrededor de las dos tarjetas.
  final Color background;

  /// La tarjeta del jugador que espera. En las dos paletas es oscura, y en la
  /// clara eso es deliberado: ver [reserve].
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

  /// La letra que va encima del fondo de la pantalla y de los ajustes, que es
  /// lo único que cambia de claro a oscuro. En la paleta oscura coincide con
  /// [text]; en la clara es casi negra.
  final Color onSurface;

  /// El turno agotado, sobre el reloj de tiempo extra y su barra. Amarillo y
  /// no naranja desde que la mitad del rival es naranja: sobre ella, un
  /// naranja sobre otro dejaba de avisar de nada.
  ///
  /// Este es el color que obliga a que la tarjeta inactiva siga siendo oscura
  /// en la paleta clara. Tiene que pasar de 5:1 sobre las tres superficies
  /// donde se pinta, y las dos mitades activas van saturadas: eso le exige ser
  /// claro. Sobre una tarjeta clara le exigiría ser oscuro, y no hay ningún
  /// color que sea las dos cosas. Se comprobó barriendo el espacio entero: con
  /// la tarjeta clara no hay solución, ni a 5:1 ni a 4,5:1.
  final Color reserve;

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

  /// Lo apagado que va un control avanzado. Son alfas sobre [onSurface] y no
  /// valen igual en las dos paletas: las de la oscura, invertidas, dan grises
  /// sucios en vez del mismo efecto.
  final double advancedFillAlpha;
  final double advancedIconAlpha;

  /// Lo mismo cuando el control va suelto, que es el caso de los ajustes antes
  /// de empezar. Sin nadie al lado que lo sitúe, a los valores de la costura se
  /// leía como un botón deshabilitado.
  final double advancedAloneFillAlpha;
  final double advancedAloneIconAlpha;

  /// El borde de la tarjeta, sobre [text]: la tarjeta es oscura en las dos
  /// paletas, así que quien la perfila es la letra clara.
  final double halfCardBorderAlpha;

  /// El velo de pausa deja ver los relojes por debajo: se pausa para hablar de
  /// la jugada, y el tiempo se sigue leyendo mientras se habla.
  final double veilOpacity;

  /// El jugador inactivo no se apaga del todo: se sigue leyendo desde el otro
  /// lado de la mesa.
  final double inactiveOpacity;

  /// La de siempre, la que fijó el prototipo B2.
  static const dark = ClockColors(
    brightness: Brightness.dark,
    background: Color(0xFF0B0F19),
    inactive: Color(0xFF161B26),
    active: Color(0xFF1D4ED8),
    activeOpponent: Color(0xFF9A3412),
    text: Color(0xFFF8FAFC),
    onSurface: Color(0xFFF8FAFC),
    reserve: Color(0xFFFDE047),
    paused: Color(0xFF16A34A),
    dialogSurface: Color(0xFF161B26),
    veilText: Color(0xFFF8FAFC),
    advancedFillAlpha: 0.07,
    advancedIconAlpha: 0.55,
    advancedAloneFillAlpha: 0.12,
    advancedAloneIconAlpha: 0.85,
    halfCardBorderAlpha: 0.14,
    veilOpacity: 0.82,
    inactiveOpacity: 0.3,
  );

  /// La clara. Lo que se aclara es el marco: el fondo de la pantalla, los
  /// ajustes y los diálogos. Las dos tarjetas siguen siendo oscuras, y no por
  /// no haberlas tocado: es lo que deja que [reserve] siga avisando.
  ///
  /// El azul y el naranja se eligieron de nuevo apuntando a las razones de
  /// contraste que tenía la oscura, no a las máximas posibles: subidos hasta
  /// el tope, las dos mitades se volvían dos bloques casi negros sobre una
  /// página blanca, que es la paleta oscura con los márgenes aclarados.
  ///
  /// Las alfas se quedan como en la oscura, pero no por copiarlas: se midieron
  /// otra vez. Lo que las hacía sospechosas era ir sobre [text]; pasadas a
  /// [onSurface], que en cada paleta es la letra del marco, el mismo 0,07 de
  /// relleno separa igual del fondo en las dos, 1,15 contra 1,17.
  static const light = ClockColors(
    brightness: Brightness.light,
    background: Color(0xFFF1F5F9),
    inactive: Color(0xFF1E293B),
    active: Color(0xFF234FC7),
    activeOpponent: Color(0xFF973E20),
    text: Color(0xFFF8FAFC),
    onSurface: Color(0xFF0F172A),
    reserve: Color(0xFFFDE047),
    paused: Color(0xFF15803D),
    dialogSurface: Color(0xFFFFFFFF),
    veilText: Color(0xFF0F172A),
    advancedFillAlpha: 0.07,
    advancedIconAlpha: 0.55,
    advancedAloneFillAlpha: 0.12,
    advancedAloneIconAlpha: 0.85,
    halfCardBorderAlpha: 0.14,
    veilOpacity: 0.82,
    inactiveOpacity: 0.3,
  );

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
      sliderTheme: SliderThemeData(
        valueIndicatorColor: active,
        valueIndicatorTextStyle: TextStyle(
          color: text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
