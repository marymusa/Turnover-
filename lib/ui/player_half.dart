import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/clock_format.dart';
import '../l10n/app_localizations.dart';
import 'clock_colors.dart';
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
    // Las dos mitades no comparten fondo: la activa lleva el color de su turno
    // en las dos paletas y la que espera se aclara con la luz. Por eso lo que
    // se pinta dentro elige letra y aviso según `isActive`.
    final colors = ClockColors.of(context);
    final rows = <Widget>[
      // La pista de renombrar va en la misma fila que el nombre y no en una
      // propia: así aparecer y desaparecer no cambia la altura de la mitad, y
      // empezar el partido no mueve los relojes de sitio.
      _Name(
        name,
        canRename: onRename != null,
        hint: strings.renameHintShort,
        hintLong: strings.renameHintInline,
        isActive: isActive,
      ),
      // Encima del turno, y vacío con el partido empezado: el hueco se queda
      // igual, que es lo que impide que empezar mueva los relojes de sitio.
      SizedBox(
        height: ClockTheme.labelSlotHeight,
        child: Center(
          child: _ClockLabel(
            isStarted ? null : strings.turnTimeLabel,
            isActive: isActive,
          ),
        ),
      ),
      const SizedBox(height: ClockTheme.labelToClockGap),
      _ClockText(
        formatClock(turn),
        size: _isTurnSpent ? ClockTheme.turnSizeSpent : ClockTheme.turnSize,
        isActive: isActive,
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
                  isActive: isActive,
                )
              : _ClockLabel(strings.extraTimeLabel, isActive: isActive),
        ),
      ),
      const SizedBox(height: ClockTheme.labelToClockGap),
      _ClockText(
        formatClock(reserve),
        size: _isTurnSpent
            ? ClockTheme.reserveSizeSpent
            : ClockTheme.reserveSize,
        color: _isTurnSpent
            ? (isActive ? colors.reserve : colors.inactiveReserve)
            : null,
        isActive: isActive,
      ),
      // La invitación cierra el bloque, debajo de los dos relojes, y late para
      // que se vea que la mitad espera un toque. Reserva su hueco también con
      // el partido empezado: sin eso, empezar mueve los relojes de sitio.
      _StartHint(
        text: strings.startHint,
        isVisible: !isStarted && isRevealed,
        isActive: isActive,
      ),
    ];

    // Sin velo de opacidad encima: al jugador que espera ya lo distingue su
    // color, que ahora es el suyo y no el de la mitad activa apagada.
    final half = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // Arriba y abajo va la mitad que a los lados: en la costura las dos
      // tarjetas suman sus márgenes y el hueco sale igual que el de los lados.
      margin: const EdgeInsets.symmetric(
        horizontal: ClockTheme.halfCardInset,
        vertical: ClockTheme.halfCardVerticalInset,
      ),
      decoration: BoxDecoration(
        color: isActive ? activeColor : colors.inactive,
        borderRadius: BorderRadius.circular(ClockTheme.halfCardRadius),
        border: Border.all(
          color: colors.halfCardBorder,
          width: ClockTheme.halfCardBorderWidth,
        ),
      ),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rows,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onRename == null ? null : _renameWithFeedback,
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
    required this.isActive,
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

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    final textColor = isActive ? colors.activeText : colors.text;

    final label = Flexible(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: ClockTheme.nameSize,
          fontWeight: FontWeight.w600,
          color: textColor.withValues(alpha: 0.75),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          label,
          if (canRename) ...[
            const SizedBox(width: 8),
            Semantics(
              label: hintLong,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: ClockTheme.renameIconSize,
                    color: textColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hint,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: ClockTheme.renameHintSize,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.4),
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
class _StartHint extends StatefulWidget {
  const _StartHint({
    required this.text,
    required this.isVisible,
    required this.isActive,
  });

  final String text;
  final bool isVisible;
  final bool isActive;

  @override
  State<_StartHint> createState() => _StartHintState();
}

class _StartHintState extends State<_StartHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _scale = Tween(
    begin: 1.0,
    end: 1.12,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _controller.repeat(reverse: true);
  }

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
    final colors = ClockColors.of(context);
    final textColor = widget.isActive ? colors.activeText : colors.text;

    final label = Text(
      widget.text,
      style: TextStyle(
        fontSize: ClockTheme.startHintSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: widget.isVisible ? textColor : textColor.withValues(alpha: 0),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: widget.isVisible
          ? ScaleTransition(scale: _scale, child: label)
          : label,
    );
  }
}

class _ClockText extends StatelessWidget {
  const _ClockText(
    this.text, {
    required this.size,
    required this.isActive,
    this.color,
  });

  final String text;
  final double size;
  final bool isActive;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    final textColor = isActive ? colors.activeText : colors.text;

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 200),
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 0.95,
        letterSpacing: -0.03 * size,
        color: color ?? textColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      child: Text(text),
    );
  }
}

/// Nombra el reloj que tiene al lado mientras el partido no ha empezado.
class _ClockLabel extends StatelessWidget {
  const _ClockLabel(this.text, {required this.isActive});

  final String? text;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    if (text == null) return const SizedBox.shrink();
    final colors = ClockColors.of(context);
    final textColor = isActive ? colors.activeText : colors.text;

    return Text(
      text,
      style: TextStyle(
        fontSize: ClockTheme.clockLabelSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: textColor.withValues(alpha: 0.45),
      ),
    );
  }
}

/// Una sola barra por mitad, la del reloj que está corriendo.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.remainingFraction,
    required this.isReserve,
    required this.isActive,
  });

  final double? remainingFraction;
  final bool isReserve;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    final barColor = isActive ? colors.activeText : colors.text;
    // El aviso del turno agotado tiene su color por mitad, igual que la letra:
    // las dos dejaron de compartir fondo.
    final reserveColor = isActive ? colors.reserve : colors.inactiveReserve;
    return FractionallySizedBox(
      widthFactor: ClockTheme.barWidthFactor,
      child: Container(
        height: ClockTheme.barHeight,
        decoration: BoxDecoration(
          color: barColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(ClockTheme.barHeight / 2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: remainingFraction ?? 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isReserve ? reserveColor : barColor,
              borderRadius: BorderRadius.circular(ClockTheme.barHeight / 2),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: _BarGlow(color: isReserve ? reserveColor : barColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// La brasa que va en la cabeza de la barra mientras el reloj corre.
class _BarGlow extends StatefulWidget {
  const _BarGlow({required this.color});

  final Color color;

  @override
  State<_BarGlow> createState() => _BarGlowState();
}

class _BarGlowState extends State<_BarGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ClockTheme.barGlowDuration,
  )..repeat(reverse: true);

  late final Animation<double> _glow = Tween(
    begin: ClockTheme.barGlowMinAlpha,
    end: ClockTheme.barGlowMaxAlpha,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: ClockTheme.barHeight,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _glow.value),
                  blurRadius: ClockTheme.barGlowBlur,
                  spreadRadius: ClockTheme.barGlowSpread,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
