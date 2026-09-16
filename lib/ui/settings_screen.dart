import 'package:flutter/material.dart';

import '../domain/match_settings.dart';
import '../l10n/app_localizations.dart';
import 'clock_theme.dart';

/// Los tres tiempos, cada uno con su deslizador. Vive fuera de la pantalla
/// principal para no estorbar durante la partida: la aplicación sigue
/// abriendo directamente en el cronómetro.
///
/// Un cambio se guarda y se aplica al momento. No hay botón de aceptar: lo
/// que se ve es lo que hay, y el partido en curso se redimensiona solo.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.settings, super.key});

  final MatchSettings settings;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: ClockTheme.background,
      appBar: AppBar(
        backgroundColor: ClockTheme.background,
        foregroundColor: ClockTheme.text,
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
              _TimeSetting(
                name: strings.settingsWarning,
                hint: strings.settingsWarningHint,
                value: strings.seconds(settings.warning.inSeconds),
                amount: settings.warning.inSeconds.toDouble(),
                min: _minWarningSeconds,
                max: _maxWarningSeconds,
                divisions: _warningDivisions,
                onChanged: (seconds) =>
                    settings.save(warning: Duration(seconds: seconds.round())),
              ),
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
const _minWarningSeconds = 5.0;
const _maxWarningSeconds = 60.0;

/// El aviso previo va de cinco en cinco segundos, no de uno en uno: afinarlo
/// al segundo no le dice nada a nadie. Once tramos entre cinco y sesenta.
const _warningDivisions = 11;

class _TimeSetting extends StatelessWidget {
  const _TimeSetting({
    required this.name,
    required this.hint,
    required this.value,
    required this.amount,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String name;
  final String hint;
  final String value;
  final double amount;
  final double min;
  final double max;

  /// Los tramos en los que se parte el deslizador. Nulo para los que van de
  /// uno en uno, que son los dos de minutos.
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(
                  color: ClockTheme.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: ClockTheme.text,
                  fontSize: 17,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Text(
            hint,
            style: TextStyle(
              color: ClockTheme.text.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
          Slider(
            value: amount.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions ?? (max - min).round(),
            activeColor: ClockTheme.active,
            inactiveColor: ClockTheme.text.withValues(alpha: 0.14),
            label: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
