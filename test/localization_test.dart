import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/l10n/app_localizations.dart';

void main() {
  group('localización', () {
    test('admite castellano e inglés', () {
      expect(
        AppLocalizations.supportedLocales,
        containsAll(const [Locale('en'), Locale('es')]),
      );
    });

    test('un idioma del sistema admitido se usa tal cual', () {
      expect(
        basicLocaleListResolution([
          const Locale('es'),
        ], AppLocalizations.supportedLocales),
        const Locale('es'),
      );
    });

    test('el sistema en otro idioma cae al inglés', () {
      for (final locale in [Locale('fr'), Locale('de'), Locale('ja')]) {
        expect(
          basicLocaleListResolution([
            locale,
          ], AppLocalizations.supportedLocales),
          const Locale('en'),
          reason: 'el sistema en ${locale.languageCode} debe caer al inglés',
        );
      }
    });

    test('cada idioma trae su propia cadena', () {
      expect(
        lookupAppLocalizations(const Locale('es')).appTagline,
        'Cronómetro para partidos de Blood Bowl',
      );
      expect(
        lookupAppLocalizations(const Locale('en')).appTagline,
        'Timer for Blood Bowl matches',
      );
    });

    test('los nombres por defecto están en los dos idiomas', () {
      final es = lookupAppLocalizations(const Locale('es'));
      expect(es.playerOne, 'Jugador 1');
      expect(es.playerTwo, 'Oponente');

      final en = lookupAppLocalizations(const Locale('en'));
      expect(en.playerOne, 'Player 1');
      expect(en.playerTwo, 'Opponent');
    });

    test('el nombre visible no se traduce', () {
      for (final locale in AppLocalizations.supportedLocales) {
        expect(lookupAppLocalizations(locale).appTitle, 'Turnover!');
      }
    });
  });
}
