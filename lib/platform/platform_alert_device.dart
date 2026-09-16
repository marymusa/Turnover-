/// El adaptador que toca la plataforma: reproduce las bocinas y hace vibrar.
/// Nada del dominio entra aquí más allá de [AlertSound].
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../domain/alert_player.dart';
import '../domain/match_alerts.dart';

/// Lo que separa dos pulsaciones seguidas, para que se noten como dos y no
/// como una sola larga.
const _gapBetweenPulses = Duration(milliseconds: 150);

class PlatformAlertDevice implements AlertDevice {
  PlatformAlertDevice()
    : _players = {
        for (final sound in AlertSound.values)
          sound: AudioPlayer()..setReleaseMode(ReleaseMode.stop),
      };

  /// Un reproductor por bocina, ya cargado: dos avisos seguidos no se pisan y
  /// el sonido sale sin esperar a leer el fichero.
  final Map<AlertSound, AudioPlayer> _players;

  /// Se llama una vez antes del primer aviso.
  ///
  /// `respectSilence` es lo que hace que el móvil en silencio no suene: la
  /// decisión la toma el sistema y la aplicación no lee el estado del timbre
  /// ni impone nada por encima.
  Future<void> prepare() async {
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(respectSilence: true).build(),
    );
    await Future.wait([
      for (final entry in _players.entries) _load(entry.key, entry.value),
    ]);
  }

  Future<void> _load(AlertSound sound, AudioPlayer player) async {
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setSource(AssetSource(sound.asset));
  }

  @override
  Future<void> play(AlertSound sound) async {
    final player = _players[sound];
    if (player == null) return;
    // Volver al principio: el mismo reproductor puede estar sonando todavía.
    await player.seek(Duration.zero);
    await player.resume();
  }

  /// Las pulsaciones salen por el canal normal de vibración, que es el que el
  /// sistema silencia cuando el jugador apaga la vibración. No se usa el canal
  /// de alarma, que está exento de esa configuración justamente para poder
  /// saltársela: aquí no hay nada que imponer por encima del móvil.
  @override
  Future<void> vibrate(int pulses) async {
    for (var pulse = 0; pulse < pulses; pulse++) {
      if (pulse > 0) await Future<void>.delayed(_gapBetweenPulses);
      await HapticFeedback.heavyImpact();
    }
  }
}
