import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'clock_colors.dart';
import 'clock_theme.dart';
import 'touch_feedback.dart';

/// El velo que cubre la pantalla con el partido pausado. Dice por qué está
/// puesto y cómo se quita, tocarlo en cualquier sitio reanuda, y lleva además
/// el botón que declara un Time-Out.
///
/// Va por delante de las dos mitades a propósito: así el toque no les llega y
/// reanudar no se confunde nunca con pasar turno, que es el mismo gesto sobre
/// la misma mitad. La pantalla decide cuándo se pinta.
class PausedVeil extends StatelessWidget {
  const PausedVeil({
    required this.onResume,
    required this.onTimeOut,
    this.status,
    super.key,
  });

  final VoidCallback onResume;

  /// Declara un Time-Out: quita la pausa y aplica la regla. El velo es donde
  /// los jugadores ya están, porque paran el reloj para desplegar y la tirada
  /// de la patada inicial es posterior (ADR-0010).
  final VoidCallback onTimeOut;

  /// Por qué está puesto el velo, ya traducido. Nulo es la pausa a secas, que
  /// es la que se pide a mano desde la costura.
  ///
  /// Lo pone quien pausa y no se deduce aquí: el velo no conoce la cuenta, y
  /// desde ella el parón del cambio de parte no se distingue de una pausa
  /// cualquiera hecha a media jugada del turno 9.
  final String? status;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = ClockColors.of(context);
    final statusText = status ?? strings.paused;
    // Uno solo para los dos sitios que reanudan. El nodo de semántica y el
    // gesto declaran la misma acción por caminos distintos, y un toque entra
    // por uno o por otro, nunca por los dos: compartir la función es lo que
    // garantiza que el tacto salga una vez y no dos.
    void resumeWithFeedback() {
      TouchFeedback.clockToggled();
      onResume();
    }

    // Las dos filas se escriben igual: son la misma frase partida en dos, y lo
    // que las separa es el hueco, no el tamaño.
    final textStyle = TextStyle(
      color: colors.veilText,
      fontSize: ClockTheme.veilTextSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
    return Semantics(
      button: true,
      // El estado por delante: quien no ve el velo tiene que oír lo mismo que
      // se lee en él, primero por qué está puesto y después qué hace tocarlo.
      label: '$statusText. ${strings.resume}',
      // Con nodo propio y los de dentro aparte. Sin esto, la etiqueta se traga
      // todo lo que el velo escribe y se anuncia como "Segunda parte.
      // Reanudar. Segunda parte. Pulsa en cualquier sitio para continuar.
      // Evento de patada inicial", que es la frase entera dos veces y el
      // encabezado del botón suelto en medio. El botón de Time-Out y lo que lo
      // encabeza se quedan donde estaban, cada uno con su nodo.
      explicitChildNodes: true,
      // La acción la declara el velo y no el gesto: cerrado el nodo, el
      // `GestureDetector` se hacía uno suyo, se llevaba el toque fuera del
      // botón anunciado y de paso se quedaba con el encabezado del Time-Out
      // de etiqueta.
      onTap: resumeWithFeedback,
      child: GestureDetector(
        onTap: resumeWithFeedback,
        excludeFromSemantics: true,
        // Opaco al toque también donde el velo es transparente: lo que cubre
        // lo cubre entero.
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          // Translúcido, no opaco: los dos relojes se siguen leyendo mientras
          // se habla de la jugada, que es para lo que se pausa.
          color: colors.background.withValues(alpha: colors.veilOpacity),
          // El aviso y el botón arrancan por debajo de la costura y crecen
          // hacia abajo, y se leen derechos desde el lado del jugador uno: es
          // el que tiene el móvil de cara.
          //
          // Lo que se fija es dónde empieza el bloque, no cuánto se aparta uno
          // centrado: centrado, la mitad de lo que mida sube por encima del
          // centro, de modo que añadirle el botón devolvía el aviso encima de
          // la costura, que es justo lo que este hueco evita.
          //
          // La costura está en el centro del velo, así que el bloque arranca
          // media pantalla más abajo y, encima, lo que la costura ocupa hacia
          // abajo desde su centro.
          child: LayoutBuilder(
            builder: (context, constraints) => Padding(
              padding: EdgeInsets.only(
                top: constraints.maxHeight / 2 + ClockTheme.veilContentTop,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dos filas y no una frase: arriba por qué el reloj no
                  // corre, que cambia, y debajo qué hacer con el velo, que es
                  // siempre lo mismo.
                  //
                  // Fuera de la semántica las dos: es lo mismo que ya dice la
                  // etiqueta del velo, que es el nodo sobre el que se cae, y
                  // repetido serían tres nodos para una frase.
                  ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusText,
                          textAlign: TextAlign.center,
                          style: textStyle,
                        ),
                        const SizedBox(height: ClockTheme.veilStatusGap),
                        Text(
                          strings.continueHint,
                          textAlign: TextAlign.center,
                          style: textStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ClockTheme.veilButtonGap),
                  // El botón no se explica solo: "Tiempo muerto" a secas se
                  // lee como pausar, que es justo lo que el velo ya es. Lo que
                  // dice de qué va es la tabla de la que sale.
                  Text(
                    strings.kickOffEvent,
                    style: TextStyle(
                      color: colors.veilText.withValues(alpha: 0.6),
                      fontSize: ClockTheme.veilLabelSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: ClockTheme.veilLabelGap),
                  _TimeOutButton(
                    label: strings.timeOut,
                    // Sin tacto: abre un diálogo y no aplica la regla. Quien
                    // responde es el botón de confirmar.
                    onPressed: onTimeOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El botón que declara un Time-Out, dentro del velo.
///
/// Se come su propio toque, que es lo que lo distingue del velo que tiene
/// debajo: sin eso, pulsarlo reanudaría sin aplicar la regla, porque el velo
/// entero reanuda al tocarlo en cualquier sitio.
///
/// Lleva texto y no icono: es el nombre del reglamento, y ningún icono dice
/// "Time-Out" sin que haya que aprendérselo. Delante va el 3, que es el
/// resultado con el que sale en la tabla: quien se sabe la tabla lo reconoce
/// sin leer, y quien no, lee el nombre que tiene al lado.
class _TimeOutButton extends StatelessWidget {
  const _TimeOutButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    return Material(
      color: colors.controlSurface,
      shape: const StadiumBorder(),
      elevation: ClockTheme.controlElevation,
      shadowColor: colors.controlShadow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClockTheme.veilButtonHorizontalPadding,
            vertical: ClockTheme.veilButtonVerticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // El resultado de la tabla, no un número cualquiera: va en su
              // propia ficha para que se lea como la cara de un dado y no como
              // parte del nombre.
              ExcludeSemantics(
                child: _ResultBadge(
                  result: '3',
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(width: ClockTheme.veilBadgeGap),
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: ClockTheme.veilButtonTextSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El resultado de la tabla, en un cuadrado de esquinas redondeadas como las
/// casillas de la cuenta: en esta pantalla un número dentro de un cuadrado ya
/// significa "una casilla de la tabla", y esto se apoya en eso.
class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.result, required this.color});

  final String result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ClockTheme.veilBadgeSize,
      height: ClockTheme.veilBadgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: ClockTheme.veilBadgeFillOpacity),
        borderRadius: BorderRadius.circular(ClockTheme.turnBoxRadius),
      ),
      child: Text(
        result,
        style: TextStyle(
          color: color,
          fontSize: ClockTheme.veilBadgeTextSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
