import 'package:flutter/material.dart';

import 'clock_colors.dart';
import 'clock_theme.dart';

/// Un control redondo y discreto, el de las operaciones que acompañan al
/// partido sin ser el gesto principal: pausar, reiniciar, abrir los ajustes.
///
/// Es un botón de Material, con su superficie y su sombra: lo que lo separa de
/// la pantalla es la elevación, como en cualquier botón redondo del sistema.
/// Pintado plano y con una tinta sobre el fondo se leía como una mancha pegada
/// encima, sobre todo en la paleta clara.
///
/// Lo que manda en la costura sigue siendo pasar turno, y a estos los distingue
/// el tamaño, no estar medio borrados.
class AdvancedControl extends StatelessWidget {
  const AdvancedControl({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isHighlighted = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// Solo lo enciende el control de pausa mientras está pausado.
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: isHighlighted ? colors.paused : colors.controlSurface,
        shape: const CircleBorder(),
        elevation: ClockTheme.controlElevation,
        shadowColor: colors.controlShadow,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: ClockTheme.advancedSize,
            child: Icon(
              icon,
              size: ClockTheme.advancedIconSize,
              color: isHighlighted ? colors.text : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
