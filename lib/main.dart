import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';

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
      home: const _Placeholder(),
    );
  }
}

/// Pantalla provisional hasta que exista el cronómetro. Solo demuestra que la
/// localización resuelve.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(strings.appTitle, style: textTheme.headlineMedium),
            Text(strings.appTagline, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
