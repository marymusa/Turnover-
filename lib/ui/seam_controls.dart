import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
  /// Nulo mientras el reinicio no esté cableado: el control se pinta igual,
  /// porque la costura tiene que quedar centrada desde el primer día.
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AdvancedControl(
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
        _AdvancedControl(
          icon: Icons.refresh,
          label: strings.reset,
          onPressed: onReset,
          isHighlighted: false,
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
    return Semantics(
      button: true,
      label: label,
      child: Opacity(
        opacity: onPressed == null ? 0.25 : 1,
        child: Material(
          color: ClockTheme.text.withValues(alpha: 0.16),
          shape: CircleBorder(
            side: BorderSide(
              color: ClockTheme.text.withValues(alpha: 0.22),
              width: 2,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const SizedBox.square(
              dimension: ClockTheme.passTurnSize,
              child: Icon(
                Icons.swap_vert,
                size: ClockTheme.passTurnIconSize,
                color: ClockTheme.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdvancedControl extends StatelessWidget {
  const _AdvancedControl({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isHighlighted,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: isHighlighted
            ? ClockTheme.paused
            : ClockTheme.text.withValues(alpha: 0.07),
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
                  ? ClockTheme.text
                  : ClockTheme.text.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}
