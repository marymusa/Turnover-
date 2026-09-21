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
/// `scripts/tomar-capturas.ps1` hace el recorrido entero en Android.
///
/// En iOS no vale el recorrido a toques: `simctl` sabe arrancar, fotografiar y
/// matar, pero no sabe tocar la pantalla. Así que allí la aplicación se arranca
/// una vez por captura y se le dice cuál le toca dejándole una nota:
///
///     <contenedor de datos>/tmp/turnover-captura.txt
///
/// con el índice en la primera línea y el idioma (`es` o `en`) en la segunda.
/// El script saca esa ruta con `simctl get_app_container`, y aquí se llega a
/// ella por `Directory.systemTemp`, que en iOS es el `tmp` del contenedor.
///
/// La nota y no el entorno porque en iOS `Platform.environment` le llega vacía
/// a Dart: `SIMCTL_CHILD_...` no la cruza, y se comprobó midiéndolo. Sin nota
/// se arranca por la primera captura, que es lo que hace Android.
///
/// Se lee una sola vez, al nacer: cambiar la nota con la aplicación abierta no
/// hace nada.
library;

import 'dart:io' show Directory, File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turnover/domain/alert_player.dart';
import 'package:turnover/domain/awake_guard.dart';
import 'package:turnover/domain/match_alerts.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/domain/match_settings.dart';
import 'package:turnover/domain/player_names.dart';
import 'package:turnover/domain/report_sharer.dart';
import 'package:turnover/domain/turn_count.dart';
import 'package:turnover/l10n/app_localizations.dart';
import 'package:turnover/ui/clock_colors.dart';
import 'package:turnover/ui/clock_screen.dart';
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
    this.seedCount,
    this.playerOne,
    this.playerTwo,
    this.isSettings = false,
  });

  /// El nombre del fichero que le toca, para saber cuál se está mirando.
  final String name;

  /// Deja el reloj en el estado que la captura enseña.
  final void Function(MatchClock clock) seed;

  /// Deja la cuenta de turnos donde la quiere la captura. Va aparte del reloj
  /// porque son dos cosas: el reloj mide el tiempo y esto cuenta los turnos, y
  /// una captura puede querer el turno 14 con el reloj recién empezado.
  ///
  /// Nulo deja la cuenta al principio, que es lo que enseña un turno 1.
  final void Function(TurnCount count)? seedCount;

  final String? playerOne;
  final String? playerTwo;

  /// Los ajustes son otra pantalla, no otro estado del reloj.
  final bool isSettings;
}

/// Deja la cuenta en el turno que pide la captura, pasando turno las veces que
/// haga falta desde el toque inicial. Se pasa turno de verdad en vez de empujar
/// el número: así el desfase entre los dos jugadores sale solo, que es lo que
/// hay que mirar en la fila.
void Function(TurnCount) _countAt({
  required Player receiver,
  required int passes,
}) => (count) {
  count.start(receiver);
  for (var i = 0; i < passes; i++) {
    count.passTurn();
  }
};

/// Lo que dura cada turno del acta de ejemplo, alternando jugador uno y dos:
/// los pares son del uno y los impares del dos.
///
/// Están puestos a mano y no generados porque tienen que contar algo: el uno
/// se piensa las jugadas y remata la primera parte con un turno de casi cinco
/// minutos, y el dos va deprisa salvo cuando le toca responder. Una serie
/// aleatoria dibuja ruido, y lo que hay que mirar en la captura es si la
/// gráfica deja leer una partida.
const _actaTurns = [
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

final _shots = <_Shot>[
  _Shot(name: '01-antes-de-empezar', seed: (_) {}),
  _Shot(
    name: '02-turno-corriendo',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(const Duration(seconds: 47));
    },
    // A media cuenta, que es donde la fila enseña los tres estados de casilla a
    // la vez: los jugados, el que corre y los que faltan.
    seedCount: _countAt(receiver: Player.one, passes: 4),
  ),
  _Shot(
    name: '03-aviso-previo',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(_turn - const Duration(seconds: 8));
    },
    seedCount: _countAt(receiver: Player.one, passes: 4),
  ),
  _Shot(
    name: '04-tiempo-extra-consumiendose',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(_turn + const Duration(minutes: 2, seconds: 12));
    },
    seedCount: _countAt(receiver: Player.one, passes: 6),
  ),
  _Shot(
    name: '05-overtime',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(_turn + _reserve + const Duration(seconds: 34));
    },
    seedCount: _countAt(receiver: Player.one, passes: 10),
  ),
  _Shot(
    name: '06-pausado',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 1, seconds: 3));
      clock.pause();
    },
    seedCount: _countAt(receiver: Player.one, passes: 6),
  ),
  _Shot(
    name: '07-nombres',
    seed: (clock) {
      clock.start(Player.two);
      clock.advance(const Duration(seconds: 25));
    },
    seedCount: _countAt(receiver: Player.two, passes: 3),
    playerOne: 'Luke',
    playerTwo: 'Nuffle',
  ),
  _Shot(name: '08-ajustes', seed: (_) {}, isSettings: true),
  // El rival con el turno gastado: es la única combinación que enseña a la vez
  // el naranja de su mitad y el amarillo de la reserva, que es lo que hay que
  // mirar junto para saber si el aviso se sigue leyendo encima del naranja.
  _Shot(
    name: '09-rival-con-el-turno-gastado',
    seed: (clock) {
      clock.start(Player.two);
      clock.advance(_turn + const Duration(minutes: 2, seconds: 12));
    },
    seedCount: _countAt(receiver: Player.two, passes: 7),
  ),
  // La segunda parte avanzada: la fila va de 9 a 16 y casi toda ella lleva dos
  // cifras, que es donde se ve si las casillas se estrechan al cambiar de
  // parte. Es tambien donde se lee si la parte se distingue sola en el numero.
  _Shot(
    name: '10-segunda-parte',
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 2, seconds: 30));
    },
    seedCount: _countAt(receiver: Player.one, passes: 21),
  ),
  // El velo con el boton de Time-Out, que es lo que hay que mirar de cerca: que
  // el boton se lee como un evento de la patada inicial y no como pausar, y que
  // convive con el aviso sin taparle el sitio a la costura.
  _Shot(
    name: '11-pausado-con-time-out',
    seed: (clock) {
      clock.start(Player.two);
      clock.advance(const Duration(minutes: 2, seconds: 41));
      clock.pause();
    },
    seedCount: _countAt(receiver: Player.two, passes: 9),
  ),
  // El acta. Se siembra con los dos tiempos desiguales a propósito, que es lo
  // que hay que mirar: que la comparación se lee de un vistazo y que los
  // cuatro tiempos cuadran en pantalla. Y es la captura que de verdad importa,
  // porque el acta existe para ser capturada: vale también como la prueba de
  // que sale entera, derecha y de una pieza.
  //
  // El tiempo parado no se puede sembrar corriendo, porque no es de nadie: se
  // pausa, se le da el rato por `advanceStopped` y se reanuda, que es el
  // camino por el que lo mete el ticker durante el partido.
  _Shot(
    name: '12-acta',
    seed: (clock) {
      clock.start(Player.one);
      // Se juegan los treinta y dos turnos de verdad, uno a uno, en vez de
      // gastar los totales de una vez: la gráfica dibuja lo que duró cada
      // turno, y sembrando el total sale una línea plana que no enseña si la
      // gráfica funciona.
      for (var turn = 0; turn < _actaTurns.length; turn++) {
        clock.advance(_actaTurns[turn]);
        // Una pausa por parte, para que el tiempo parado no salga a cero y se
        // vea que el total es mayor que el tiempo de juego.
        if (turn == 11 || turn == 23) {
          clock.pause();
          clock.advanceStopped(const Duration(minutes: 2, seconds: 6));
          clock.resume();
        }
        clock.passTurn();
      }
      clock.finish();
    },
    seedCount: _countAt(receiver: Player.one, passes: 32),
  ),
];

/// Lo que la tanda de capturas pide: por qué captura empezar y en qué idioma.
///
/// Se lee una sola vez, al arrancar. Cualquier cosa rara en la nota (que no
/// esté, que no se pueda leer, que traiga un índice que no existe) se resuelve
/// con la primera captura en castellano: el script comprueba después que la
/// tanda no traiga dos capturas iguales, que es donde se ve si esto ha pasado.
class _Nota {
  const _Nota(this.indice, this.idioma);

  final int indice;
  final String idioma;

  static const _fichero = 'turnover-captura.txt';

  static _Nota leer() {
    try {
      final nota = File('${Directory.systemTemp.path}/$_fichero');
      if (!nota.existsSync()) return const _Nota(0, 'es');
      final lineas = nota.readAsLinesSync();
      final indice = int.tryParse(lineas.isEmpty ? '' : lineas.first.trim());
      return _Nota(
        indice == null || indice < 0 || indice >= _shots.length ? 0 : indice,
        lineas.length > 1 ? lineas[1].trim() : 'es',
      );
    } catch (_) {
      return const _Nota(0, 'es');
    }
  }
}

final _nota = _Nota.leer();

class _CaptureApp extends StatefulWidget {
  const _CaptureApp();

  @override
  State<_CaptureApp> createState() => _CaptureAppState();
}

class _CaptureAppState extends State<_CaptureApp> {
  /// Por qué captura se empieza. En Android siempre es la primera y al resto se
  /// llega a toques; en iOS se arranca una vez por captura y esto dice cuál.
  ///
  /// Un valor que no sea un índice de la lista se ignora y arranca por la
  /// primera: una tanda que empieza donde no debe se nota mirando las capturas,
  /// y para entonces ya se ha perdido el rato.
  int _index = _nota.indice;

  /// El idioma de la ficha que se está fotografiando. La aplicación de verdad
  /// lo saca del sistema (ADR-0004), pero aquí se fija: una tanda entera tiene
  /// que salir en el mismo idioma, y no en el que tenga puesto el simulador.
  static Locale get _idioma => AppLocalizations.supportedLocales.firstWhere(
    (locale) => locale.languageCode == _nota.idioma,
    orElse: () => const Locale('es'),
  );

  final _store = _MemoryStore();

  /// Un reloj nuevo por captura: sembrar sobre el anterior arrastraría lo ya
  /// gastado y el estado no sería el que dice la lista.
  late MatchClock _clock;
  late TurnCount _count;
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

    // La cuenta se siembra aparte del reloj: llegar al turno 14 pasando turno
    // catorce veces no enseña nada que no enseñe ponerlo a mano.
    _count = TurnCount();
    _shot.seedCount?.call(_count);

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
      locale: _idioma,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Los dos temas y que mande el aparato, igual que la aplicacion de
      // verdad: es lo que permite ver las dos paletas cambiando el ajuste del
      // sistema con las capturas abiertas.
      theme: ClockColors.light.toTheme(),
      darkTheme: ClockColors.dark.toTheme(),
      themeMode: ThemeMode.system,
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
              count: _count,
              names: _names,
              alerts: const AlertPlayer(_SilentDevice()),
              screen: const _IgnoredScreen(),
              sharer: const _MuteSharer(),
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

/// Las capturas no comparten nada: el menú del sistema taparía justo lo que
/// se está fotografiando.
class _MuteSharer implements ReportSharer {
  const _MuteSharer();

  @override
  Future<void> share(
    Uint8List png, {
    required String name,
    String? text,
  }) async {}
}
