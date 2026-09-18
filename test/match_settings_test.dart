import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/domain/match_settings.dart';

import 'memory_settings_store.dart';

void main() {
  group('los ajustes', () {
    test('sin nada guardado son los del glosario', () async {
      final settings = MatchSettings(MemorySettingsStore());

      await settings.load();

      expect(settings.turn, const Duration(minutes: 4));
      expect(settings.reserve, const Duration(minutes: 15));
      expect(settings.warning, const Duration(seconds: 30));
      // Los dos avisos vienen encendidos y separados: con los dos agarres a la
      // vista se ve de un vistazo que son dos y que se mueven.
      expect(settings.earlyWarning, const Duration(seconds: 55));
    });

    test(
      'el aviso temprano guardado se lee en el arranque siguiente',
      () async {
        final store = MemorySettingsStore();
        await MatchSettings(store)
            .save(earlyWarning: const Duration(minutes: 1));

        final settings = MatchSettings(store);
        await settings.load();

        expect(settings.earlyWarning, const Duration(minutes: 1));
        expect(settings.warning, const Duration(seconds: 30));
      },
    );

    test('un aviso temprano llega al partido en curso', () async {
      final settings = MatchSettings(MemorySettingsStore());
      final clock = MatchClock(
        turn: defaultTurn,
        reserve: defaultReserve,
        warning: defaultWarning,
      );
      applySettingsTo(clock, settings);

      await settings.save(earlyWarning: const Duration(minutes: 1));

      expect(clock.earlyWarning, const Duration(minutes: 1));
    });

    test('lo guardado se lee en el arranque siguiente', () async {
      final store = MemorySettingsStore();
      await MatchSettings(store).save(
        turn: const Duration(minutes: 5),
        reserve: const Duration(minutes: 20),
        warning: const Duration(seconds: 45),
      );

      final settings = MatchSettings(store);
      await settings.load();

      expect(settings.turn, const Duration(minutes: 5));
      expect(settings.reserve, const Duration(minutes: 20));
      expect(settings.warning, const Duration(seconds: 45));
    });

    test('guardar un solo tiempo deja los otros como estaban', () async {
      final store = MemorySettingsStore();
      final settings = MatchSettings(store);
      await settings.load();

      await settings.save(turn: const Duration(minutes: 6));

      expect(settings.turn, const Duration(minutes: 6));
      expect(settings.reserve, const Duration(minutes: 15));
    });

    test('avisa a quien escuche al guardar', () async {
      final settings = MatchSettings(MemorySettingsStore());
      var notices = 0;
      settings.addListener(() => notices++);

      await settings.save(turn: const Duration(minutes: 5));

      expect(notices, 1);
    });
  });

  group('los ajustes aplicados al partido', () {
    // La regla de redimensionar es de MatchClock y ya está probada allí. Lo
    // que se prueba aquí es el cable: que un cambio de ajustes llegue al
    // partido en curso sin que nadie lo empuje a mano.
    test('un cambio llega al partido en curso', () async {
      final settings = MatchSettings(MemorySettingsStore());
      final clock = MatchClock(
        turn: defaultTurn,
        reserve: defaultReserve,
        warning: defaultWarning,
      );
      applySettingsTo(clock, settings);

      await settings.save(reserve: const Duration(minutes: 20));

      expect(clock.reserveOf(Player.one), const Duration(minutes: 20));
    });

    test('cambiar el turno a media jugada no lo reinicia', () async {
      final settings = MatchSettings(MemorySettingsStore());
      final clock = MatchClock(
        turn: defaultTurn,
        reserve: defaultReserve,
        warning: defaultWarning,
      );
      applySettingsTo(clock, settings);
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 1));

      await settings.save(turn: const Duration(minutes: 5));

      // Un minuto más al turno que ya corría, no un turno nuevo de cinco.
      expect(clock.turnOf(Player.one), const Duration(minutes: 4));
    });

    test('ampliar la reserva conserva lo gastado', () async {
      final settings = MatchSettings(MemorySettingsStore());
      final clock = MatchClock(
        turn: defaultTurn,
        reserve: defaultReserve,
        warning: defaultWarning,
      );
      applySettingsTo(clock, settings);
      clock.start(Player.one);
      // Agotar el turno entero y seis minutos de reserva.
      clock.advance(defaultTurn + const Duration(minutes: 6));

      await settings.save(reserve: const Duration(minutes: 20));

      expect(clock.reserveOf(Player.one), const Duration(minutes: 14));
    });
  });
}
