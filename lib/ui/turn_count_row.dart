import 'package:flutter/material.dart';

import '../domain/turn_count.dart';
import '../l10n/app_localizations.dart';
import 'clock_colors.dart';
import 'clock_theme.dart';

/// La cuenta de turnos de un jugador: una fila de ocho casillas al pie de su
/// tarjeta, con la que se está jugando destacada.
///
/// El pie es el del jugador y no el de la pantalla: la mitad de arriba está
/// girada, así que el suyo cae contra el borde superior. De girarla se encarga
/// quien la coloca, igual que con [PlayerHalf].
///
/// La numeración es corrida: de 1 a 8 en la primera parte y de 9 a 16 en la
/// segunda, y así la parte se lee en el propio número sin ningún indicador
/// aparte (ADR-0010).
class TurnCountRow extends StatelessWidget {
  const TurnCountRow({
    required this.turn,
    required this.half,
    required this.isActive,
    required this.surface,
    required this.isStarted,
    super.key,
  });

  /// El número de cara al jugador, el corrido de 1 a 16.
  final int turn;

  /// La parte, que aquí solo corre la numeración: en la segunda las casillas
  /// van de 9 a 16.
  final int half;

  final bool isActive;

  /// El fondo de la mitad sobre la que se pinta, azul o naranja mientras es su
  /// turno. El número de la casilla en curso se recorta con él: con un color
  /// fijo salía azul encima del naranja del rival.
  final Color surface;

  /// Sin empezar no hay ningún turno jugado. La fila se vuelve transparente en
  /// vez de irse, igual que `_StartHint` en `player_half.dart`, y por lo mismo:
  /// si se fuera del todo, empezar movería los relojes de sitio.
  final bool isStarted;

  /// Lo que se le suma al número de casilla en la segunda parte.
  int get _offset => (half - 1) * TurnCount.turnsPerHalf;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    // La mitad activa conserva su color en los dos modos (ADR-0009), así que
    // su tinta es [activeText] y no cambia con la luz. La que espera sí se
    // aclara, y la suya es [text], que es la que el tema mueve.
    final colors = ClockColors.of(context);
    final ink = isActive ? colors.activeText : colors.text;

    return Opacity(
      opacity: isStarted ? 1 : 0,
      child: Semantics(
        label: strings.turnCount(
          turn,
          TurnCount.turnsPerHalf * TurnCount.halves,
        ),
        child: Padding(
          // El margen de la tarjeta y, encima, el hueco interior: la fila vive
          // dentro de la tarjeta, así que para despegarse de su pared hay que
          // sumar los dos. El de la tarjeta no vale lo mismo a los lados que
          // abajo, y sumarles lo mismo deja el hueco parejo por dentro.
          //
          // Abajo el margen de la tarjeta se suma dos veces, porque quien
          // coloca la fila ya reparte el alto con el suyo. Se deja así a
          // propósito: descontarlo deja el hueco de abajo más corto que el de
          // los lados, y lo que se mira en el móvil es que los tres sean el
          // mismo, no que la cuenta cuadre.
          padding: const EdgeInsets.only(
            left: ClockTheme.halfCardInset + ClockTheme.turnCountInset,
            right: ClockTheme.halfCardInset + ClockTheme.turnCountInset,
            bottom:
                ClockTheme.halfCardVerticalInset + ClockTheme.turnCountInset,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // De izquierda a derecha. El giro de la mitad de arriba invierte
              // la fila entera, de modo que cada jugador lee su cuenta
              // empezando por el número más bajo a su izquierda.
              for (var i = 1; i <= TurnCount.turnsPerHalf; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClockTheme.turnBoxGap,
                  ),
                  child: _TurnBox(
                    number: i + _offset,
                    state: _stateOf(i + _offset),
                    ink: ink,
                    surface: surface,
                    isOnActiveHalf: isActive,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _TurnState _stateOf(int number) {
    if (number == turn) return _TurnState.current;
    return number < turn ? _TurnState.played : _TurnState.upcoming;
  }
}

/// En qué punto de la cuenta está una casilla.
enum _TurnState {
  /// Ya jugado: apagado, porque no queda nada que hacer con él.
  played,

  /// El que se está jugando: es el único que destaca.
  current,

  /// Todavía por jugar: discreto, presente para dar la escala.
  upcoming,
}

/// Una casilla de la cuenta, construida como un chip de Material: una
/// [Material] con su forma, su elevación y su tinta, y no un [Container]
/// pintado a mano.
///
/// Los tres estados son los de Material y no una escala inventada: el turno en
/// curso es un chip seleccionado, que se rellena con el color y lleva el número
/// encima en el contrario; el jugado es un chip deshabilitado, con las
/// opacidades que Material usa para lo que ya no responde; y el que falta es un
/// chip de contorno, que es como Material muestra lo disponible sin destacarlo.
class _TurnBox extends StatelessWidget {
  const _TurnBox({
    required this.number,
    required this.state,
    required this.ink,
    required this.surface,
    required this.isOnActiveHalf,
  });

  final int number;
  final _TurnState state;

  /// Si la casilla se pinta sobre la mitad del turno que corre, que va
  /// saturada, o sobre la que espera, que en la paleta clara es casi blanca.
  ///
  /// Decide las opacidades de lo apagado. Las de Material valen sobre la mitad
  /// activa, donde la tinta es clara sobre azul o naranja; sobre la que espera
  /// la tinta es oscura sobre casi blanco, y ahí un 12% desaparece: la fila
  /// entera se quedaba en blanco sobre blanco.
  final bool isOnActiveHalf;

  /// El color de la mitad sobre la que se pinta, ya resuelto para el modo y
  /// para si el jugador tiene el turno.
  final Color ink;

  /// El fondo de la mitad, con el que se recorta el número del chip
  /// seleccionado, que invierte.
  final Color surface;

  static const _corners = BorderRadius.all(
    Radius.circular(ClockTheme.turnBoxRadius),
  );

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == _TurnState.current;

    // Lo apagado se apaga igual en las dos mitades: lo que cambia entre ellas
    // es el relleno, no la letra.
    final dimmed = ink.withValues(alpha: ClockTheme.dimmedContentOpacity);

    final background = switch (state) {
      _TurnState.current => ink,
      _TurnState.played => ink.withValues(
        alpha: isOnActiveHalf
            ? ClockTheme.playedFillOpacity
            : ClockTheme.waitingPlayedFillOpacity,
      ),
      _TurnState.upcoming => Colors.transparent,
    };

    // Lo que apaga a cada uno no es lo mismo, porque no es lo mismo lo que
    // los sostiene. Al jugado lo apaga su relleno, que es lo que dice que está
    // gastado, y con el relleno puesto su número no necesita ir entero. Al que
    // falta no lo rellena nada: lo único que tiene es su número, así que va
    // entero y lo que se apaga es el contorno.
    //
    // Es la diferencia entre un chip deshabilitado y uno de contorno, que son
    // los dos estados que pide el ticket. Apagar los dos números por igual, que
    // es lo que decía al pie de la letra, dejaba al que falta sin nada que lo
    // sostuviera.
    final content = switch (state) {
      _TurnState.current => surface,
      _TurnState.played => dimmed,
      _TurnState.upcoming => ink,
    };

    return Material(
      color: background,
      // Cuadrado de esquinas redondeadas, no pastilla: son ocho casillas en
      // fila y el cuadrado las hace contarse de un vistazo.
      shape: state == _TurnState.upcoming
          ? RoundedRectangleBorder(
              borderRadius: _corners,
              side: BorderSide(color: dimmed),
            )
          : const RoundedRectangleBorder(borderRadius: _corners),
      elevation: isCurrent ? ClockTheme.turnBoxElevation : 0,
      shadowColor: ClockColors.of(context).controlShadow,
      child: SizedBox(
        width: ClockTheme.turnBoxWidth,
        height: ClockTheme.turnBoxHeight,
        child: Center(
          child: Text(
            '$number',
            // El estilo sale del tema y no de un tamaño suelto: es la etiqueta
            // de un chip, que en Material es `labelMedium`.
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: content,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
