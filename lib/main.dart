import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'domain/alert_player.dart';
import 'domain/awake_guard.dart';
import 'domain/match_clock.dart';
import 'l10n/app_localizations.dart';
import 'platform/platform_alert_device.dart';
import 'platform/platform_screen.dart';
import 'ui/clock_screen.dart';

/// Los tiempos por defecto del glosario. Configurarlos es cosa de #8.
const _defaultTurn = Duration(minutes: 4);
const _defaultReserve = Duration(minutes: 15);
const _defaultWarning = Duration(seconds: 30);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final device = PlatformAlertDevice();
  await device.prepare();

  runApp(
    TurnoverApp(
      alerts: AlertPlayer(device),
      screen: const PlatformScreen(),
    ),
  );
}

/// El dueño del reloj. Es un [StatefulWidget] por una sola razón: el partido
/// tiene que durar más que un `build`. Construirlo ahí dejaba dos relojes
/// vivos en cuanto algo de arriba reconstruía la aplicación, uno pintándose y
/// otro corriendo.
class TurnoverApp extends StatefulWidget {
  const TurnoverApp({
    required this.alerts,
    required this.screen,
    super.key,
  });

  final AlertPlayer alerts;

  /// La pantalla del aparato, que entra desde fuera para que los tests puedan
  /// sustituirla por una que no cruce a la plataforma.
  final Screen screen;

  @override
  State<TurnoverApp> createState() => _TurnoverAppState();
}

class _TurnoverAppState extends State<TurnoverApp> {
  final MatchClock _clock = MatchClock(
    turn: _defaultTurn,
    reserve: _defaultReserve,
    warning: _defaultWarning,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // `of` es nulo solo si falta el delegate, y se registra aquí mismo.
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ClockScreen(
        alerts: widget.alerts,
        screen: widget.screen,
        clock: _clock,
      ),
    );
  }
}
