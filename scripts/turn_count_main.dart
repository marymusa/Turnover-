/// Prototipo de usar y tirar para el ticket #14: la cuenta de turnos, la parte
/// y el marcador en la costura.
///
/// No es codigo de produccion y no pretende serlo. Pinta las variantes una al
/// lado de otra sobre la pantalla de verdad, para decidir mirando el telefono
/// lo que no se decide razonando:
///
///   1. La cuenta de turnos: columna de ocho marcas contra un solo numero.
///   2. La parte: etiqueta girada 90 grados en la costura izquierda.
///   3. El marcador: girado 90 grados, simetrico a la parte.
///
/// Sigue el patron de `scripts/capture_main.dart`: siembra el reloj a mano y
/// pasa de una variante a la siguiente tocando la banda del borde izquierdo.
///
///     flutter build apk --debug -t scripts/turn_count_main.dart
///     adb install -r build/app/outputs/flutter-apk/app-debug.apk
///
/// La cuenta y la parte que se pintan aqui son valores fijos de muestra: el
/// dominio que las lleva es el ticket #15, que todavia no existe.
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
import 'package:turnover/ui/clock_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const _PrototypeApp());
}

const _turn = Duration(minutes: 4);
const _reserve = Duration(minutes: 15);

/// Como se pinta la cuenta de turnos, que es lo que decide el prototipo.
enum _CountStyle {
  /// Sin cuenta: la pantalla de hoy, para comparar contra ella.
  none,

  /// Ocho casillas redondeadas con su numero dentro, apiladas en el margen
  /// derecho de la mitad. El turno en curso destacado, los jugados apagados y
  /// los que faltan discretos.
  column,
}

/// Una variante del prototipo: como se pinta la cuenta y en que estado esta el
/// partido mientras se mira.
class _Variant {
  const _Variant({
    required this.name,
    required this.style,
    required this.seed,
    this.turnOne = 3,
    this.turnTwo = 2,
    this.half = 1,
  });

  /// Lo que se lee en la esquina, para saber cual se esta mirando.
  final String name;

  final _CountStyle style;
  final void Function(MatchClock clock) seed;

  /// La cuenta de cada jugador y la parte, fijas: el dominio es el #15.
  final int turnOne;
  final int turnTwo;
  final int half;
}

final _variants = <_Variant>[
  _Variant(
    name: 'Turno 3, media cuenta',
    style: _CountStyle.column,
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(const Duration(seconds: 47));
    },
  ),
  // Sin empezar: es donde se ve si la cuenta ocupa su sitio antes de tiempo.
  // `player_half.dart` insiste cuatro veces en que empezar no mueve los relojes
  // de sitio, y la columna tiene que respetarlo igual. Con los dos en 1 no hay
  // ningun turno jugado, que es lo que la version anterior contaba mal.
  _Variant(
    name: 'Sin empezar, los dos en 1',
    style: _CountStyle.column,
    seed: (_) {},
    turnOne: 1,
    turnTwo: 1,
  ),
  // La segunda parte recien empezada: las casillas van de 9 a 16 y el turno en
  // curso es el 9. Es donde se ve si la parte se lee sola en el numero.
  _Variant(
    name: 'Segunda parte, turno 9',
    style: _CountStyle.column,
    seed: (clock) {
      clock.start(Player.two);
      clock.advance(const Duration(seconds: 40));
    },
    turnOne: 1,
    turnTwo: 1,
    half: 2,
  ),
  // La segunda parte avanzada, con dos cifras en casi toda la fila: es donde
  // se comprueba que las casillas no se estrechan con el 16.
  _Variant(
    name: 'Segunda parte, turno 15',
    style: _CountStyle.column,
    seed: (clock) {
      clock.start(Player.two);
      clock.advance(const Duration(minutes: 2, seconds: 30));
    },
    turnOne: 7,
    turnTwo: 7,
    half: 2,
  ),
  // El turno gastado del rival: el naranja de su mitad y el amarillo de la
  // reserva a la vez, para ver si la columna se sigue leyendo encima.
  _Variant(
    name: 'Rival con el turno gastado',
    style: _CountStyle.column,
    seed: (clock) {
      clock.start(Player.two);
      clock.advance(_turn + const Duration(minutes: 2, seconds: 12));
    },
    turnOne: 4,
    turnTwo: 5,
  ),
  // El ultimo turno de la parte: la columna entera apagada menos el 8.
  _Variant(
    name: 'Turno 8, el ultimo',
    style: _CountStyle.column,
    seed: (clock) {
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 1, seconds: 5));
    },
    turnOne: 8,
    turnTwo: 7,
  ),
];

class _PrototypeApp extends StatefulWidget {
  const _PrototypeApp();

  @override
  State<_PrototypeApp> createState() => _PrototypeAppState();
}

class _PrototypeAppState extends State<_PrototypeApp> {
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

  /// Un reloj nuevo por variante, igual que en las capturas: sembrar sobre el
  /// anterior arrastraria lo ya gastado.
  void _build() {
    _clock = MatchClock(
      turn: _turn,
      reserve: _reserve,
      warning: const Duration(seconds: 30),
    );
    _variant.seed(_clock);
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
          // La cuenta, la parte y el marcador van encima de la pantalla de
          // verdad en vez de dentro: el prototipo no toca `lib/`, que es lo
          // que lo hace desechable.
          Positioned.fill(
            child: IgnorePointer(
              child: _Overlay(variant: _variant, clock: _clock),
            ),
          ),
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

/// Todo lo que el prototipo anade encima de la pantalla: las dos cuentas, la
/// parte, el marcador y el nombre de la variante.
class _Overlay extends StatelessWidget {
  const _Overlay({required this.variant, required this.clock});

  final _Variant variant;
  final MatchClock clock;

  @override
  Widget build(BuildContext context) {
    final isStarted = clock.state != MatchState.notStarted;
    // Todo cuelga de una [Material] transparente. Sin ella, cualquier [Text]
    // que no tenga una encima sale con el doble subrayado amarillo con que
    // Flutter avisa de que le falta: el prototipo se apila fuera del
    // `Scaffold`, asi que se la tiene que poner el.
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: [
            // La cuenta va en una fila al pie de cada tarjeta, que es donde
            // sobra sitio: el bloque de relojes esta centrado y por debajo no
            // hay nada.
            //
            // El pie de cada jugador es el que ve el, no el de la pantalla: la
            // mitad de arriba esta girada, asi que el suyo cae contra el borde
            // superior y la fila se pinta girada con ella.
            // Las dos mitades del alto, cada una con su fila abajo del todo.
            // El reparto va con un [Column] de dos [Expanded] y no con
            // fracciones sueltas: es el mismo que hace `clock_screen.dart`, y
            // asi las filas caen justo donde acaba cada tarjeta.
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    // La mitad de arriba esta girada, asi que su pie cae
                    // contra el borde superior de la pantalla.
                    child: RotatedBox(
                      quarterTurns: 2,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _Count(
                          style: variant.style,
                          turn: variant.turnTwo,
                          isActive: clock.activePlayer == Player.two,
                          player: Player.two,
                          half: variant.half,
                          isStarted: isStarted,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _Count(
                        style: variant.style,
                        turn: variant.turnOne,
                        isActive: clock.activePlayer == Player.one,
                        player: Player.one,
                        half: variant.half,
                        isStarted: isStarted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // La parte no lleva indicador propio: se lee en la numeracion, que
            // en la segunda va de 9 a 16. El marcador tampoco esta, que es del
            // ticket del que sale la anotacion.
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  variant.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ClockColors.of(context).onSurface
                        .withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La cuenta de un jugador, en el margen lateral de su mitad.
class _Count extends StatelessWidget {
  const _Count({
    required this.style,
    required this.turn,
    required this.isActive,
    required this.player,
    required this.half,
    required this.isStarted,
  });

  final _CountStyle style;
  final int turn;
  final bool isActive;

  /// De quien es la cuenta: decide el color de la tarjeta sobre la que se
  /// pinta, azul o naranja, igual que en `clock_screen.dart`.
  final Player player;

  /// La parte, que aqui solo corre la numeracion: en la segunda las casillas
  /// van de 9 a 16.
  final int half;

  /// Sin empezar no hay cuenta que enseñar: nadie ha jugado ningun turno
  /// todavia.
  final bool isStarted;

  static const _total = 8;

  /// Lo que se le suma al numero de casilla en la segunda parte: la cuenta
  /// sigue a 9 en vez de volver a 1, y asi la parte se lee en el propio numero
  /// sin ningun indicador aparte (ADR-0010).
  int get _offset => half == 2 ? _total : 0;

  /// Lo que la fila se despega de la pared interior de la tarjeta, igual por
  /// los tres lados. Se suma al margen de la propia tarjeta, que no es el
  /// mismo a los lados que abajo: sin sumarlo, pedir el margen de la tarjeta
  /// dejaba la fila rozando su pared por dentro.
  ///
  /// Cubre de sobra el radio de la esquina, que a 20 pide unos 6 para que una
  /// casilla no se meta debajo del arco.
  static const _innerPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    if (style == _CountStyle.none) return const SizedBox.shrink();

    // La mitad activa conserva su color en los dos modos (ADR-0009), asi que
    // su letra es [activeText] y no cambia con la luz. La que espera si se
    // aclara, y la suya es [text], que es la que el tema mueve.
    final colors = ClockColors.of(context);
    final ink = isActive ? colors.activeText : colors.text;
    final surface = isActive
        ? (player == Player.one ? colors.active : colors.activeOpponent)
        : colors.inactive;

    // Sin empezar la fila se vuelve transparente en vez de desaparecer, que es
    // lo mismo que hace `_StartHint` en `player_half.dart`: si se fuera del
    // todo, empezar el partido movería los relojes de sitio.
    return Opacity(
      opacity: isStarted ? 1 : 0,
      child: Padding(
        // El margen de la tarjeta y, encima, el hueco interior: la fila vive
        // dentro de la tarjeta, asi que para despegarse de su pared hay que
        // sumar los dos. El de la tarjeta vale 12 a los lados y 6 abajo, de
        // modo que sumarle lo mismo a los tres deja el hueco parejo por dentro.
        padding: const EdgeInsets.only(
          left: ClockTheme.halfCardInset + _innerPadding,
          right: ClockTheme.halfCardInset + _innerPadding,
          bottom: ClockTheme.halfCardVerticalInset + _innerPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // De izquierda a derecha, del 1 al 8 en la primera parte y del 9 al
            // 16 en la segunda. El `RotatedBox` de la mitad de arriba lo
            // invierte entero, de modo que cada jugador lee su cuenta empezando
            // por el numero mas bajo a su izquierda.
            for (var i = 1; i <= _total; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _TurnBox(
                  number: i + _offset,
                  state: _stateOf(i),
                  ink: ink,
                  surface: surface,
                ),
              ),
          ],
        ),
      ),
    );
  }

  _TurnState _stateOf(int number) {
    if (number == turn) return _TurnState.current;
    return number < turn ? _TurnState.played : _TurnState.upcoming;
  }
}

/// En que punto de la cuenta esta una casilla.
enum _TurnState {
  /// Ya jugado: apagado, porque no queda nada que hacer con el.
  played,

  /// El que se esta jugando: es el unico que destaca.
  current,

  /// Todavia por jugar: discreto, presente para dar la escala.
  upcoming,
}

/// Una casilla de la cuenta, construida como un chip de Material: una
/// [Material] con su forma, su elevacion y su tinta, y no un [Container]
/// pintado a mano.
///
/// Los tres estados son los de Material y no una escala inventada: el turno en
/// curso es un chip seleccionado, que en Material se rellena con el color y
/// lleva la letra encima en el contrario; el jugado es un chip deshabilitado,
/// con la opacidad que Material usa para lo que ya no responde; y el que falta
/// es un chip de contorno, que es como Material muestra lo disponible sin
/// destacarlo.
class _TurnBox extends StatelessWidget {
  const _TurnBox({
    required this.number,
    required this.state,
    required this.ink,
    required this.surface,
  });

  final int number;
  final _TurnState state;

  /// El color de la mitad sobre la que se pinta, ya resuelto para el modo y
  /// para si el jugador tiene el turno.
  final Color ink;

  /// El fondo de la mitad. El chip seleccionado invierte, y su numero se
  /// recorta sobre [ink] con este color: usar uno fijo lo dejaba azul encima
  /// del naranja del rival.
  final Color surface;

  /// El objetivo tactil minimo de Material es 48, pero esto no se pulsa: la
  /// correccion a mano es una pulsacion larga sobre la cuenta entera, no sobre
  /// una casilla. Es un indicador, y va al tamano de un chip denso.
  ///
  /// Mas ancha que alta porque en la segunda parte los numeros son de dos
  /// cifras: el ancho lo fija el 16, y todas miden igual para que la fila no
  /// cambie de forma al cambiar de parte.
  static const _width = 30.0;
  static const _height = 26.0;

  /// Las de Material para el estado deshabilitado: la capa al 12% y el
  /// contenido al 38%.
  static const _disabledContainerOpacity = 0.12;
  static const _disabledContentOpacity = 0.38;

  /// El radio `small` de las formas de Material, que es el que llevan los
  /// contenedores de este tamano.
  static const _corners = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == _TurnState.current;
    final isPlayed = state == _TurnState.played;

    final background = switch (state) {
      _TurnState.current => ink,
      _TurnState.played => ink.withValues(alpha: _disabledContainerOpacity),
      _TurnState.upcoming => Colors.transparent,
    };

    final content = switch (state) {
      _TurnState.current => surface,
      _TurnState.played => ink.withValues(alpha: _disabledContentOpacity),
      _TurnState.upcoming => ink,
    };

    return Material(
      color: background,
      // Cuadrado de esquinas redondeadas, no pastilla: son ocho casillas en
      // fila y el cuadrado las hace contarse de un vistazo. El radio es el
      // `small` de las formas de Material.
      shape: isPlayed || isCurrent
          ? const RoundedRectangleBorder(borderRadius: _corners)
          : RoundedRectangleBorder(
              borderRadius: _corners,
              side: BorderSide(color: ink.withValues(alpha: 0.38)),
            ),
      // Solo el seleccionado se levanta. En Material la elevacion dice cual
      // manda, y aqui manda el turno que se esta jugando.
      elevation: isCurrent ? 2 : 0,
      shadowColor: ClockColors.of(context).controlShadow,
      child: SizedBox(
        width: _width,
        height: _height,
        child: Center(
          child: Text(
            '$number',
            // El estilo sale del tema, no de un tamano suelto: es la etiqueta
            // de un chip, que en Material es `labelMedium`.
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: content,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              height: 1,
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
