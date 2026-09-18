import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'advanced_control.dart';

/// El acceso a los ajustes, en la costura y al lado del escudo. Solo se pinta
/// antes de empezar: quién lo decide es la pantalla, no este widget.
///
/// Va en la costura y no en una esquina desde que las mitades viven dentro de
/// tarjetas: pegado arriba a la derecha caía sobre la tarjeta del rival y
/// parecía suyo. En el centro no es de nadie, que es lo que es.
///
/// Solo el icono, y con la misma forma que los controles de la costura: es una
/// operación del mismo tipo que pausar o reiniciar, y se lee antes como parte
/// de un juego de botones que como una etiqueta suelta.
class SettingsButton extends StatelessWidget {
  const SettingsButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AdvancedControl(
      icon: Icons.settings,
      label: strings.settings,
      onPressed: onPressed,
      isAlone: true,
    );
  }
}
