/// Sacar el acta de la aplicación. La regla de qué se comparte vive en la
/// pantalla, que es quien sabe pintarla; aquí solo está el agujero por el que
/// salen los bytes.
library;

import 'dart:typed_data';

/// Por donde el acta sale del teléfono. La implementación real abre el menú
/// de compartir del sistema; en los tests se sustituye por una que solo
/// apunta lo que le piden, igual que [Screen] y [AlertDevice].
///
/// Recibe la imagen ya hecha y no el acta: quién la pinta y con qué aspecto
/// es cosa de la pantalla, y este puerto no tiene por qué saber que lo que
/// comparte es un acta de Blood Bowl.
abstract interface class ReportSharer {
  /// Comparte [png] con el nombre de fichero [name]. [text] acompaña a la
  /// imagen donde el destino lo admita.
  ///
  /// No dice si el jugador llegó a compartir o se echó atrás, y no hace
  /// falta: la aplicación no cambia de estado por ello, porque el acta sigue
  /// en pantalla y el partido sigue terminado.
  Future<void> share(Uint8List png, {required String name, String? text});
}
