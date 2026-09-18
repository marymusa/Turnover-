import 'dart:async';

import 'package:flutter/material.dart';

import 'clock_theme.dart';
import 'logo_outline.dart';

/// El escudo, que se presenta dibujándose solo: un punto recorre su contorno
/// dejando el trazo detrás, y al cerrarlo aparece el escudo entero y el trazo
/// se desvanece. Una sola vez, al entrar en la pantalla.
///
/// Se queda quieto al terminar: esta pantalla es la antesala de un partido, y
/// algo moviéndose sin parar al lado de los relojes acaba cansando.
class _RevealedLogo extends StatefulWidget {
  const _RevealedLogo({
    required this.trace,
    required this.settle,
    required this.onOutlineReady,
  });

  /// Lo que recorre el cometa, de cero a uno. Manda sobre todo lo demás: hasta
  /// que no cierra el contorno no entra nada.
  final Animation<double> trace;

  /// La entrada del escudo: empieza al cerrarse el contorno y acaba con él.
  final Animation<double> settle;

  /// Avisa de que el contorno ya está resuelto, con o sin éxito. Quien manda
  /// la animación no puede arrancarla antes: no habría nada que dibujar.
  final ValueChanged<LogoOutline?> onOutlineReady;

  @override
  State<_RevealedLogo> createState() => _RevealedLogoState();
}

class _RevealedLogoState extends State<_RevealedLogo> {
  /// El contorno tarda en llegar, y hasta entonces no hay nada que dibujar.
  LogoOutline? _outline;

  @override
  void initState() {
    super.initState();
    unawaited(_loadOutline());
  }

  /// Si el contorno no se puede leer, la presentación se da por hecha en vez
  /// de quedarse a medias: lo que hay detrás de ella, la invitación a empezar,
  /// no puede depender de que un adorno haya cargado.
  Future<void> _loadOutline() async {
    LogoOutline? outline;
    try {
      outline = await LogoOutline.load();
    } on Object {
      outline = null;
    }
    if (!mounted) return;
    setState(() => _outline = outline);
    widget.onOutlineReady(outline);
  }

  @override
  Widget build(BuildContext context) {
    const size = ClockTheme.leagueLogoSize;
    final logo = Image.asset(
      'assets/images/league_logo.png',
      width: size,
      height: size,
    );

    // Sin contorno no hay nada que dibujar, pero el escudo sí se enseña: la
    // presentación es el adorno, y el escudo es lo que de verdad va aquí.
    final outline = _outline;
    if (outline == null) {
      return SizedBox.square(dimension: size, child: logo);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([widget.trace, widget.settle]),
      child: logo,
      builder: (context, child) {
        return SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // El escudo entra cuando el cometa ya ha cerrado la silueta: es
              // lo que hace que parezca el resultado de haberla dibujado.
              Opacity(opacity: widget.settle.value, child: child),
              CustomPaint(
                size: const Size.square(size),
                painter: _OutlinePainter(
                  outline: outline,
                  progress: widget.trace.value,
                  fade: widget.settle.value,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pinta el contorno del escudo: el trazo ya recorrido y, en la cabeza, el
/// punto que lo va dejando.
///
/// [progress] es lo que lleva recorrido el cometa y [fade] lo que ha entrado
/// ya el escudo: el trazo se apaga a medida que el escudo aparece, de modo que
/// lo dibujado se convierte en el escudo en vez de desaparecer antes.
class _OutlinePainter extends CustomPainter {
  const _OutlinePainter({
    required this.outline,
    required this.progress,
    required this.fade,
  });

  final LogoOutline outline;
  final double progress;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = 1 - fade;
    if (opacity <= 0 || progress <= 0) return;

    final path = Path();
    for (final (index, point) in outline.points.indexed) {
      final offset = Offset(point.$1 * size.width, point.$2 * size.height);
      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    path.close();

    final metric = path.computeMetrics().first;
    final head = metric.length * progress;

    // La cola es lo que separa la cabeza brillante del trazo apagado que va
    // quedando: se dibujan por separado porque llevan grosor y color propios.
    final tailStart = (head - ClockTheme.logoRevealTailLength).clamp(
      0.0,
      metric.length,
    );

    final trail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ClockTheme.logoRevealTrailWidth
      ..strokeCap = StrokeCap.round
      ..color = ClockTheme.logoRevealColor.withValues(
        alpha: ClockTheme.logoRevealTrailAlpha * opacity,
      );
    canvas.drawPath(metric.extractPath(0, tailStart), trail);

    final comet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ClockTheme.logoRevealHeadWidth
      ..strokeCap = StrokeCap.round
      ..color = ClockTheme.logoRevealColor.withValues(alpha: opacity);
    canvas.drawPath(metric.extractPath(tailStart, head), comet);
  }

  @override
  bool shouldRepaint(_OutlinePainter old) =>
      old.progress != progress || old.fade != fade;
}

/// El escudo de la liga en el centro del campo, donde la línea central parte
/// las veintiséis casillas en dos mitades de trece. Ocupa la costura, que
/// antes de empezar está vacía, y desaparece en cuanto el partido arranca y
/// los controles la necesitan.
///
/// La línea que lo acompañaba se quitó al meter las mitades en tarjetas: el
/// hueco que queda entre las dos ya parte el campo, y la línea encima cruzaba
/// ese hueco cortando los bordes de ambas.
///
/// Es decoración y nada más: no recibe el toque, que tiene que seguir llegando
/// a la mitad que hay debajo para elegir quién recibe la patada inicial.
class LeagueCrest extends StatefulWidget {
  const LeagueCrest({required this.onRevealed, super.key});

  /// Se llama al terminar la presentación entera.
  final VoidCallback onRevealed;

  @override
  State<LeagueCrest> createState() => _LeagueCrestState();
}

class _LeagueCrestState extends State<LeagueCrest>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: ClockTheme.logoTraceDuration + ClockTheme.logoSettleDuration,
  );

  /// El cometa manda: mientras recorre el contorno no hay nada más, y al
  /// cerrarlo arrancan a la vez el escudo y la línea, que tardan lo mismo.
  static final _traceShare =
      ClockTheme.logoTraceDuration.inMilliseconds /
      (ClockTheme.logoTraceDuration + ClockTheme.logoSettleDuration)
          .inMilliseconds;

  late final Animation<double> _trace = CurvedAnimation(
    parent: _controller,
    curve: Interval(0, _traceShare),
  );

  /// El escudo y la línea comparten intervalo: el mismo principio y el mismo
  /// final, que es lo que hace que se vean como un solo gesto.
  late final Animation<double> _settle = CurvedAnimation(
    parent: _controller,
    curve: Interval(_traceShare, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            _RevealedLogo(
              trace: _trace,
              settle: _settle,
              // Arrancar aquí y no en `initState`: hasta que el contorno no
              // está leído no hay nada que dibujar, y la animación se comería
              // sus primeros fotogramas con el escudo todavía vacío.
              onOutlineReady: (outline) => unawaited(_runReveal(outline)),
            ),
          ],
        ),
      ),
    );
  }

  /// Avisa al terminar, que es cuando la pantalla puede enseñar lo que estaba
  /// esperando: la invitación a empezar no se pone encima de la presentación.
  ///
  /// Sin contorno no hay nada que presentar, así que se salta la animación y
  /// se avisa igual: la invitación no puede quedarse esperando a un adorno.
  Future<void> _runReveal(LogoOutline? outline) async {
    if (outline != null) {
      await _controller.forward();
    } else {
      _controller.value = 1;
    }
    if (mounted) widget.onRevealed();
  }
}

