/// Entrypoint de usar y tirar para las capturas de la ficha de Play.
///
/// Siembra cada estado del partido a mano en vez de esperar a que el reloj
/// llegue solo: así la captura del overtime no cuesta quince minutos. Reutiliza
/// los widgets de verdad, de modo que lo que sale es lo que pinta la
/// aplicación y no una maqueta.
///
/// Vive en `scripts/` y no en `.scratch/` a propósito: la versión anterior se
/// perdió por estar en un directorio que no se versiona, y volver a escribirla
/// costó más que guardarla.
///
///     flutter build apk --debug -t scripts/capture_main.dart
///     adb install -r build/app/outputs/flutter-apk/app-debug.apk
///
/// Un toque en la banda del borde izquierdo pasa a la captura siguiente. La
/// banda va por encima del `Navigator`, envolviendo el `home` entero: dentro
/// del `Stack` de la pantalla quedaba por debajo de las mitades, que se comen
/// el toque con `HitTestBehavior.opaque`.
///
/// `scripts/tomar-capturas.ps1` hace el recorrido entero.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turnover/domain/alert_player.dart';
import 'package:turnover/domain/awake_guard.dart';
import 'package:turnover/domain/match_alerts.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/domain/match_settings.dart';
import 'package:turnover/domain/player_names.dart';
import 'package:turnover/l10n/app_localizations.dart';
import 'package:turnover/ui/clock_screen.dart';
import 'package:turnover/ui/clock_theme.dart';
import 'package:turnover/ui/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const _CaptureApp());
}

/// El turno y el tiempo extra por defecto, que son los que hay que gastar para
/// llegar a cada estado. Se repiten aquí porque las capturas no leen nada
/// guardado: parten siempre de lo mismo.
const _turn = Duration(minutes: 4);
const _reserve = Duration(minutes: 15);

/// Lo que hace falta para una captura: cómo dejar el reloj y qué nombres poner.
class _Shot {
  const _Shot({
    required this.name,
    required this.seed,
    this.playerOne,
    this.playerTwo,
    this.isSettings = false,
  });

  /// El nombre del fichero que le toca, para saber cuál se está mirando.
  final String name;

  /// Deja el reloj en el estado que la captura enseña.
  final void Function(MatchClock clock) seed;

  final String? playerOne;
  final String? playerTwo;

  /// Los ajustes son otra pantalla, no otro estado del reloj.
  final bool isSettings;
}

final _shots = <_Shot>[
  _Shot(name: '01-antes-de-empezar', seed: (_) {}),
  _Shot(
    name: '02-turno-corriendo',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(const Duration(seconds: 47));
    },
  ),
  _Shot(
    name: '03-aviso-previo',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(_turn - const Duration(seconds: 8));
    },
  ),
  _Shot(
    name: '04-tiempo-extra-consumiendose',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(_turn + const Duration(minutes: 2, seconds: 12));
    },
  ),
  _Shot(
    name: '05-overtime',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(_turn + _reserve + const Duration(seconds: 34));
    },
  ),
  _Shot(
    name: '06-pausado',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 1, seconds: 3));
      clock.pause();
    },
  ),
  _Shot(
    name: '07-nombres',
    seed: (clock) {
      clock.start(Player.two);
      clock.advance(const Duration(seconds: 25));
    },
    playerOne: 'Luke',
    playerTwo: 'Nuffle',
  ),
  _Shot(name: '08-ajustes', seed: (_) {}, isSettings: true),
];

class _CaptureApp extends StatefulWidget {
  const _CaptureApp();

  @override
  State<_CaptureApp> createState() => _CaptureAppState();
}

class _CaptureAppState extends State<_CaptureApp> {
  int _index = 0;

  final _store = _MemoryStore();

  /// Un reloj nuevo por captura: sembrar sobre el anterior arrastraría lo ya
  /// gastado y el estado no sería el que dice la lista.
  late MatchClock _clock;
  late PlayerNames _names;
  late MatchSettings _settings;

  _Shot get _shot => _shots[_index];

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    _clock = MatchClock(
      turn: _turn,
      reserve: _reserve,
      warning: const Duration(seconds: 30),
    );
    _shot.seed(_clock);

    _names = PlayerNames(_store);
    final one = _shot.playerOne;
    final two = _shot.playerTwo;
    if (one != null) _names.rename(Player.one, one);
    if (two != null) _names.rename(Player.two, two);

    _settings = MatchSettings(_store);
  }

  void _next() => setState(() {
    _index = (_index + 1) % _shots.length;
    _build();
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: ClockTheme.active,
          brightness: Brightness.dark,
          surface: ClockTheme.background,
        ),
        scaffoldBackgroundColor: ClockTheme.background,
        sliderTheme: const SliderThemeData(
          valueIndicatorColor: ClockTheme.active,
          valueIndicatorTextStyle: TextStyle(
            color: ClockTheme.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      // La banda va aqui, envolviendo el `home`, y no dentro de un `Stack` de
      // la pantalla: por debajo de las mitades el toque no le llegaba nunca.
      builder: (context, child) => Stack(
        children: [
          child!,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 28,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
            ),
          ),
        ],
      ),
      // La clave es lo que obliga a `ClockScreen` a nacer de nuevo en cada
      // captura. Sin ella Flutter reutiliza su `State`, que se queda con el
      // primer reloj: el suyo es un `late final` y no cambia por recibir otro.
      home: _shot.isSettings
          ? SettingsScreen(key: ValueKey(_index), settings: _settings)
          : ClockScreen(
              key: ValueKey(_index),
              clock: _clock,
              names: _names,
              alerts: const AlertPlayer(_SilentDevice()),
              screen: const _IgnoredScreen(),
              onOpenSettings: () {},
            ),
    );
  }
}

class _MemoryStore implements SettingsStore {
  final _seconds = <String, int>{};
  final _text = <String, String>{};

  @override
  Future<int?> readSeconds(String key) async => _seconds[key];

  @override
  Future<void> writeSeconds(String key, int seconds) async {
    _seconds[key] = seconds;
  }

  @override
  Future<String?> readText(String key) async => _text[key];

  @override
  Future<void> writeText(String key, String? text) async {
    if (text == null) {
      _text.remove(key);
    } else {
      _text[key] = text;
    }
  }
}

class _SilentDevice implements AlertDevice {
  const _SilentDevice();

  @override
  Future<void> play(AlertSound sound) async {}

  @override
  Future<void> vibrate(VibrationLevel level) async {}
}

class _IgnoredScreen implements Screen {
  const _IgnoredScreen();

  @override
  Future<void> keepOn(bool on) async {}
}
