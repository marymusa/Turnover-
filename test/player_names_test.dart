import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/domain/player_names.dart';

import 'memory_settings_store.dart';

void main() {
  group('los nombres', () {
    test('sin nada guardado no hay ninguno puesto', () async {
      final names = PlayerNames(MemorySettingsStore());

      await names.load();

      expect(names.nameOf(Player.one), isNull);
      expect(names.nameOf(Player.two), isNull);
    });

    test('se puede renombrar a cualquiera de los dos', () async {
      final names = PlayerNames(MemorySettingsStore());

      await names.rename(Player.one, 'Ivan');
      await names.rename(Player.two, 'Nurgle');

      expect(names.nameOf(Player.one), 'Ivan');
      expect(names.nameOf(Player.two), 'Nurgle');
    });

    test('el del jugador uno sobrevive a cerrar la aplicación', () async {
      final store = MemorySettingsStore();
      await PlayerNames(store).rename(Player.one, 'Ivan');

      final names = PlayerNames(store);
      await names.load();

      expect(names.nameOf(Player.one), 'Ivan');
    });

    test('el del jugador dos no se guarda', () async {
      final store = MemorySettingsStore();
      await PlayerNames(store).rename(Player.two, 'Nurgle');

      final names = PlayerNames(store);
      await names.load();

      expect(names.nameOf(Player.two), isNull);
    });

    test(
      'reiniciar devuelve el del jugador dos a su valor por defecto',
      () async {
        final names = PlayerNames(MemorySettingsStore());
        await names.rename(Player.one, 'Ivan');
        await names.rename(Player.two, 'Nurgle');

        names.resetOpponent();

        expect(names.nameOf(Player.one), 'Ivan');
        expect(names.nameOf(Player.two), isNull);
      },
    );

    test('un nombre en blanco devuelve al valor por defecto', () async {
      final store = MemorySettingsStore();
      final names = PlayerNames(store);
      await names.rename(Player.one, 'Ivan');

      await names.rename(Player.one, '   ');

      expect(names.nameOf(Player.one), isNull);
      final reloaded = PlayerNames(store);
      await reloaded.load();
      expect(reloaded.nameOf(Player.one), isNull);
    });

    test('un nombre se guarda sin los espacios de los extremos', () async {
      final names = PlayerNames(MemorySettingsStore());

      await names.rename(Player.one, '  Ivan  ');

      expect(names.nameOf(Player.one), 'Ivan');
    });

    test('avisa a quien escuche al renombrar', () async {
      final names = PlayerNames(MemorySettingsStore());
      var notices = 0;
      names.addListener(() => notices++);

      await names.rename(Player.two, 'Nurgle');

      expect(notices, 1);
    });

    test('avisa a quien escuche al reiniciar', () async {
      final names = PlayerNames(MemorySettingsStore());
      var notices = 0;
      names.addListener(() => notices++);

      names.resetOpponent();

      expect(notices, 1);
    });
  });
}
