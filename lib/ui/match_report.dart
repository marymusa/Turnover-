import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../domain/clock_format.dart';
import '../domain/match_clock.dart';
import '../domain/report_sharer.dart';
import '../domain/turn_count.dart';
import '../l10n/app_localizations.dart';
import 'clock_colors.dart';
import 'clock_theme.dart';

/// El acta, la pantalla que cierra el partido al pasar el turno 16 del segundo
/// jugador. No hay botón de terminar: sale sola.
///
/// Es un documento y no una pantalla de juego, y esa es la diferencia que
/// manda en cómo se pinta. El resto de la aplicación se parte en dos mitades
/// enfrentadas porque el móvil está en medio de la mesa y los dos jugadores lo
/// leen a la vez desde sus lados. El acta no: se lee una vez, con el partido
/// acabado y los dos mirando la misma pantalla, y de ella se hace una captura
/// que va al responsable de la liga, que la abre como cualquier otra imagen.
/// Media acta girada sería media captura del revés.
///
/// De arriba abajo: cuánto se ha jugado, cómo se ha repartido entre los dos, y
/// turno a turno de dónde salió ese reparto. Las tres son la misma historia
/// contada con más detalle cada vez.
///
/// No hay resultado, porque la anotación se queda fuera de esta versión y no
/// hay marcador que enseñar, ni se nombra la prórroga, porque sin resultado no
/// hay empate que nombrar (ADR-0008). No se guarda, como no se guarda nada
/// (ADR-0003): la captura es el único registro, y por eso el acta cabe entera
/// sin desplazarse, porque lo que no esté en pantalla no sale en ella.
class MatchReport extends StatefulWidget {
  const MatchReport({
    required this.nameOfOne,
    required this.nameOfTwo,
    required this.playedByOne,
    required this.playedByTwo,
    required this.turnsOfOne,
    required this.turnsOfTwo,
    required this.total,
    required this.sharer,
    required this.onEnd,
    super.key,
  });

  final String nameOfOne;
  final String nameOfTwo;

  final Duration playedByOne;
  final Duration playedByTwo;

  /// Lo que duró cada turno de cada jugador, por orden. Es lo que dibuja la
  /// gráfica: el turno enésimo es el enésimo que jugó.
  final List<Duration> turnsOfOne;
  final List<Duration> turnsOfTwo;

  /// Lo que ha durado el partido con las pausas dentro. El tiempo de juego,
  /// que es la cifra que encabeza, sale de sumar lo de los dos; lo parado es
  /// la diferencia entre los dos números, y por eso los dos van juntos.
  final Duration total;

  /// Terminar el partido, que devuelve a antes de empezar. Es el único botón:
  /// abandonar a mitad de partido ya lo cubre reiniciar, que además avisa de
  /// lo que se pierde.
  final VoidCallback onEnd;

  /// Por donde sale la foto del acta. El acta la hace y este se la lleva: qué
  /// se comparte lo decide la pantalla, porque es la única que sabe lo que ha
  /// pintado, y cómo sale del teléfono no es cosa suya.
  final ReportSharer sharer;

  /// Los dos tramos de la barra, para poder medirlos desde un test.
  ///
  /// Existen porque la barra llegó a estar en pantalla con los dos tramos a
  /// cero de alto: la fila los centraba en vez de estirarlos, y una caja
  /// pintada y sin hijo con el alto holgado se queda en nada. Se veía el
  /// hueco donde iba la barra y no la barra, y ningún test lo cazaba porque
  /// el widget estaba montado y las etiquetas salían bien.
  @visibleForTesting
  static const barKeyOne = Key('match-report-bar-one');
  @visibleForTesting
  static const barKeyTwo = Key('match-report-bar-two');

  /// El nombre del fichero que se comparte. No se traduce: es un
  /// identificador, y quien lo recibe lo archiva, no lo lee.
  static const fileName = 'turnover-match-report.png';

  @override
  State<MatchReport> createState() => _MatchReportState();
}

class _MatchReportState extends State<MatchReport> {
  /// Lo que entra en la foto. Marca el trozo del árbol que se sabe pintar a
  /// sí mismo aparte, que es lo que permite sacarle una imagen sin capturar
  /// la pantalla entera.
  final _documentKey = GlobalKey();

  /// Hace la foto del acta y se la da a quien la comparte.
  ///
  /// Un fallo aquí no tumba nada ni se anuncia: el acta sigue en pantalla y
  /// el partido sigue terminado, así que lo peor que pasa es que haya que
  /// volver a pulsar. Es el mismo criterio con el que [AwakeGuard] trata a
  /// una pantalla que no responde.
  Future<void> _share() async {
    // Las cadenas se leen antes de esperar nada: después de un `await` este
    // `context` puede haberse ido.
    //
    // Los dos nombres van en el texto y no solo en la imagen: en una bandeja
    // de entrada el acta no se distingue de la siguiente hasta que se abre,
    // y el texto sí se lee de pasada.
    final text = AppLocalizations.of(context)!.matchReportShareText(
      widget.nameOfOne,
      widget.nameOfTwo,
    );
    try {
      final png = await _capture();
      if (png == null) return;
      await widget.sharer.share(
        png,
        name: MatchReport.fileName,
        text: text,
      );
    } on Exception {
      return;
    }
  }

  /// Pinta el acta en una imagen. Nula si todavía no se ha dispuesto, que no
  /// llega a pasar porque el botón vive debajo de ella.
  Future<Uint8List?> _capture() async {
    final boundary = _documentKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;

    final image = await boundary.toImage(
      pixelRatio: ClockTheme.reportCapturePixelRatio,
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } finally {
      // La imagen es memoria nativa y no la recoge nadie por su cuenta.
      image.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = ClockColors.of(context);

    // Los tiempos se truncan a la vez y aquí, y el de juego sale de sumar los
    // dos ya truncados. Truncando cada uno por su cuenta y sumando después,
    // los trozos de segundo que cada uno pierde no caen en ninguna parte y el
    // acta enseña una suma que no cuadra por un segundo.
    final oneSeconds = widget.playedByOne.inSeconds;
    final twoSeconds = widget.playedByTwo.inSeconds;
    final playSeconds = oneSeconds + twoSeconds;

    return ColoredBox(
      color: colors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(ClockTheme.halfCardInset),
          // Encoge entera si la pantalla no da de sí, en vez de desplazarse:
          // el acta se lee igual más pequeña, y lo que se sale de la pantalla
          // no sale en la captura, que es para lo que el acta existe.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: ClockTheme.reportWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Lo que entra en la foto, y solo eso: los botones se
                  // quedan fuera a propósito, porque en la imagen que llega
                  // al responsable de la liga no hay nada que pulsar y un
                  // botón pintado allí solo confunde.
                  //
                  // Lleva su propio fondo: lo que se pinta fuera del marco no
                  // entra en la imagen, y sin él el acta saldría con el fondo
                  // transparente, que en casi cualquier visor se ve negro o
                  // a cuadros.
                  RepaintBoundary(
                    key: _documentKey,
                    child: ColoredBox(
                      color: colors.background,
                      child: Padding(
                        padding: const EdgeInsets.all(
                          ClockTheme.reportCaptureInset,
                        ),
                        child: _Document(
                          nameOfOne: widget.nameOfOne,
                          nameOfTwo: widget.nameOfTwo,
                          oneSeconds: oneSeconds,
                          twoSeconds: twoSeconds,
                          playSeconds: playSeconds,
                          total: widget.total,
                          turnsOfOne: widget.turnsOfOne,
                          turnsOfTwo: widget.turnsOfTwo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: ClockTheme.reportButtonGap),
                  Center(
                    child: _PillButton(
                      label: strings.matchReportShare,
                      icon: Icons.share,
                      onPressed: () => unawaited(_share()),
                    ),
                  ),
                  const SizedBox(height: ClockTheme.reportActionGap),
                  Center(
                    child: _PillButton(
                      label: strings.matchReportEnd,
                      onPressed: widget.onEnd,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El acta propiamente dicha, que es lo que entra en la foto.
///
/// Va aparte de la pantalla porque son dos cosas con límites distintos: esto
/// se comparte y los botones no, y tenerlo separado es lo que deja marcar
/// exactamente dónde acaba la imagen.
class _Document extends StatelessWidget {
  const _Document({
    required this.nameOfOne,
    required this.nameOfTwo,
    required this.oneSeconds,
    required this.twoSeconds,
    required this.playSeconds,
    required this.total,
    required this.turnsOfOne,
    required this.turnsOfTwo,
  });

  final String nameOfOne;
  final String nameOfTwo;
  final int oneSeconds;
  final int twoSeconds;
  final int playSeconds;
  final Duration total;
  final List<Duration> turnsOfOne;
  final List<Duration> turnsOfTwo;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(text: strings.matchReportHeading),
        const SizedBox(height: ClockTheme.reportHeadingGap),
        _PlayTime(
          label: strings.matchReportPlayTime,
          playSeconds: playSeconds,
          total: total,
        ),
        const SizedBox(height: ClockTheme.reportHeadingGap),
        // El reparto entre los dos, que es lo que de verdad se compara. Las
        // etiquetas van encima y fuera de la barra: dentro, al jugador que
        // menos consumió no le cabe la suya.
        //
        // Son además la leyenda de la gráfica de abajo, que usa estos mismos
        // dos colores: el nombre va pegado a su color, así que quién es quién
        // no depende de distinguirlos.
        _SplitLabels(
          nameOfOne: nameOfOne,
          nameOfTwo: nameOfTwo,
          oneSeconds: oneSeconds,
          twoSeconds: twoSeconds,
        ),
        const SizedBox(height: ClockTheme.reportBarLabelGap),
        _SplitBar(oneSeconds: oneSeconds, twoSeconds: twoSeconds),
        // Sin ningún turno cerrado no hay gráfica, y tampoco su rótulo: un
        // encabezado encima de un hueco se lee como que algo ha fallado. Pasa
        // en un partido que se termina sin pasar un solo turno, que no es un
        // partido pero es un estado al que se llega.
        if (turnsOfOne.isNotEmpty || turnsOfTwo.isNotEmpty) ...[
          const SizedBox(height: ClockTheme.reportHeadingGap),
          _Heading(text: strings.matchReportPerTurn),
          const SizedBox(height: ClockTheme.reportChartGap),
          _TurnChart(
            nameOfOne: nameOfOne,
            nameOfTwo: nameOfTwo,
            turnsOfOne: turnsOfOne,
            turnsOfTwo: turnsOfTwo,
          ),
        ],
      ],
    );
  }
}

/// Un rótulo de los que nombran lo que viene debajo. Hay dos en el acta, el
/// que dice que el partido ha terminado y el que encabeza la gráfica, y son
/// la misma clase de cosa.
class _Heading extends StatelessWidget {
  const _Heading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    return Text(
      text.toUpperCase(),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: colors.onSurface.withValues(
          alpha: ClockTheme.dimmedContentOpacity,
        ),
        fontSize: ClockTheme.reportHeadingSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// El tiempo de juego, grande, y debajo el total con las pausas dentro.
///
/// Son dos y no uno porque dicen cosas distintas: el de juego es lo que han
/// consumido los relojes y el total lo que ha durado la tarde. Lo parado no
/// lleva fila propia y es la diferencia entre los dos, que están uno encima
/// del otro justamente para que la resta esté a mano.
class _PlayTime extends StatelessWidget {
  const _PlayTime({
    required this.label,
    required this.playSeconds,
    required this.total,
  });

  final String label;
  final int playSeconds;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = ClockColors.of(context);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.onSurface.withValues(
              alpha: ClockTheme.dimmedContentOpacity,
            ),
            fontSize: ClockTheme.reportFigureSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: ClockTheme.reportHeroGap),
        Text(
          formatElapsed(Duration(seconds: playSeconds)),
          // Sin cifras tabulares: alinean columnas, y esta cifra no está en
          // ninguna. A este tamaño lo único que harían es separar los dígitos.
          style: TextStyle(
            color: colors.onSurface,
            fontSize: ClockTheme.reportHeroSize,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: ClockTheme.reportHeroGap),
        Text(
          strings.matchReportTotalTime(formatElapsed(total)),
          style: TextStyle(
            color: colors.onSurface.withValues(
              alpha: ClockTheme.dimmedContentOpacity,
            ),
            fontSize: ClockTheme.reportFigureSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Los dos nombres con su tiempo, uno a cada lado y encima de la barra, cada
/// uno del lado por el que crece su tramo.
class _SplitLabels extends StatelessWidget {
  const _SplitLabels({
    required this.nameOfOne,
    required this.nameOfTwo,
    required this.oneSeconds,
    required this.twoSeconds,
  });

  final String nameOfOne;
  final String nameOfTwo;
  final int oneSeconds;
  final int twoSeconds;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _SideLabel(
            name: nameOfOne,
            seconds: oneSeconds,
            accent: colors.reportAccentOf(Player.one),
            alignEnd: false,
          ),
        ),
        const SizedBox(width: ClockTheme.reportAccentGap),
        Expanded(
          child: _SideLabel(
            name: nameOfTwo,
            seconds: twoSeconds,
            accent: colors.reportAccentOf(Player.two),
            alignEnd: true,
          ),
        ),
      ],
    );
  }
}

/// El nombre de un jugador con su pastilla y su tiempo, volcado hacia su lado
/// de la barra.
class _SideLabel extends StatelessWidget {
  const _SideLabel({
    required this.name,
    required this.seconds,
    required this.accent,
    required this.alignEnd,
  });

  final String name;
  final int seconds;
  final Color accent;

  /// Si va pegado al borde derecho, que es el lado del jugador dos.
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = ClockColors.of(context);
    final time = formatElapsed(Duration(seconds: seconds));

    final dot = Container(
      width: ClockTheme.reportAccentSize,
      height: ClockTheme.reportAccentSize,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(ClockTheme.reportAccentSize / 4),
      ),
    );

    final label = Flexible(
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: colors.onSurface.withValues(
            alpha: ClockTheme.dimmedContentOpacity,
          ),
          fontSize: ClockTheme.reportPlayerNameSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    // La fila se anuncia entera: suelta, un lector de pantalla leería el
    // nombre y la cifra como dos cosas sin relación, y la pastilla no tiene
    // nada que anunciar porque el nombre ya dice de quién es.
    return Semantics(
      label: strings.matchReportPlayed(name, time),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: alignEnd
                ? [
                    label,
                    const SizedBox(width: ClockTheme.reportAccentGap / 2),
                    dot,
                  ]
                : [
                    dot,
                    const SizedBox(width: ClockTheme.reportAccentGap / 2),
                    label,
                  ],
          ),
          const SizedBox(height: 2),
          Text(
            time,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: ClockTheme.reportPlayerTimeSize,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// La barra enfrentada: el tramo de cada jugador crece desde su borde y los
/// dos se encuentran donde cae el reparto. Quien consumió más ocupa más, y
/// dónde se tocan es la respuesta de un vistazo.
///
/// Entre los dos tramos va un hueco del color del fondo y no un borde
/// alrededor de cada uno: el hueco los separa sin añadir una línea que no
/// significa nada. Los extremos de fuera van redondeados y los de dentro no,
/// porque los de dentro son el punto de encuentro y redondearlos lo
/// desdibujaría.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.oneSeconds, required this.twoSeconds});

  final int oneSeconds;
  final int twoSeconds;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    const radius = Radius.circular(ClockTheme.reportBarRadius);

    return LayoutBuilder(
      builder: (context, constraints) {
        final total = oneSeconds + twoSeconds;
        final usable = constraints.maxWidth - ClockTheme.reportBarGap;
        // Un partido sin tiempo no se reparte: se enseña a medias, que es lo
        // único honesto cuando no hay nada que comparar.
        final oneWidth = total == 0
            ? usable / 2
            : usable * oneSeconds / total;

        return SizedBox(
          height: ClockTheme.reportBarHeight,
          child: Row(
            // Los dos tramos se estiran hasta el alto de la barra. Sin esto
            // la fila los centra, que es alinearlos sin darles alto: una caja
            // pintada y sin hijo con el alto holgado se queda en cero, y la
            // barra existe pero no se ve.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                key: MatchReport.barKeyOne,
                width: oneWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.reportAccentOf(Player.one),
                    borderRadius: const BorderRadius.horizontal(left: radius),
                  ),
                ),
              ),
              const SizedBox(width: ClockTheme.reportBarGap),
              Expanded(
                child: DecoratedBox(
                  key: MatchReport.barKeyTwo,
                  decoration: BoxDecoration(
                    color: colors.reportAccentOf(Player.two),
                    borderRadius: const BorderRadius.horizontal(right: radius),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// La gráfica de lo que duró cada turno, una línea por jugador.
///
/// Un solo eje de tiempo para las dos líneas, que es lo que las hace
/// comparables: con una escala para cada una, la forma de la gráfica diría
/// cosas que no están en los datos.
///
/// No lleva punto en cada turno ni número en cada punto. Lo único que se
/// señala es el turno más largo de cada uno, que es lo que se busca al mirar
/// esto: dónde se atascó la partida. Lo demás lo dice el eje.
class _TurnChart extends StatelessWidget {
  const _TurnChart({
    required this.nameOfOne,
    required this.nameOfTwo,
    required this.turnsOfOne,
    required this.turnsOfTwo,
  });

  final String nameOfOne;
  final String nameOfTwo;
  final List<Duration> turnsOfOne;
  final List<Duration> turnsOfTwo;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = ClockColors.of(context);

    final one = turnsOfOne.map((t) => t.inSeconds).toList();
    final two = turnsOfTwo.map((t) => t.inSeconds).toList();

    // Sin un solo turno cerrado no hay nada que dibujar, y una gráfica vacía
    // con sus ejes es peor que no ponerla: parece que algo ha fallado.
    if (one.isEmpty && two.isEmpty) return const SizedBox.shrink();

    final peakOne = _peakOf(one);
    final peakTwo = _peakOf(two);

    // La gráfica es una imagen, así que lo que dice se cuenta aparte: para
    // quien no la ve, el dato que se señala es el mismo que se señala en ella.
    final summary = [
      if (peakOne != null)
        strings.matchReportPeak(
          nameOfOne,
          formatElapsed(Duration(seconds: one[peakOne])),
          peakOne + 1,
        ),
      if (peakTwo != null)
        strings.matchReportPeak(
          nameOfTwo,
          formatElapsed(Duration(seconds: two[peakTwo])),
          peakTwo + 1,
        ),
    ].join('. ');

    return Semantics(
      label: '${strings.matchReportPerTurn}. $summary',
      excludeSemantics: true,
      child: SizedBox(
        // El alto incluye la banda de las etiquetas del eje: contar solo el
        // dibujo las deja fuera de la caja y se recortan.
        height: ClockTheme.reportChartHeight + ClockTheme.reportChartAxisBand,
        child: CustomPaint(
          painter: _TurnChartPainter(
            one: one,
            two: two,
            colorOne: colors.reportAccentOf(Player.one),
            colorTwo: colors.reportAccentOf(Player.two),
            ink: colors.onSurface,
            surface: colors.background,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }

  /// Dónde está el turno más largo de un jugador, que es el único punto que
  /// la gráfica señala. Nulo si todavía no ha cerrado ninguno.
  static int? _peakOf(List<int> values) {
    if (values.isEmpty) return null;
    var index = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[index]) index = i;
    }
    return index;
  }
}

class _TurnChartPainter extends CustomPainter {
  _TurnChartPainter({
    required this.one,
    required this.two,
    required this.colorOne,
    required this.colorTwo,
    required this.ink,
    required this.surface,
    required this.textDirection,
  });

  final List<int> one;
  final List<int> two;
  final Color colorOne;
  final Color colorTwo;
  final Color ink;

  /// El color del fondo, que es con el que se abre el anillo alrededor de la
  /// marca cuando las dos líneas se cruzan justo ahí.
  final Color surface;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final turns = math.max(one.length, two.length);
    if (turns == 0) return;

    final maxSeconds = _niceCeiling(
      math.max(
        one.isEmpty ? 0 : one.reduce(math.max),
        two.isEmpty ? 0 : two.reduce(math.max),
      ),
    );

    // Lo que se le reserva a cada eje: a la izquierda las etiquetas de tiempo
    // y abajo las de turno. El dibujo es lo que queda, y se mete hacia dentro
    // el radio de la marca por los dos lados, porque la del primer turno y la
    // del último caen justo en el borde y se cortarían por la mitad.
    final inset =
        ClockTheme.reportChartPeakRadius + ClockTheme.reportChartPeakRing;
    final leftGutter =
        _measure(formatElapsed(Duration(seconds: maxSeconds))).width + 6;
    final plot = Rect.fromLTRB(
      leftGutter + inset,
      inset,
      size.width - inset,
      size.height - ClockTheme.reportChartAxisBand,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    _paintGrid(canvas, plot, turns);
    _paintSeries(canvas, plot, one, colorOne, maxSeconds, turns);
    _paintSeries(canvas, plot, two, colorTwo, maxSeconds, turns);
    _paintAxisLabels(canvas, plot, size, maxSeconds, turns);
  }

  /// La retícula: continua, fina y un tono por encima del fondo. Va por
  /// detrás y no compite con las dos líneas.
  void _paintGrid(Canvas canvas, Rect plot, int turns) {
    final paint = Paint()
      ..color = ink.withValues(alpha: ClockTheme.reportGridOpacity)
      ..strokeWidth = ClockTheme.reportGridWidth
      ..style = PaintingStyle.stroke;

    for (final fraction in const [0.0, 0.5, 1.0]) {
      final y = plot.bottom - plot.height * fraction;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), paint);
    }

    // La raya de la media parte, que es lo único vertical que se dibuja: parte
    // la gráfica donde se partió el partido, y sin ella los dieciséis turnos
    // se leen como una sola tirada.
    if (turns > TurnCount.turnsPerHalf) {
      final x = _xFor(plot, TurnCount.turnsPerHalf - 0.5, turns);
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), paint);
    }
  }

  void _paintSeries(
    Canvas canvas,
    Rect plot,
    List<int> values,
    Color color,
    int maxSeconds,
    int turns,
  ) {
    if (values.isEmpty) return;

    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          _xFor(plot, i.toDouble(), turns),
          _yFor(plot, values[i], maxSeconds),
        ),
    ];

    final line = Paint()
      ..color = color
      ..strokeWidth = ClockTheme.reportChartLineWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    if (points.length == 1) {
      canvas.drawCircle(points.first, ClockTheme.reportChartLineWidth, line);
    } else {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, line);
    }

    // El turno más largo, y solo ese. El anillo del color del fondo lo
    // despega de la otra línea cuando las dos pasan por el mismo sitio.
    var peak = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[peak]) peak = i;
    }
    final centre = points[peak];
    canvas.drawCircle(
      centre,
      ClockTheme.reportChartPeakRadius + ClockTheme.reportChartPeakRing,
      Paint()..color = surface,
    );
    canvas.drawCircle(
      centre,
      ClockTheme.reportChartPeakRadius,
      Paint()..color = color,
    );
  }

  void _paintAxisLabels(
    Canvas canvas,
    Rect plot,
    Size size,
    int maxSeconds,
    int turns,
  ) {
    // El eje de tiempo: el techo y la mitad. El cero no se rotula, que se da
    // por sabido y una etiqueta más ahí solo aprieta.
    for (final fraction in const [0.5, 1.0]) {
      final seconds = (maxSeconds * fraction).round();
      final painter = _measure(formatElapsed(Duration(seconds: seconds)));
      final y = plot.bottom - plot.height * fraction;
      painter.paint(
        canvas,
        Offset(plot.left - painter.width - 6, y - painter.height / 2),
      );
    }

    // El eje de turnos: el primero, el último y el cambio de parte. No se
    // rotulan los dieciséis, que no caben y no hacen falta para leer la forma.
    final marks = <int>{
      1,
      if (turns > TurnCount.turnsPerHalf) TurnCount.turnsPerHalf,
      turns,
    };
    for (final turn in marks) {
      final painter = _measure('$turn');
      final x = _xFor(plot, turn - 1.0, turns);
      painter.paint(
        canvas,
        Offset(
          (x - painter.width / 2).clamp(0.0, size.width - painter.width),
          plot.bottom + 4,
        ),
      );
    }
  }

  double _xFor(Rect plot, double index, int turns) =>
      turns <= 1 ? plot.center.dx : plot.left + plot.width * index / (turns - 1);

  double _yFor(Rect plot, int seconds, int maxSeconds) => maxSeconds == 0
      ? plot.bottom
      : plot.bottom - plot.height * seconds / maxSeconds;

  TextPainter _measure(String text) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: ink.withValues(alpha: ClockTheme.dimmedContentOpacity),
        fontSize: ClockTheme.reportChartLabelSize,
        fontWeight: FontWeight.w500,
        // Aquí sí: las etiquetas del eje se alinean unas con otras, que es
        // para lo que están las cifras tabulares.
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
    textDirection: textDirection,
  )..layout();

  /// Redondea el techo del eje al medio minuto de más arriba, para que las
  /// etiquetas caigan en números que se leen y no en un 3:47 cualquiera.
  static int _niceCeiling(int seconds) {
    if (seconds <= 0) return 30;
    const step = 30;
    return ((seconds + step - 1) ~/ step) * step;
  }

  @override
  bool shouldRepaint(_TurnChartPainter old) =>
      !listEquals(old.one, one) ||
      !listEquals(old.two, two) ||
      old.colorOne != colorOne ||
      old.colorTwo != colorTwo ||
      old.ink != ink;
}

/// Los dos botones del acta, que tienen la misma forma que el de Time-Out del
/// velo: una pastilla con su texto.
///
/// El texto no se quita ni cuando hay icono. Compartir sí tiene un icono que
/// se entiende sin aprendérselo, al revés que terminar el partido, pero si
/// uno de los dos llevara solo icono dejarían de parecer dos botones del
/// mismo tipo puestos uno encima del otro.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;

  /// Nulo es una pastilla de solo texto, que es lo que lleva terminar.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    final iconData = icon;

    return Material(
      color: colors.controlSurface,
      shape: const StadiumBorder(),
      elevation: ClockTheme.controlElevation,
      shadowColor: colors.controlShadow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ClockTheme.veilButtonHorizontalPadding,
            vertical: ClockTheme.veilButtonVerticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconData != null) ...[
                Icon(
                  iconData,
                  size: ClockTheme.reportButtonIconSize,
                  color: colors.onSurface,
                ),
                const SizedBox(width: ClockTheme.reportButtonIconGap),
              ],
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: ClockTheme.veilButtonTextSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
