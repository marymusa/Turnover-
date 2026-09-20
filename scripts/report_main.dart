/// Entrypoint de usar y tirar para mirar el acta montándose.
///
/// El acta se presenta sola al salir: las cifras suben desde cero, la barra
/// parte del reparto a medias y se abre, las dos líneas recorren sus turnos y
/// al final entran las medias. Eso dura cuatro segundos y pico, pasa una vez
/// y no se repite, así que con la aplicación de verdad hay que jugar un
/// partido entero por cada vez que se quiera ver.
///
/// Aquí se ve al momento y con datos distintos, que es lo que hace falta para
/// juzgarla: una animación se mira muchas veces seguidas y con más de un dato,
/// porque la que queda bien con un reparto de 60/40 puede no decir nada con
/// uno de 51/49.
///
///     flutter build apk --debug -t scripts/report_main.dart
///     adb install -r build/app/outputs/flutter-apk/app-debug.apk
///
/// Un toque en la banda del borde izquierdo pasa al siguiente juego de datos,
/// y de paso vuelve a montar el acta: la clave de `ClockScreen` cambia, su
/// `State` nace de nuevo y la animación arranca otra vez desde cero. Con un
/// solo juego de datos el mismo toque sirve de repetición.
///
/// Si el sistema lleva las animaciones apagadas el acta sale hecha, que es lo
/// que tiene que hacer. Para que eso no se confunda con un fallo, el
/// prototipo lo dice en pantalla.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turnover/domain/alert_player.dart';
import 'package:turnover/domain/awake_guard.dart';
import 'package:turnover/domain/match_alerts.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/domain/match_settings.dart';
import 'package:turnover/domain/player_names.dart';
import 'package:turnover/domain/report_sharer.dart';
import 'package:turnover/l10n/app_localizations.dart';
import 'package:turnover/ui/clock_colors.dart';
import 'package:turnover/ui/clock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const _ReportApp());
}

const _turn = Duration(minutes: 4);
const _reserve = Duration(minutes: 15);

/// Un partido ya jugado, para mirar el acta que sale de él.
class _Variant {
  const _Variant({
    required this.name,
    required this.turns,
    this.paused = const Duration(minutes: 4, seconds: 12),
  });

  /// Lo que se lee en la esquina, para saber cuál se está mirando.
  final String name;

  /// Lo que duró cada turno, alternando jugador uno y dos: los pares son del
  /// uno y los impares del dos. La longitud es la del partido, así que una
  /// lista corta es una parte que un Time-Out acortó.
  final List<Duration> turns;

  /// Lo que el partido estuvo pausado, que es la diferencia entre el tiempo
  /// de juego y el total.
  final Duration paused;
}

final _variants = <_Variant>[
  // El caso normal: el uno se piensa las jugadas y el dos va deprisa. Es el
  // reparto con el que la barra se abre de verdad y se ve hacia dónde.
  _Variant(name: 'Desigual, 60/40', turns: _lopsided),
  // Dos que van al mismo ritmo. La barra apenas se mueve del medio, y es
  // donde se comprueba que no moverse tambien se lee como un dato y no como
  // que la animacion no ha arrancado.
  _Variant(name: 'Igualados', turns: _even),
  // Un solo turno enorme en medio de turnos cortos: el techo del eje lo fija
  // ese pico, las dos lineas quedan aplastadas abajo y las medias muy por
  // debajo de el. Es el caso que peor se lee y el que hay que mirar.
  _Variant(name: 'Un turno eterno', turns: _oneSlowTurn),
  // Una parte que un Time-Out dejo en siete turnos: la lista no llega a
  // dieciseis y el eje tiene que terminar donde termina el partido.
  _Variant(name: 'Parte corta (Time-Out)', turns: _shortHalf),
  // Sin pausas: el tiempo total y el de juego coinciden, y las dos cifras de
  // arriba suben hasta el mismo numero.
  _Variant(name: 'Sin pausas', turns: _lopsided, paused: Duration.zero),
];

/// El uno se piensa las jugadas y remata la primera parte con un turno de
/// casi cinco minutos; el dos va deprisa salvo cuando le toca responder.
const _lopsided = [
  Duration(minutes: 2, seconds: 10), Duration(minutes: 1, seconds: 5),
  Duration(minutes: 2, seconds: 40), Duration(minutes: 1, seconds: 20),
  Duration(minutes: 3, seconds: 5), Duration(minutes: 1, seconds: 2),
  Duration(minutes: 2, seconds: 25), Duration(seconds: 55),
  Duration(minutes: 3, seconds: 30), Duration(minutes: 1, seconds: 40),
  Duration(minutes: 2, seconds: 15), Duration(minutes: 1, seconds: 10),
  Duration(minutes: 4, seconds: 50), Duration(minutes: 2, seconds: 5),
  Duration(minutes: 2, seconds: 35), Duration(minutes: 1, seconds: 15),
  Duration(minutes: 2, seconds: 20), Duration(minutes: 1, seconds: 30),
  Duration(minutes: 3, seconds: 10), Duration(minutes: 2, seconds: 45),
  Duration(minutes: 2, seconds: 5), Duration(minutes: 1, seconds: 25),
  Duration(minutes: 1, seconds: 50), Duration(minutes: 3, seconds: 20),
  Duration(minutes: 2, seconds: 30), Duration(minutes: 1, seconds: 35),
  Duration(minutes: 3, seconds: 45), Duration(minutes: 2, seconds: 10),
  Duration(minutes: 1, seconds: 55), Duration(minutes: 1, seconds: 45),
  Duration(minutes: 2, seconds: 5), Duration(minutes: 1, seconds: 20),
];

const _even = [
  Duration(minutes: 2, seconds: 10), Duration(minutes: 2, seconds: 5),
  Duration(minutes: 1, seconds: 50), Duration(minutes: 2, seconds: 0),
  Duration(minutes: 2, seconds: 20), Duration(minutes: 2, seconds: 15),
  Duration(minutes: 2, seconds: 0), Duration(minutes: 1, seconds: 55),
  Duration(minutes: 2, seconds: 30), Duration(minutes: 2, seconds: 25),
  Duration(minutes: 1, seconds: 45), Duration(minutes: 1, seconds: 50),
  Duration(minutes: 2, seconds: 15), Duration(minutes: 2, seconds: 10),
  Duration(minutes: 2, seconds: 5), Duration(minutes: 2, seconds: 0),
  Duration(minutes: 1, seconds: 55), Duration(minutes: 2, seconds: 5),
  Duration(minutes: 2, seconds: 20), Duration(minutes: 2, seconds: 15),
  Duration(minutes: 2, seconds: 0), Duration(minutes: 1, seconds: 50),
  Duration(minutes: 2, seconds: 10), Duration(minutes: 2, seconds: 20),
  Duration(minutes: 1, seconds: 50), Duration(minutes: 1, seconds: 55),
  Duration(minutes: 2, seconds: 25), Duration(minutes: 2, seconds: 15),
  Duration(minutes: 2, seconds: 0), Duration(minutes: 2, seconds: 5),
  Duration(minutes: 2, seconds: 10), Duration(minutes: 2, seconds: 0),
];

const _oneSlowTurn = [
  Duration(seconds: 50), Duration(seconds: 45),
  Duration(seconds: 55), Duration(seconds: 40),
  Duration(minutes: 1, seconds: 5), Duration(seconds: 50),
  Duration(seconds: 45), Duration(seconds: 55),
  // Aqui alguien se fue a por un cafe con el reloj corriendo.
  Duration(minutes: 11, seconds: 30), Duration(seconds: 50),
  Duration(seconds: 55), Duration(seconds: 45),
  Duration(minutes: 1, seconds: 0), Duration(seconds: 50),
  Duration(seconds: 40), Duration(seconds: 55),
  Duration(seconds: 50), Duration(seconds: 45),
  Duration(minutes: 1, seconds: 10), Duration(seconds: 50),
  Duration(seconds: 45), Duration(seconds: 55),
  Duration(seconds: 50), Duration(minutes: 1, seconds: 0),
  Duration(seconds: 55), Duration(seconds: 45),
  Duration(seconds: 50), Duration(seconds: 55),
  Duration(minutes: 1, seconds: 5), Duration(seconds: 40),
  Duration(seconds: 50), Duration(seconds: 45),
];

const _shortHalf = [
  Duration(minutes: 2, seconds: 10), Duration(minutes: 1, seconds: 20),
  Duration(minutes: 2, seconds: 40), Duration(minutes: 1, seconds: 35),
  Duration(minutes: 3, seconds: 5), Duration(minutes: 1, seconds: 10),
  Duration(minutes: 2, seconds: 25), Duration(minutes: 1, seconds: 45),
  Duration(minutes: 3, seconds: 30), Duration(minutes: 1, seconds: 55),
  Duration(minutes: 2, seconds: 15), Duration(minutes: 1, seconds: 30),
  Duration(minutes: 2, seconds: 50), Duration(minutes: 2, seconds: 5),
];

class _ReportApp extends StatefulWidget {
  const _ReportApp();

  @override
  State<_ReportApp> createState() => _ReportAppState();
}

class _ReportAppState extends State<_ReportApp> {
  int _index = 0;

  final _store = _MemoryStore();

  late MatchClock _clock;
  late PlayerNames _names;

  _Variant get _variant => _variants[_index];

  @override
  void initState() {
    super.initState();
    _build();
  }

  /// Juega el partido entero de un tirón y lo termina, que es la única forma
  /// de que el acta tenga algo que contar: la gráfica dibuja lo que duró cada
  /// turno, y eso solo existe si los turnos se han pasado de verdad.
  void _build() {
    _clock = MatchClock(
      turn: _turn,
      reserve: _reserve,
      warning: const Duration(seconds: 30),
    );
    _clock.start(Player.one);

    // Los turnos se alternan sin más. En el partido de verdad quien cierra
    // una parte la abre también y juega dos seguidos, pero eso lo decide la
    // cuenta y aquí no hay ninguna: para mirar cómo se dibuja la gráfica da
    // igual de quién sea cada punto, lo que importa es que haya dos series
    // con formas distintas.
    final turns = _variant.turns;
    for (var i = 0; i < turns.length; i++) {
      _clock.advance(turns[i]);
      // Lo pausado se mete a la mitad, y por su propia puerta: no es de
      // ningún jugador, así que no puede entrar por `advance`.
      if (i == turns.length ~/ 2 && _variant.paused > Duration.zero) {
        _clock.pause();
        _clock.advanceStopped(_variant.paused);
        _clock.resume();
      }
      _clock.passTurn();
    }
    _clock.finish();

    _names = PlayerNames(_store);
  }

  void _next() => setState(() {
    _index = (_index + 1) % _variants.length;
    _build();
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ClockColors.light.toTheme(),
      darkTheme: ClockColors.dark.toTheme(),
      themeMode: ThemeMode.system,
      builder: (context, child) => Stack(
        children: [
          child!,
          Positioned.fill(child: IgnorePointer(child: _Overlay(_variant.name))),
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
      // La clave es lo que vuelve a montar el acta. Sin ella Flutter reutiliza
      // el `State` de `ClockScreen`, y con él el de `MatchReport`, que es
      // quien lleva el controlador de la animación: se quedaría acabada y no
      // habría manera de volver a verla.
      home: ClockScreen(
        key: ValueKey(_index),
        clock: _clock,
        names: _names,
        alerts: const AlertPlayer(_SilentDevice()),
        screen: const _IgnoredScreen(),
        sharer: const _MuteSharer(),
        onOpenSettings: () {},
      ),
    );
  }
}

/// El nombre de la variante y, si hace falta, el aviso de que el sistema
/// lleva las animaciones apagadas.
///
/// Ese aviso es la mitad del prototipo: sin él, un acta que sale hecha en un
/// teléfono con las animaciones apagadas se lee como que la animación está
/// rota, y lo que está es respetando el ajuste.
class _Overlay extends StatelessWidget {
  const _Overlay(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    final muted = MediaQuery.of(context).disableAnimations;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (muted)
                  Text(
                    'Animaciones apagadas en el sistema: sale hecha',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.reportAccentOpponent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
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

/// El prototipo no comparte nada: el menú del sistema taparía justo lo que se
/// está mirando.
class _MuteSharer implements ReportSharer {
  const _MuteSharer();

  @override
  Future<void> share(
    Uint8List png, {
    required String name,
    String? text,
  }) async {}
}
