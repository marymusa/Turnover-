import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/match_alerts.dart';

void main() {
  // El fichero que falte no da error hasta que la bocina tiene que sonar, y
  // para entonces el partido ya está en marcha.
  test('cada bocina tiene su fichero empaquetado', () {
    for (final sound in AlertSound.values) {
      expect(
        File('assets/${sound.asset}').existsSync(),
        isTrue,
        reason: 'falta assets/${sound.asset}',
      );
    }
  });

  test('pubspec empaqueta el directorio de audio', () {
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/audio/'));
  });
}
