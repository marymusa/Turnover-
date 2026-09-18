import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/clock_format.dart';
import '../l10n/app_localizations.dart';
import 'clock_theme.dart';

/// La mitad de un jugador: su nombre, el turno grande, la reserva debajo y la
/// barra del reloj que corre. La de arriba se gira 180 grados para que cada
/// jugador lea la suya de frente.
class PlayerHalf extends StatelessWidget {
  const PlayerHalf({
    required this.name,
    required this.onRename,
    required this.turn,
    required this.reserve,
    required this.remainingFraction,
    required this.isActive,
    required this.activeColor,
    required this.isStarted,
    required this.isUpsideDown,
    required this.isRevealed,
    required this.onTap,
    super.key,
  });

  /// El nombre ya resuelto: quien pinta es quien sabe cuál es el valor por
  /// defecto, porque está localizado.
  final String name;

  /// Abre el cambio de nombre, con una pulsación larga sobre la mitad entera.
  /// Nulo con el partido empezado: los nombres se pactan con el partido
  /// parado, y después la mitad es pasar turno y nada más, para que un dedo
  /// lento no abra un diálogo en mitad del juego.
  final VoidCallback? onRename;

  final Duration turn;
  final Duration reserve;

  /// Lo que queda del reloj que corre, entre cero y uno. Nulo si no corre
  /// ninguno: entonces no hay barra que pintar.
  final double? remainingFraction;

  final bool isActive;

  /// El color de esta mitad mientras es su turno. Lo elige quien pinta, que es
  /// quien sabe de qué jugador es la mitad: aquí no se deduce del giro, que
  /// dice hacia dónde se lee y no de quién es.
  final Color activeColor;

  final bool isStarted;
  final bool isUpsideDown;

  /// Si la presentación de la costura ya ha terminado. La invitación no sale
  /// antes: mientras el escudo se dibuja, la pantalla ya está diciendo algo.
  final bool isRevealed;
  final VoidCallback onTap;

  /// El turno a cero es lo que hace de la reserva el número principal.
  bool get _isTurnSpent => turn <= Duration.zero;

  /// El aviso al dedo va antes del diálogo, que tarda en aparecer: confirma
  /// que la pulsación ha entrado sin esperar a la animación. Sale por el canal
  /// normal del sistema, así que respeta su configuración (ADR-0005).
  void _renameWithFeedback() {
    HapticFeedback.selectionClick();
    onRename!();
  }

  @override
  Widget build(BuildContext context) {
    // Las dos mitades llevan el mismo orden. De girar la de arriba se encarga
    // el RotatedBox del final, que ya la deja leyéndose de frente desde su
    // lado de la mesa: invertir aquí además la dejaría del revés.
    final strings = AppLocalizations.of(context)!;
    final rows = <Widget>[
      // La pista de renombrar va en la misma fila que el nombre y no en una
      // propia: así aparecer y desaparecer no cambia la altura de la mitad, y
      // empezar el partido no mueve los relojes de sitio.
      _Name(
        name,
        canRename: onRename != null,
        hint: strings.renameHintShort,
        hintLong: strings.renameHintInline,
      ),
      // Encima del turno, y vacío con el partido empezado: el hueco se queda
      // igual, que es lo que impide que empezar mueva los relojes de sitio.
      SizedBox(
        height: ClockTheme.labelSlotHeight,
        child: Center(
          child: _ClockLabel(isStarted ? null : strings.turnTimeLabel),
        ),
      ),
      const SizedBox(height: ClockTheme.labelToClockGap),
      _ClockText(
        formatClock(turn),
        size: _isTurnSpent ? ClockTheme.turnSizeSpent : ClockTheme.turnSize,
      ),
      const SizedBox(height: ClockTheme.clockToSlotGap),
      // El mismo hueco para los dos: la barra con el partido en marcha y el
      // nombre del reloj antes de empezar. Fijar la altura aquí es lo que
      // hace que empezar no mueva los relojes de sitio.
      SizedBox(
        height: ClockTheme.barSlotHeight,
        child: Center(
          child: isStarted
              ? _ProgressBar(
                  remainingFraction: remainingFraction,
                  isReserve: _isTurnSpent,
                )
              : _ClockLabel(strings.extraTimeLabel),
        ),
      ),
      const SizedBox(height: ClockTheme.labelToClockGap),
      _ClockText(
        formatClock(reserve),
        size: _isTurnSpent
            ? ClockTheme.reserveSizeSpent
            : ClockTheme.reserveSize,
        color: _isTurnSpent ? ClockTheme.reserve : null,
      ),
      // La invitación cierra el bloque, debajo de los dos relojes, y late para
      // que se vea que la mitad espera un toque. Reserva su hueco también con
      // el partido empezado: sin eso, empezar mueve los relojes de sitio.
      _StartHint(
        text: strings.startHint,
        isVisible: !isStarted && isRevealed,
      ),
    ];

    final half = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: !isStarted || isActive ? 1 : ClockTheme.inactiveOpacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isActive ? activeColor : ClockTheme.inactive,
        // Ancho completo: la mitad es tocable entera, no solo donde hay números.
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: rows,
        ),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onRename == null ? null : _renameWithFeedback,
      // El fondo del contenedor ya es opaco, pero el gesto tiene que cubrir
      // la mitad entera y no solo lo que ocupan los números.
      behavior: HitTestBehavior.opaque,
      child: isUpsideDown ? RotatedBox(quarterTurns: 2, child: half) : half,
    );
  }
}

/// El nombre, encima de los relojes. No lleva gesto propio: el de la mitad lo
/// cubre entero, de modo que tocar aquí pasa turno como en cualquier otro
/// punto y la pulsación larga renombra.
class _Name extends StatelessWidget {
  const _Name(
    this.text, {
    required this.canRename,
    required this.hint,
    required this.hintLong,
  });

  final String text;

  /// Con el partido empezado no se renombra, y entonces no hay lápiz: el
  /// gesto que anuncia no existe.
  final bool canRename;

  /// La pista corta que se ve, al lado del nombre.
  final String hint;

  /// La frase entera, solo para los lectores de pantalla: la corta se apoya en
  /// el lápiz que tiene al lado, y sin verlo no se entiende sola.
  final String hintLong;

  @override
  Widget build(BuildContext context) {
    final label = Flexible(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: ClockTheme.nameSize,
          fontWeight: FontWeight.w600,
          color: ClockTheme.text.withValues(alpha: 0.75),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        // La fila se ciñe al nombre en vez de ocupar el ancho entero: así el
        // lápiz queda pegado a él y no en el borde de la pantalla.
        mainAxisSize: MainAxisSize.min,
        children: [
          label,
          if (canRename) ...[
            const SizedBox(width: 8),
            // El lápiz y la pista se leen juntos, y de una vez: por separado
            // un lector de pantalla diría dos cosas para un solo gesto.
            Semantics(
              label: hintLong,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: ClockTheme.renameIconSize,
                    color: ClockTheme.text.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hint,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: ClockTheme.renameHintSize,
                      fontWeight: FontWeight.w500,
                      color: ClockTheme.text.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// La invitación a empezar, latiendo despacio debajo de los relojes.
///
/// Late con [ScaleTransition] y no cambiando el cuerpo de la letra: escalar
/// solo repinta, mientras que agrandar el texto rehace la medida y empujaría a
/// los relojes en cada fotograma.
///
/// Con el partido empezado no se pinta, pero su hueco se queda: el texto se
/// sustituye por uno transparente del mismo tamaño, de modo que la mitad mide
/// igual antes y después y empezar no mueve nada de sitio.
class _StartHint extends StatefulWidget {
  const _StartHint({required this.text, required this.isVisible});

  final String text;
  final bool isVisible;

  @override
  State<_StartHint> createState() => _StartHintState();
}

class _StartHintState extends State<_StartHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _scale = Tween(begin: 1.0, end: 1.12).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _controller.repeat(reverse: true);
  }

  /// El latido solo corre mientras se ve. Parado, el controlador no despierta
  /// a nadie en cada fotograma.
  @override
  void didUpdateWidget(_StartHint old) {
    super.didUpdateWidget(old);
    if (widget.isVisible == old.isVisible) return;
    if (widget.isVisible) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = Text(
      widget.text,
      style: TextStyle(
        fontSize: ClockTheme.startHintSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: widget.isVisible
            ? ClockTheme.text
            : ClockTheme.text.withValues(alpha: 0),
      ),
    );

    // Simétrico y no solo por arriba: la mitad de arriba va girada, y un
    // margen de un solo lado le queda del lado contrario, pegando el texto al
    // reloj de reserva. El hueco que deja el escalado entra en esta medida.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: widget.isVisible
          ? ScaleTransition(scale: _scale, child: label)
          : label,
    );
  }
}


class _ClockText extends StatelessWidget {
  const _ClockText(this.text, {required this.size, this.color});

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 0.95,
        letterSpacing: -0.03 * size,
        color: color ?? ClockTheme.text,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      child: Text(text),
    );
  }
}

/// Nombra el reloj que tiene al lado mientras el partido no ha empezado, que
/// es cuando hay tiempo de leerlo. Empezado, el nombre sobra y el hueco se
/// queda vacío: quien juega ya sabe qué mira, y la mitad no puede cambiar de
/// altura por eso.
///
/// Con [text] nulo no pinta nada y solo ocupa su sitio, que es como se reserva
/// el hueco sin decir nada.
class _ClockLabel extends StatelessWidget {
  const _ClockLabel(this.text);

  final String? text;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    if (text == null) return const SizedBox.shrink();
    return Text(
      text,
      style: TextStyle(
        fontSize: ClockTheme.clockLabelSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: ClockTheme.text.withValues(alpha: 0.45),
      ),
    );
  }
}

/// Una sola barra por mitad, la del reloj que está corriendo. Antes de empezar
/// no la pinta nadie: en su hueco va [_ExtraTimeLabel].
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.remainingFraction,
    required this.isReserve,
  });

  final double? remainingFraction;
  final bool isReserve;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: ClockTheme.barWidthFactor,
      child: Container(
        height: ClockTheme.barHeight,
        decoration: BoxDecoration(
          color: ClockTheme.text.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(ClockTheme.barHeight / 2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: remainingFraction ?? 0,
          child: Container(
            decoration: BoxDecoration(
              color: isReserve ? ClockTheme.reserve : ClockTheme.text,
              borderRadius: BorderRadius.circular(ClockTheme.barHeight / 2),
            ),
          ),
        ),
      ),
    );
  }
}
