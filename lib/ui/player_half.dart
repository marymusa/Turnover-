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
    required this.isStarted,
    required this.isUpsideDown,
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
  final bool isStarted;
  final bool isUpsideDown;
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
      _Name(name),
      // La pista de renombrar va atada al nombre y sigue a quien de verdad
      // ofrece el gesto: `onRename` es nulo con el partido empezado, y
      // entonces no hay nada que sugerir.
      if (onRename != null) _RenameHint(strings.renameHintInline),
      _ClockText(
        formatClock(turn),
        size: _isTurnSpent ? ClockTheme.turnSizeSpent : ClockTheme.turnSize,
      ),
      const SizedBox(height: 12),
      _ProgressBar(
        remainingFraction: remainingFraction,
        isReserve: _isTurnSpent,
      ),
      const SizedBox(height: 14),
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
      _StartHint(text: strings.startHint, isVisible: !isStarted),
    ];

    final half = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: !isStarted || isActive ? 1 : ClockTheme.inactiveOpacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isActive ? ClockTheme.active : ClockTheme.inactive,
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
  const _Name(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
        fontSize: 11,
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

/// La pista de que el nombre se cambia con una pulsación larga. Va pegada al
/// nombre y más apagada que él: es una ayuda para la primera vez, no algo que
/// haya que leer en cada partida.
class _RenameHint extends StatelessWidget {
  const _RenameHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: ClockTheme.text.withValues(alpha: 0.4),
        ),
      ),
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

/// Una sola barra por mitad, la del reloj que está corriendo. Con el partido
/// parado se queda el carril vacío, para que la mitad no cambie de altura.
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
