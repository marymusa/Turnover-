import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/alert_player.dart';
import 'package:turnover/domain/match_alerts.dart';
import 'package:turnover/domain/match_clock.dart';

void main() {
  group('lo que se dispara con cada evento', () {
    test('suena y vibra a la vez', () async {
      final device = FakeDevice();
      final player = AlertPlayer(device);

      await player.handle([const MatchEvent(Horn.turnExpired, Player.one)]);

      expect(device.played, [AlertSound.strong]);
      expect(device.vibrated, [alertFor(Horn.turnExpired).vibration]);
    });

    test('cada evento del avance dispara lo suyo', () async {
      final device = FakeDevice();
      final player = AlertPlayer(device);

      await player.handle([
        const MatchEvent(Horn.turnExpired, Player.one),
        const MatchEvent(Horn.reserveWarning, Player.one),
      ]);

      expect(device.played, [AlertSound.strong, AlertSound.soft]);
    });

    test('sin eventos no hace nada', () async {
      final device = FakeDevice();
      final player = AlertPlayer(device);

      await player.handle(const []);

      expect(device.played, isEmpty);
      expect(device.vibrated, isEmpty);
    });
  });

  // Respetar la configuración del sistema, sin imponer nada por encima: quien
  // decide si el sonido sale y si la vibración se nota es el propio móvil. El
  // aviso se pide siempre igual, y el sistema silencia lo que el jugador haya
  // apagado (ADR-0005).
  group('la configuración del sistema', () {
    test('pide siempre las dos cosas, y deja que el móvil decida', () async {
      final device = FakeDevice();
      final player = AlertPlayer(device);

      await player.handle([const MatchEvent(Horn.reserveExpired, Player.one)]);

      expect(device.played, [AlertSound.strongest]);
      expect(device.vibrated, [VibrationLevel.strongest]);
    });

    test('un fallo del aparato no tumba el aviso entero', () async {
      final device = FakeDevice(fails: true);
      final player = AlertPlayer(device);

      await expectLater(
        player.handle([const MatchEvent(Horn.turnWarning, Player.one)]),
        completes,
      );
    });

    // Sin vibrador el aviso sale igual, solo que sin vibrar: es el caso del
    // móvil que no lo tiene, no un error que haya que esconder entero.
    test('lo que sí funciona sale aunque falle lo otro', () async {
      final device = FakeDevice(vibrationFails: true);
      final player = AlertPlayer(device);

      await player.handle([const MatchEvent(Horn.turnWarning, Player.one)]);

      expect(device.played, [AlertSound.soft]);
      expect(device.vibrated, isEmpty);
    });
  });

  group('el jugador inactivo', () {
    // El reloj solo emite eventos del jugador activo, así que no hay nada que
    // filtrar aquí: lo que se comprueba es que el reloj no emite del otro.
    test('no recibe ningún aviso mientras espera', () {
      final clock = MatchClock(
        turn: const Duration(minutes: 4),
        reserve: const Duration(minutes: 15),
        warning: const Duration(seconds: 30),
      );
      clock.start(Player.one);
      final events = clock.advance(const Duration(minutes: 20));

      expect(events.map((event) => event.player), everyElement(Player.one));
    });
  });
}

class FakeDevice implements AlertDevice {
  FakeDevice({this.fails = false, this.vibrationFails = false});

  final bool fails;
  final bool vibrationFails;
  final played = <AlertSound>[];
  final vibrated = <VibrationLevel>[];

  @override
  Future<void> play(AlertSound sound) async {
    if (fails) throw Exception('sin salida de audio');
    played.add(sound);
  }

  @override
  Future<void> vibrate(VibrationLevel level) async {
    if (fails || vibrationFails) throw Exception('sin vibrador');
    vibrated.add(level);
  }
}
