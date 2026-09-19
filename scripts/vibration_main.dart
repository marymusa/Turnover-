/// Entrypoint para probar la vibración en un aparato de verdad.
///
/// Las tres intensidades salen por `PlatformAlertDevice`, el adaptador real, no
/// por un doble: lo que hay que comprobar es justamente el código nativo, que
/// es el único que `flutter test` no toca. Cada botón dispara un nivel entero,
/// bocina incluida, porque la queja de los probadores era que la vibración no
/// acompañaba al sonido y eso solo se juzga con los dos a la vez (ADR-0005).
///
///     flutter build apk --debug -t scripts/vibration_main.dart
///     adb install -r build/app/outputs/flutter-apk/app-debug.apk
///
/// Vive en `scripts/` y no en `.scratch/` por lo mismo que `capture_main.dart`:
/// la próxima vez que haya que ajustar la vibración, esto ya está escrito.
library;

import 'package:flutter/material.dart';
import 'package:turnover/domain/match_alerts.dart';
import 'package:turnover/platform/platform_alert_device.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final device = PlatformAlertDevice();
  await device.prepare();
  runApp(_VibrationApp(device));
}

class _VibrationApp extends StatelessWidget {
  const _VibrationApp(this.device);

  final PlatformAlertDevice device;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              for (final level in VibrationLevel.values)
                Expanded(child: _LevelButton(device: device, level: level)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cada nivel ocupa un tercio de la pantalla: en la mano, y mirando el móvil de
/// lado, hay que poder darle sin apuntar.
class _LevelButton extends StatelessWidget {
  const _LevelButton({required this.device, required this.level});

  final PlatformAlertDevice device;
  final VibrationLevel level;

  /// La bocina que acompaña a cada intensidad, que es la misma correspondencia
  /// que hace `alertFor` por su nombre.
  AlertSound get _sound =>
      AlertSound.values.firstWhere((sound) => sound.name == level.name);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        device.play(_sound);
        device.vibrate(level);
      },
      child: Container(
        color: switch (level) {
          VibrationLevel.soft => Colors.green.shade700,
          VibrationLevel.strong => Colors.orange.shade800,
          VibrationLevel.strongest => Colors.red.shade900,
        },
        alignment: Alignment.center,
        child: Text(
          level.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
