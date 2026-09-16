import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'clock_theme.dart';

/// El acceso a los ajustes, discreto y en una esquina. Solo se pinta antes de
/// empezar: quién lo decide es la pantalla, no este widget.
class SettingsButton extends StatelessWidget {
  const SettingsButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: strings.settings,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.tune, size: ClockTheme.advancedIconSize),
        color: ClockTheme.text.withValues(alpha: 0.55),
      ),
    );
  }
}
