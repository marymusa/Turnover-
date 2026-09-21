import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'clock_colors.dart';
import 'touch_feedback.dart';

/// Pide confirmación antes de aplicar un Time-Out. Devuelve `true` solo si se
/// confirma: cerrar el diálogo por cualquier otro camino es no aplicarlo.
///
/// Describe la consecuencia en vez de preguntar a secas, igual que el de
/// reiniciar y por lo mismo: mueve las dos cuentas y no hay forma de deshacerlo
/// desde la aplicación.
///
/// Dice además hacia dónde se mueven, que es lo que el jugador va a comprobar
/// contra su ficha. La dirección la decide el turno de tablero del pateador
/// (ADR-0010) y la resuelve el dominio, no esta pantalla: quien pregunta no
/// puede deducir por su cuenta lo que luego hace la regla.
Future<bool> askToApplyTimeOut(
  BuildContext context, {
  required bool retreats,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _TimeOutDialog(retreats: retreats),
  );
  return confirmed ?? false;
}

class _TimeOutDialog extends StatelessWidget {
  const _TimeOutDialog({required this.retreats});

  /// Si las dos cuentas van a retroceder. Lo contrario es avanzar: no hay un
  /// tercer caso, porque la regla se aplica sin topes.
  final bool retreats;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = ClockColors.of(context);
    return AlertDialog(
      backgroundColor: colors.dialogSurface,
      title: Text(
        strings.timeOutTitle,
        style: TextStyle(color: colors.onSurface),
      ),
      content: Text(
        retreats ? strings.timeOutBackBody : strings.timeOutForwardBody,
        style: TextStyle(color: colors.onSurface.withValues(alpha: 0.75)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () {
            TouchFeedback.confirmed();
            Navigator.of(context).pop(true);
          },
          child: Text(strings.timeOutConfirm),
        ),
      ],
    );
  }
}
