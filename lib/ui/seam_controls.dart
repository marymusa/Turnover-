import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'advanced_control.dart';
import 'clock_colors.dart';
import 'clock_theme.dart';

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
          onPressed: onTogglePause,
          isHighlighted: isPaused,
        ),
        const SizedBox(width: ClockTheme.seamGap),
        _PassTurnControl(
          label: strings.passTurn,
          // Pausar bloquea pasar turno, también desde las mitades.
          onPressed: isPaused ? null : onPassTurn,
        ),
        const SizedBox(width: ClockTheme.seamGap),
        AdvancedControl(
          icon: Icons.refresh,
          label: strings.reset,
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
          color: colors.onSurface.withValues(alpha: 0.16),
          shape: CircleBorder(
            side: BorderSide(
              color: colors.onSurface.withValues(alpha: 0.22),
              width: 2,
            ),
          ),
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
