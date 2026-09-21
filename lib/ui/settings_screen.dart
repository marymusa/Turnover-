import 'package:flutter/material.dart';

import '../domain/match_settings.dart';
import '../l10n/app_localizations.dart';
import 'clock_colors.dart';
import 'touch_feedback.dart';

/// Los tiempos configurables, con un deslizador cada uno: el del turno, el del
/// tiempo extra y el de los dos avisos previos, que lleva dos agarres y por eso
/// cubre dos tiempos con un solo control. Vive fuera de la pantalla principal
/// para no estorbar durante la partida: la aplicación sigue abriendo
/// directamente en el cronómetro.
///
/// Un cambio se guarda y se aplica al momento. No hay botón de aceptar: lo
/// que se ve es lo que hay, y el partido en curso se redimensiona solo.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.settings, super.key});

  final MatchSettings settings;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = ClockColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        title: Text(strings.settings),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              _TimeSetting(
                name: strings.settingsTurn,
                hint: strings.settingsTurnHint,
                value: strings.minutes(settings.turn.inMinutes),
                amount: settings.turn.inMinutes.toDouble(),
                min: _minTurnMinutes,
                max: _maxTurnMinutes,
                onChanged: (minutes) =>
                    settings.save(turn: Duration(minutes: minutes.round())),
              ),
              _TimeSetting(
                name: strings.settingsReserve,
                hint: strings.settingsReserveHint,
                value: strings.minutes(settings.reserve.inMinutes),
                amount: settings.reserve.inMinutes.toDouble(),
                min: _minReserveMinutes,
                max: _maxReserveMinutes,
                onChanged: (minutes) =>
                    settings.save(reserve: Duration(minutes: minutes.round())),
              ),
              _WarningSetting(settings: settings, strings: strings),
            ],
          ),
        ),
      ),
    );
  }
}

/// Los extremos de cada deslizador. No son reglas del dominio: solo evitan
/// que un resbalón deje el turno en cero o la reserva en dos horas.
const _minTurnMinutes = 1.0;
const _maxTurnMinutes = 10.0;
const _minReserveMinutes = 1.0;
const _maxReserveMinutes = 30.0;

/// Los avisos previos sí llegan a cero, que es apagarlos: el turno se acaba sin
/// avisar antes. Son los únicos que se pueden desactivar, porque los otros dos
/// son el tiempo del partido y sin ellos no hay nada que medir.
const _minWarningSeconds = 0.0;

/// El tope se queda por debajo del turno más corto, que es un minuto: un aviso
/// a los sesenta segundos de un turno de sesenta sonaría al arrancar, y eso no
/// avisa de nada.
const _maxWarningSeconds = 55.0;

/// Los avisos previos van de cinco en cinco segundos, no de uno en uno:
/// afinarlos al segundo no le dice nada a nadie. Once tramos hasta cincuenta y
/// cinco.
const _warningDivisions = 11;

/// Cuándo se avisa, con los dos agarres del mismo deslizador. Se lee entero
/// sin explicar nada: juntos son un aviso, separados son dos, y los dos en
/// cero es no avisar.
///
/// El deslizador mide cuánto queda cuando suena el aviso, así que el agarre de
/// la derecha, el del número mayor, es el que suena antes. Es lo que obliga a
/// cruzar el orden: `RangeSlider` exige `start <= end`, y el aviso temprano es
/// el de más segundos.
class _WarningSetting extends StatefulWidget {
  const _WarningSetting({required this.settings, required this.strings});

  final MatchSettings settings;
  final AppLocalizations strings;

  @override
  State<_WarningSetting> createState() => _WarningSettingState();
}

/// Con estado por lo mismo que [_TimeSetting], y con un paso por agarre: mover
/// el de la izquierda no puede hacer sonar al de la derecha, que no se ha
/// movido. Dos agarres, dos pasos anteriores.
class _WarningSettingState extends State<_WarningSetting> {
  int? _lastStart;
  int? _lastEnd;

  /// Un tacto por movimiento aunque se muevan los dos agarres a la vez: lo que
  /// se nota es que el control ha pasado de paso, no cuántos agarres lo han
  /// hecho.
  void _detentIfStepChanged(RangeValues values) {
    final start = values.start.round();
    final end = values.end.round();
    if (start != _lastStart || end != _lastEnd) {
      _lastStart = start;
      _lastEnd = end;
      TouchFeedback.detent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final strings = widget.strings;
    final earlySeconds = settings.earlyWarning.inSeconds.toDouble().clamp(
      _minWarningSeconds,
      _maxWarningSeconds,
    );
    final lateSeconds = settings.warning.inSeconds.toDouble().clamp(
      _minWarningSeconds,
      _maxWarningSeconds,
    );

    // El aviso temprano apagado se guarda como cero, que cae por debajo del
    // tardío: el agarre de la derecha se posa encima del otro, que es como se
    // ve un solo aviso.
    final rightHandle = earlySeconds < lateSeconds ? lateSeconds : earlySeconds;
    final colors = ClockColors.of(context);

    return _Setting(
      name: strings.settingsWarning,
      hint: strings.settingsWarningHint,
      value: _valueText(earlySeconds, lateSeconds),
      child: RangeSlider(
        values: RangeValues(lateSeconds, rightHandle),
        min: _minWarningSeconds,
        max: _maxWarningSeconds,
        divisions: _warningDivisions,
        activeColor: colors.active,
        inactiveColor: colors.onSurface.withValues(alpha: 0.14),
        labels: RangeLabels(
          strings.seconds(lateSeconds.round()),
          strings.seconds(earlySeconds.round()),
        ),
        onChangeStart: (values) {
          _lastStart = values.start.round();
          _lastEnd = values.end.round();
        },
        onChanged: (values) {
          _detentIfStepChanged(values);
          settings.save(
            warning: Duration(seconds: values.start.round()),
            earlyWarning: Duration(seconds: values.end.round()),
          );
        },
      ),
    );
  }

  /// Los dos agarres en cero no se leen como "0 s" sino como lo que significan:
  /// que no hay avisos. Juntos por encima de cero son un aviso, y solo
  /// separados se enseñan los dos. Con el tardío en cero y el temprano arriba
  /// queda un aviso, el temprano, que es el que se enseña.
  String _valueText(double early, double late) {
    final strings = widget.strings;
    if (early <= 0 && late <= 0) return strings.settingsWarningOff;
    if (late <= 0) return strings.seconds(early.round());
    if (early <= late) return strings.seconds(late.round());
    return strings.secondsRange(early.round(), late.round());
  }
}

class _TimeSetting extends StatefulWidget {
  const _TimeSetting({
    required this.name,
    required this.hint,
    required this.value,
    required this.amount,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String name;
  final String hint;
  final String value;
  final double amount;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  State<_TimeSetting> createState() => _TimeSettingState();
}

/// Con estado solo por el tacto: lo que guarda es en qué paso estaba el dedo la
/// última vez, para responder al cruzar de uno a otro y no en cada movimiento.
///
/// El paso anterior no se puede leer de `amount`, que es lo que ya está
/// guardado. `MatchSettings.save` escribe en disco antes de avisar, así que
/// durante un arrastre rápido llegan varios avisos de cambio antes de que
/// `amount` se entere: comparando contra él saldrían varios tactos en el mismo
/// paso y ninguno en el siguiente. Por eso el paso de partida lo fija
/// `onChangeStart`, que es exacto y no depende de ninguna escritura.
class _TimeSettingState extends State<_TimeSetting> {
  int? _lastStep;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    return _Setting(
      name: widget.name,
      hint: widget.hint,
      value: widget.value,
      child: Slider(
        value: widget.amount.clamp(widget.min, widget.max),
        min: widget.min,
        max: widget.max,
        divisions: (widget.max - widget.min).round(),
        activeColor: colors.active,
        inactiveColor: colors.onSurface.withValues(alpha: 0.14),
        label: widget.value,
        onChangeStart: (value) => _lastStep = value.round(),
        onChanged: (value) {
          final step = value.round();
          if (step != _lastStep) {
            _lastStep = step;
            TouchFeedback.detent();
          }
          widget.onChanged(value);
        },
      ),
    );
  }
}

/// El nombre, lo que vale ahora y la explicación, con su control debajo. Lo
/// que cambia entre un ajuste y otro es el control, no la cabecera.
class _Setting extends StatelessWidget {
  const _Setting({
    required this.name,
    required this.hint,
    required this.value,
    required this.child,
  });

  final String name;
  final String hint;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = ClockColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontFeatures: [FontFeature.tabularFigures()],
                ).copyWith(color: colors.onSurface),
              ),
            ],
          ),
          Text(
            hint,
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
