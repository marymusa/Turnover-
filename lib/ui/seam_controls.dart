import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'advanced_control.dart';
import 'clock_colors.dart';
import 'clock_theme.dart';
import 'touch_feedback.dart';

/// La costura entre las dos mitades: pasar turno en el centro y, discretos a
/// los lados, pausar y reiniciar, que son operaciones avanzadas.
///
/// Antes de empezar no hay costura, así que esto no se pinta: la pantalla
/// decide cuándo mostrarla.
class SeamControls extends StatelessWidget {
  const SeamControls({
    required this.isPaused,
    required this.onPassTurn,
    required this.onTogglePause,
    required this.onReset,
    super.key,
  });

  final bool isPaused;
  final VoidCallback onPassTurn;
  final VoidCallback onTogglePause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AdvancedControl(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          label: isPaused ? strings.resume : strings.pause,
          onPressed: () {
            TouchFeedback.clockToggled();
            onTogglePause();
          },
          isHighlighted: isPaused,
        ),
        const SizedBox(width: ClockTheme.seamGap),
        _PassTurnControl(
          label: strings.passTurn,
          // Pausar bloquea pasar turno, también desde las mitades. Bloqueado
          // no responde al dedo: Flutter no expone la háptica de rechazo que
          // sí tiene Android, y fingirla con un golpe normal diría justo lo
          // contrario de lo que ha pasado (ADR-0014).
          onPressed: isPaused
              ? null
              : () {
                  TouchFeedback.turnPassed();
                  onPassTurn();
                },
        ),
        const SizedBox(width: ClockTheme.seamGap),
        AdvancedControl(
          icon: Icons.refresh,
          label: strings.reset,
          // Sin tacto: esto abre un diálogo y no reinicia nada. El peso lo
          // lleva el botón de confirmar, que es el que destruye el partido.
          onPressed: onReset,
        ),
      ],
    );
  }
}

/// Rotacionalmente simétrico: el icono se lee igual desde los dos lados de la
/// mesa, que es la razón de que sea este y no una flecha suelta.
class _PassTurnControl extends StatelessWidget {
  const _PassTurnControl({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Opacity(
        opacity: onPressed == null ? 0.25 : 1,
        child: Material(
          color: colors.controlSurface,
          shape: const CircleBorder(),
          // Pasar turno va más levantado que los otros dos: es el gesto
          // principal, y en Material la altura es lo que lo dice.
          elevation: ClockTheme.passTurnElevation,
          shadowColor: colors.controlShadow,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: ClockTheme.passTurnSize,
              child: Icon(
                Icons.swap_vert,
                size: ClockTheme.passTurnIconSize,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
