import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'domain/match_clock.dart';
import 'l10n/app_localizations.dart';
import 'ui/clock_screen.dart';

/// Los tiempos por defecto del glosario. Configurarlos es cosa de #8.
const _defaultTurn = Duration(minutes: 4);
const _defaultReserve = Duration(minutes: 15);
const _defaultWarning = Duration(seconds: 30);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TurnoverApp());
}

class TurnoverApp extends StatelessWidget {
  const TurnoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // `of` es nulo solo si falta el delegate, y se registra aquí mismo.
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ClockScreen(
        clock: MatchClock(
          turn: _defaultTurn,
          reserve: _defaultReserve,
          warning: _defaultWarning,
        ),
      ),
    );
  }
}
