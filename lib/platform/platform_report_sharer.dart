/// El adaptador que saca el acta por el menú de compartir del sistema. Nada
/// del dominio entra aquí: recibe unos bytes y los entrega.
library;

import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import '../domain/report_sharer.dart';

class PlatformReportSharer implements ReportSharer {
  const PlatformReportSharer();

  @override
  Future<void> share(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    // Los bytes van directos y no por un fichero nuestro: `XFile.fromData`
    // deja que sea el propio complemento quien escriba el temporal donde el
    // sistema espera encontrarlo. Lo que la aplicación no hace es guardar el
    // acta en ninguna parte suya (ADR-0003): ese temporal es del sistema de
    // compartir y se lo lleva él.
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [XFile.fromData(png, mimeType: 'image/png', name: name)],
        fileNameOverrides: [name],
      ),
    );
  }
}
