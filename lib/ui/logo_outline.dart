import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// El contorno del escudo, en coordenadas de cero a uno sobre el lado mayor.
///
/// Lo genera `scripts/trace_logo_outline.py` a partir del PNG y se lee ya
/// hecho: recorrer la silueta en el arranque costaría más que leer el
/// resultado, y el escudo no cambia entre ejecuciones.
class LogoOutline {
  const LogoOutline(this.points);

  /// Los vértices, en orden y cerrados: el último enlaza con el primero.
  final List<(double, double)> points;

  static const _asset = 'assets/images/league_logo_outline.json';

  static Future<LogoOutline> load() async {
    final raw = await rootBundle.loadString(_asset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final points = (decoded['points'] as List<dynamic>)
        .cast<List<dynamic>>()
        .map((p) => ((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(growable: false);
    return LogoOutline(points);
  }
}
