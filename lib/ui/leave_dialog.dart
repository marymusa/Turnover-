import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'clock_colors.dart';

/// Pide confirmación antes de salir del partido. Devuelve `true` solo si se
/// confirma: cerrar el diálogo por cualquier otro camino es quedarse.
///
/// Salir no reinicia nada, termina la aplicación, y lo que se pierde se pierde
/// porque el partido en curso no se guarda en ninguna parte (ADR-0003).
Future<bool> askToLeave(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => const _LeaveDialog(),
  );
  return confirmed ?? false;
}

class _LeaveDialog extends StatelessWidget {
  const _LeaveDialog();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = ClockColors.of(context);
    return AlertDialog(
      backgroundColor: colors.dialogSurface,
      title: Text(
        strings.leaveTitle,
        style: TextStyle(color: colors.onSurface),
      ),
      content: Text(
        strings.leaveBody,
        style: TextStyle(color: colors.onSurface.withValues(alpha: 0.75)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(strings.leaveConfirm),
        ),
      ],
    );
  }
}
