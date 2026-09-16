import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'clock_theme.dart';

/// Pide confirmación antes de reiniciar. Devuelve `true` solo si se confirma:
/// cerrar el diálogo por cualquier otro camino es no reiniciar.
///
/// Describe la consecuencia en vez de preguntar a secas, porque reiniciar
/// pierde el partido en curso y eso no se deshace.
Future<bool> askToReset(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => const _ResetDialog(),
  );
  return confirmed ?? false;
}

class _ResetDialog extends StatelessWidget {
  const _ResetDialog();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: ClockTheme.inactive,
      title: Text(
        strings.resetTitle,
        style: const TextStyle(color: ClockTheme.text),
      ),
      content: Text(
        strings.resetBody,
        style: TextStyle(color: ClockTheme.text.withValues(alpha: 0.75)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(strings.resetConfirm),
        ),
      ],
    );
  }
}
