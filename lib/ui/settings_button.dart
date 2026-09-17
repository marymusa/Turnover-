import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'clock_theme.dart';

/// El acceso a los ajustes, en una esquina. Solo se pinta antes de empezar:
/// quién lo decide es la pantalla, no este widget.
///
/// Lleva el nombre escrito al lado del icono, y los dos a plena opacidad. El
/// icono solo, y apagado, no se encontraba, y la esquina antes de empezar está
/// vacía: no hay nada a lo que quitarle protagonismo.
class SettingsButton extends StatelessWidget {
  const SettingsButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    // Aquí no hace falta Semantics: el botón ya se anuncia con el nombre que
    // lleva escrito. Añadirlo encima duplicaba la etiqueta.
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.settings, size: ClockTheme.advancedIconSize),
      label: Text(
        strings.settings,
        style: const TextStyle(fontSize: ClockTheme.settingsLabelSize),
      ),
      style: TextButton.styleFrom(
        foregroundColor: ClockTheme.text,
        iconColor: ClockTheme.text,
      ),
    );
  }
}
