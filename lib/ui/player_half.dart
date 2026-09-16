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
          children: [
            _Name(name),
            if (!isStarted) _Hint(AppLocalizations.of(context)!.startHint),
            _ClockText(
              formatClock(turn),
              size: _isTurnSpent
                  ? ClockTheme.turnSizeSpent
                  : ClockTheme.turnSize,
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
          ],
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

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: ClockTheme.text,
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
