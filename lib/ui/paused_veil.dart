import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'clock_colors.dart';
import 'clock_theme.dart';

/// El velo que cubre la pantalla con el partido pausado. Tocarlo en cualquier
/// sitio reanuda.
///
/// Va por delante de las dos mitades a propósito: así el toque no les llega y
/// reanudar no se confunde nunca con pasar turno, que es el mismo gesto sobre
/// la misma mitad. La pantalla decide cuándo se pinta.
class PausedVeil extends StatelessWidget {
  const PausedVeil({required this.onResume, super.key});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = ClockColors.of(context);
    return Semantics(
      button: true,
      label: strings.resume,
      child: GestureDetector(
        onTap: onResume,
        // Opaco al toque también donde el velo es transparente: lo que cubre
        // lo cubre entero.
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          // Translúcido, no opaco: los dos relojes se siguen leyendo mientras
          // se habla de la jugada, que es para lo que se pausa.
          color: colors.background.withValues(alpha: colors.veilOpacity),
          // El aviso baja para no caer sobre la costura, y se lee derecho
          // desde el lado del jugador uno: es el que tiene el móvil de cara.
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(
                top: ClockTheme.veilTextOffset * 2,
              ),
              child: Text(
                strings.pausedHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.veilText,
                  fontSize: ClockTheme.veilTextSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
