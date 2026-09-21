import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'clock_colors.dart';
import 'touch_feedback.dart';

/// Pide el nombre nuevo de un jugador. Devuelve lo escrito, o nulo si se
/// cancela: borrar el campo entero devuelve la cadena vacía, que para quien
/// guarda los nombres es volver al valor por defecto.
///
/// Un diálogo y no edición en línea porque la mitad de arriba se pinta girada
/// 180 grados y el teclado del sistema nunca lo está.
Future<String?> askForName(BuildContext context, {required String? current}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _RenameDialog(current: current),
  );
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.current});

  final String? current;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _field = TextEditingController(
    text: widget.current,
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  /// Guardar, tanto por el botón como por la tecla de hecho del teclado. El
  /// tacto va aquí y no en el botón para que los dos caminos respondan igual.
  void _submit() {
    TouchFeedback.accepted();
    Navigator.of(context).pop(_field.text);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = ClockColors.of(context);
    return AlertDialog(
      backgroundColor: colors.dialogSurface,
      title: Text(strings.rename, style: TextStyle(color: colors.onSurface)),
      content: TextField(
        controller: _field,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        maxLength: maxNameLength,
        style: TextStyle(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: strings.renameHint,
          hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
          counterText: '',
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.active),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        TextButton(onPressed: _submit, child: Text(strings.save)),
      ],
    );
  }
}

/// Lo que cabe en una mitad sin empujar los relojes. No es una regla del
/// dominio: solo evita que un nombre largo rompa la pantalla.
const maxNameLength = 18;
