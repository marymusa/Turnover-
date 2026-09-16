import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'domain/alert_player.dart';
import 'domain/awake_guard.dart';
import 'domain/match_clock.dart';
import 'domain/match_settings.dart';
import 'domain/player_names.dart';
import 'l10n/app_localizations.dart';
import 'platform/platform_alert_device.dart';
import 'platform/platform_screen.dart';
import 'platform/platform_settings_store.dart';
import 'ui/clock_screen.dart';
import 'ui/clock_theme.dart';
import 'ui/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final device = PlatformAlertDevice();
  await device.prepare();

  runApp(
    TurnoverApp(
      alerts: AlertPlayer(device),
      screen: const PlatformScreen(),
      store: PlatformSettingsStore(),
    ),
  );
}

/// El dueño del reloj y de los ajustes. Es un [StatefulWidget] por una sola
/// razón: el partido tiene que durar más que un `build`. Construirlo ahí
/// dejaba dos relojes vivos en cuanto algo de arriba reconstruía la
/// aplicación, uno pintándose y otro corriendo.
class TurnoverApp extends StatefulWidget {
  const TurnoverApp({
    required this.alerts,
    required this.screen,
    required this.store,
    super.key,
  });

  final AlertPlayer alerts;

  /// La pantalla del aparato, que entra desde fuera para que los tests puedan
  /// sustituirla por una que no cruce a la plataforma.
  final Screen screen;

  /// Dónde se guardan los ajustes, también desde fuera y por lo mismo.
  final SettingsStore store;

  @override
  State<TurnoverApp> createState() => _TurnoverAppState();
}

class _TurnoverAppState extends State<TurnoverApp> {
  late final MatchSettings _settings = MatchSettings(widget.store);
  late final PlayerNames _names = PlayerNames(widget.store);

  /// Nace con los valores por defecto y lo guardado lo alcanza en cuanto se
  /// lee, por el mismo camino que cualquier cambio posterior: redimensionando.
  /// Así no hay dos formas de que un ajuste llegue al partido.
  late final MatchClock _clock = MatchClock(
    turn: defaultTurn,
    reserve: defaultReserve,
    warning: defaultWarning,
  );

  late final VoidCallback _unbindSettings;

  @override
  void initState() {
    super.initState();
    _unbindSettings = applySettingsTo(_clock, _settings);
    unawaited(_settings.load());
    unawaited(_names.load());
  }

  @override
  void dispose() {
    _unbindSettings();
    _settings.dispose();
    _names.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // `of` es nulo solo si falta el delegate, y se registra aquí mismo.
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      // La aplicación es oscura siempre, así que lo dice en vez de dejar el
      // tema de la luz que Material trae por defecto. Los dos Scaffold ya
      // ponían su fondo a mano, de modo que esto no cambia lo que se ve: lo
      // que arregla es lo que saldría de cualquier superficie que resuelva
      // del esquema y que hoy nadie pinta.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: ClockTheme.active,
          brightness: Brightness.dark,
          surface: ClockTheme.background,
        ),
        scaffoldBackgroundColor: ClockTheme.background,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // El Builder da un context por debajo del MaterialApp, que es donde vive
      // el Navigator. El de este State está por encima, y abrir los ajustes
      // con él reventaba.
      home: Builder(
        builder: (context) => ClockScreen(
          alerts: widget.alerts,
          screen: widget.screen,
          clock: _clock,
          names: _names,
          onOpenSettings: () => _openSettings(context),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsScreen(settings: _settings),
      ),
    );
  }
}
