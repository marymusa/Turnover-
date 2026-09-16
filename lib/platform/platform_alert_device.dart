/// El adaptador que toca la plataforma: reproduce las bocinas y hace vibrar.
/// Nada del dominio entra aquí más allá de [AlertSound].
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../domain/alert_player.dart';
import '../domain/match_alerts.dart';

/// El canal propio de vibración. Flutter no trae ninguna abstracción sobre el
/// motor: `HapticFeedback` es lo único que hay y su propia documentación avisa
/// de que no sirve para controlarlo con precisión. Además sale por el canal de
/// las hápticas de la vista, que el móvil apaga con la casilla de la vibración
/// al tocar la pantalla, y entonces ningún aviso se nota (ADR-0005).
const _vibrationChannel = MethodChannel('com.ares.bloodbowl.turnover/vibration');

class PlatformAlertDevice implements AlertDevice {
  /// Un reproductor por bocina, ya cargado: dos avisos seguidos no se pisan y
  /// el sonido sale sin esperar a leer el fichero. Se llenan en [prepare], no
  /// al construir, y el motivo está allí explicado.
  final Map<AlertSound, AudioPlayer> _players = {};

  /// Se llama una vez antes del primer aviso.
  ///
  /// `respectSilence` es lo que hace que el móvil en silencio no suene: la
  /// decisión la toma el sistema y la aplicación no lee el estado del timbre
  /// ni impone nada por encima.
  ///
  /// El contexto se fija antes de crear ningún reproductor, y ese orden es lo
  /// único que hace que suenen las tres bocinas. En Android el modo de baja
  /// latencia es un SoundPool, y hay uno por cada configuración de audio: el
  /// reproductor que nace antes de fijar el contexto se queda en el SoundPool
  /// de por defecto y el resto van al nuevo. Con las bocinas repartidas entre
  /// dos, los identificadores de sonido se repiten de un SoundPool a otro, cada
  /// reproductor pide el suyo y le sale el del vecino o ninguno. Sonaba solo la
  /// primera.
  Future<void> prepare() async {
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(respectSilence: true).build(),
    );
    for (final sound in AlertSound.values) {
      _players[sound] = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    }
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
    // `stop` y no `seek`: en modo de baja latencia el reproductor es un
    // SoundPool, que no emite el aviso de fin de búsqueda que `seek` espera.
    // La primera bocina se quedaba treinta segundos colgada ahí y nunca
    // llegaba a sonar. `stop` vuelve al principio igual y sí contesta.
    await player.stop();
    await player.resume();
  }

  /// La vibración sale por el canal de aviso de cada plataforma, que es el que
  /// el sistema silencia cuando el jugador apaga la vibración. No se usa el de
  /// alarma, exento de esa configuración justamente para poder saltársela:
  /// aquí no hay nada que imponer por encima del móvil (ADR-0005).
  ///
  /// El aparato que no tenga motor no hace nada, y eso no es un error: el
  /// aviso sale igual por el altavoz.
  @override
  Future<void> vibrate(VibrationLevel level) async {
    await _vibrationChannel.invokeMethod<void>('vibrate', {
      'level': level.name,
    });
  }
}
