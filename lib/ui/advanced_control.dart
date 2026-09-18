import 'package:flutter/material.dart';

import 'clock_colors.dart';
import 'clock_theme.dart';

/// Un control redondo y discreto, el de las operaciones que acompañan al
/// partido sin ser el gesto principal: pausar, reiniciar, abrir los ajustes.
///
/// Va apagado a propósito. Lo que manda en la costura es pasar turno, y estos
/// se tienen que encontrar sin disputárselo.
class AdvancedControl extends StatelessWidget {
  const AdvancedControl({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isHighlighted = false,
    this.isAlone = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// Solo lo enciende el control de pausa mientras está pausado.
  final bool isHighlighted;

  /// Si el control no tiene a nadie al lado. En la costura son tres y se
  /// explican entre ellos; suelto, apagado se lee como deshabilitado, así que
  /// sube de tono hasta que se ve que se puede pulsar.
  final bool isAlone;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: isHighlighted
            ? colors.paused
            : colors.onSurface.withValues(
                alpha: isAlone
                    ? colors.advancedAloneFillAlpha
                    : colors.advancedFillAlpha,
              ),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: ClockTheme.advancedSize,
            child: Icon(
              icon,
              size: ClockTheme.advancedIconSize,
              color: isHighlighted
                  ? colors.text
                  : colors.onSurface.withValues(
                      alpha: isAlone
                          ? colors.advancedAloneIconAlpha
                          : colors.advancedIconAlpha,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
