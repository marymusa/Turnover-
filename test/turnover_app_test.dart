import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/alert_player.dart';
import 'package:turnover/domain/awake_guard.dart';
import 'package:turnover/domain/clock_format.dart';
import 'package:turnover/domain/match_alerts.dart';
import 'package:turnover/domain/match_clock.dart';
import 'package:turnover/domain/match_settings.dart';
import 'package:turnover/domain/report_sharer.dart';
import 'package:turnover/main.dart';
import 'package:turnover/ui/clock_colors.dart';
import 'package:turnover/ui/clock_screen.dart';
import 'package:turnover/ui/clock_theme.dart';
import 'package:turnover/ui/match_report.dart';
import 'package:turnover/ui/player_half.dart';
import 'package:turnover/ui/seam_controls.dart';
import 'package:turnover/ui/settings_screen.dart';

import 'memory_settings_store.dart';

void main() {
  // `rootBundle` guarda en cache lo que lee, por clave. El banco de pruebas
  // rehace el canal de assets entre test y test, así que la entrada guardada
  // en el primero queda apuntando a un canal muerto: a partir del segundo, la
  // espera de `LogoOutline.load()` no se resuelve nunca y la presentación del
  // escudo no llega a arrancar. Vaciar la cache devuelve a cada test una
  // lectura suya, que sí termina.
  setUp(rootBundle.clear);

  group('el dueño del reloj', () {
    // El partido se perdía porque el reloj se construía en `build`: un rebuild
    // del padre dejaba dos instancias vivas, la que pintaba la pantalla con el
    // turno entero y la que corría el ticker con el tiempo ya gastado.
    testWidgets('el partido sobrevive a un rebuild de TurnoverApp', (
      tester,
    ) async {
      final rebuilds = ValueNotifier(0);
      addTearDown(rebuilds.dispose);

      await tester.pumpWidget(
        ListenableBuilder(
          listenable: rebuilds,
          builder: (context, _) => TurnoverApp(
            alerts: const AlertPlayer(_SilentDevice()),
            screen: const _IgnoredScreen(),
            sharer: const _MuteSharer(),
            store: MemorySettingsStore(),
          ),
        ),
      );

      final clock = _clockOnScreen(tester);
      clock.start(Player.one);
      // Dos toques de reloj: el primero solo fija el origen del ticker y el
      // segundo es el que consume.
      await tester.pump();
      await tester.pump(const Duration(seconds: 70));

      rebuilds.value++;
      await tester.pump();

      expect(_clockOnScreen(tester), same(clock));
      expect(_clockOnScreen(tester).state, MatchState.running);
      expect(
        _clockOnScreen(tester).turnOf(Player.one),
        lessThan(const Duration(minutes: 4)),
      );
    });
  });

  group('los nombres en la pantalla', () {
    // Se busca por el texto en inglés, que es el idioma al que cae el banco de
    // pruebas. Que el castellano exista lo prueba localization_test.

    testWidgets('por defecto son los del ADR-0003', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      expect(find.text('Me'), findsOneWidget);
      expect(find.text('My opponent'), findsOneWidget);
    });

    testWidgets('una pulsación larga en la mitad lo cambia', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await _rename(tester, from: 'Me', to: 'Ivan');

      expect(find.text('Ivan'), findsOneWidget);
      expect(find.text('Me'), findsNothing);
    });

    testWidgets('renombra al jugador de la mitad que se pulsa', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await _rename(tester, from: 'My opponent', to: 'Nurgle');

      expect(find.text('Nurgle'), findsOneWidget);
      expect(find.text('Me'), findsOneWidget);
    });

    // Los tiempos y los nombres se pactan con el partido parado: despues, la
    // mitad es pasar turno y nada mas, para que un dedo lento no abra un
    // dialogo en mitad del juego.
    testWidgets('no se renombra con el partido empezado', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      // Se empieza tocando, que es el camino real: es el toque el que hace
      // que la pantalla se vuelva a pintar sin el gesto de renombrar.
      await tester.tap(_halfShowing('Me'));
      await _settle(tester);

      await tester.longPress(_halfShowing('My opponent'));
      await _settle(tester);

      expect(find.text('Change name'), findsNothing);
      expect(_clockOnScreen(tester).state, MatchState.running);
    });

    // La pulsacion larga no puede elegir quien recibe de paso.
    testWidgets('la pulsación larga no arranca el partido', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await tester.longPress(_halfShowing('Me'));
      await _settle(tester);

      expect(_clockOnScreen(tester).state, MatchState.notStarted);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
    });

    // Tocar sigue siendo solo elegir quien recibe, tambien sobre el nombre.
    testWidgets('tocar el nombre arranca el partido', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await tester.tap(find.text('Me'));
      await _settle(tester);

      expect(find.text('Change name'), findsNothing);
      expect(_clockOnScreen(tester).activePlayer, Player.one);
    });

    testWidgets('el del jugador uno sobrevive a cerrar la aplicación', (
      tester,
    ) async {
      final store = MemorySettingsStore();
      await tester.pumpWidget(_app(store: store));
      await _settle(tester);
      await _rename(tester, from: 'Me', to: 'Ivan');

      await tester.pumpWidget(_app(store: store, key: const Key('again')));
      await _settle(tester);

      expect(find.text('Ivan'), findsOneWidget);
    });

    testWidgets('el del jugador dos no sobrevive a cerrar la aplicación', (
      tester,
    ) async {
      final store = MemorySettingsStore();
      await tester.pumpWidget(_app(store: store));
      await _settle(tester);
      await _rename(tester, from: 'My opponent', to: 'Nurgle');

      await tester.pumpWidget(_app(store: store, key: const Key('again')));
      await _settle(tester);

      expect(find.text('My opponent'), findsOneWidget);
      expect(find.text('Nurgle'), findsNothing);
    });

    testWidgets('borrar el nombre devuelve al valor por defecto', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _rename(tester, from: 'Me', to: 'Ivan');

      await _rename(tester, from: 'Ivan', to: '');

      expect(find.text('Me'), findsOneWidget);
    });

    testWidgets('cancelar deja el nombre como estaba', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await _rename(tester, from: 'Me', to: 'Ivan', confirm: false);

      expect(find.text('Me'), findsOneWidget);
      expect(find.text('Ivan'), findsNothing);
    });
  });

  group('el botón de volver', () {
    // Sin interceptar, volver saca la única ruta de la pila y Android termina
    // la actividad: el proceso muere y el partido, que solo vive en memoria,
    // se pierde entero (ADR-0003). Se parecía a un reinicio y no lo era.

    testWidgets('antes de empezar sale sin preguntar', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await _pressBack(tester);

      expect(find.text('Leave the match?'), findsNothing);
    });

    testWidgets('con el partido empezado pide confirmación', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);

      await _pressBack(tester);

      expect(find.text('Leave the match?'), findsOneWidget);
      expect(
        find.textContaining('The current timers will be lost'),
        findsOneWidget,
      );
    });

    // Lo que hace que valga la pena preguntar: el reloj se detiene mientras se
    // decide, para que pensárselo no le cueste tiempo al jugador activo.
    testWidgets('preguntar pausa el partido', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);

      await _pressBack(tester);

      expect(_clockOnScreen(tester).state, MatchState.paused);
    });

    testWidgets('cancelar deja el partido donde estaba', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);
      final spent = _clockOnScreen(tester).turnOf(Player.one);

      await _pressBack(tester);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);

      expect(find.text('Leave the match?'), findsNothing);
      expect(_clockOnScreen(tester).turnOf(Player.one), spent);
    });
  });

  group('los ajustes', () {
    // El acceso se abría con el context de TurnoverApp, que está por encima
    // del MaterialApp y no tiene Navigator debajo: pulsar el botón reventaba y
    // la pantalla de ajustes no se alcanzaba nunca.
    testWidgets('el botón abre la pantalla de ajustes', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await tester.tap(find.bySemanticsLabel('Settings'));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    // El acceso vive en la costura, al lado del escudo: es el hueco que no
    // pertenece a ninguna de las dos mitades. Pegado arriba a la derecha caía
    // dentro de la tarjeta del rival y parecía suyo.
    //
    // Se comprueba que se reparte entre las dos mitades en vez de caer en una,
    // que es lo que se quería arreglar, y no la posición exacta, que es cosa
    // del ojo y del móvil. Cruzar la costura es lo que se busca: el escudo, que
    // ya está centrado en ella, la cruza igual.
    testWidgets('el acceso queda repartido entre las dos mitades', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      final access = tester.getRect(find.bySemanticsLabel('Settings'));
      final halves = tester
          .widgetList<PlayerHalf>(find.byType(PlayerHalf))
          .map((half) => tester.getRect(find.byWidget(half)));

      for (final half in halves) {
        final shared = half.intersect(access);
        expect(shared.height, moreOrLessEquals(access.height / 2));
      }
    });

    // Vigila que la transición entre las dos pantallas no se aclare por
    // dentro, fotografiando cada fotograma y mirando el color que más se
    // repite, que es el del fondo. El toImage necesita trabajo asíncrono de
    // verdad, así que va dentro de runAsync: en el bucle de pump se cuelga.
    //
    // No es la comprobación del destello que se veía en el móvil. Aquel salía
    // de android:windowBackground, la ventana que hay por detrás de la
    // superficie de Flutter, y desde aquí no se ve: este banco de pruebas no
    // tiene ventana de Android. Lo que se ve aquí es solo lo que pinta
    // Flutter, y por eso esta comprobación pasaba con el móvil destellando.
    // Una vez por paleta: el destello es de la transición, no del modo, y en
    // claro también hay que vigilarlo. El techo sale de la propia paleta en
    // vez de ir a mano, que es lo que ataba esta prueba a la oscura: lo que se
    // comprueba es que la transición no se aclara por encima de los dos
    // fondos entre los que ocurre, sean los que sean.
    for (final palette in [ClockColors.dark, ClockColors.light]) {
      final isLight = palette.brightness == Brightness.light;
      final name = isLight ? 'clara' : 'oscura';

      testWidgets('abrir los ajustes no da un destello claro ($name)', (
        tester,
      ) async {
        tester.platformDispatcher.platformBrightnessTestValue =
            palette.brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(_app(store: MemorySettingsStore()));
        await _settle(tester);

        await tester.tap(find.bySemanticsLabel('Settings'));

        final background = <int>[];
        for (var frame = 0; frame < 20; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          background.add(await _dominantLuma(tester));
        }

        // Las dos pantallas comparten fondo, así que el techo es ese mismo
        // color: por encima de él la transición se estaría aclarando.
        expect(
          background,
          everyElement(lessThanOrEqualTo(_transitionCeiling(palette))),
        );
      });
    }
  });

  group('los controles de la costura', () {
    // En una mesa se golpea la pantalla sin apuntar, así que el objetivo
    // táctil es lo que decide si el control se acierta.
    //
    // Lo que se mide es el círculo pintado, que aquí vale por el objetivo: el
    // InkWell lo llena entero, de modo que lo que se ve es lo que recoge el
    // toque. Medir el área del gesto de verdad pediría bajar al árbol de
    // hit testing, y lo que se quiere vigilar es que el botón no encoja.
    testWidgets('los tres llegan al tamaño de dedo', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);

      for (final label in ['Pause', 'End my turn', 'Reset timer']) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(
          size.shortestSide,
          greaterThanOrEqualTo(_minimumTapTarget),
          reason: '$label se queda por debajo del objetivo táctil',
        );
      }
    });

    // La jerarquía de la costura, que [ClockTheme.passTurnSize] explica: aquí
    // solo se vigila que subir los tres no la haya deshecho.
    testWidgets('pasar turno es el mayor de los tres', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);

      final passTurn = tester.getSize(find.bySemanticsLabel('End my turn'));
      for (final label in ['Pause', 'Reset timer']) {
        expect(
          passTurn.shortestSide,
          greaterThan(
            tester.getSize(find.bySemanticsLabel(label)).shortestSide,
          ),
        );
      }
    });

    // La costura es un añadido centrado encima de las mitades, así que crecer
    // no las empuja: se les echa encima. Lo que no puede pasar es que tape un
    // reloj, que es lo que se está mirando mientras se juega.
    //
    // Se mira en overtime, que es el estado más apretado: con el turno gastado
    // la reserva pasa de [ClockTheme.reserveSize] a
    // [ClockTheme.reserveSizeSpent] y se acerca a la costura más que en
    // ningún otro momento. Además el reloj sale con signo, `-0:39`, que es el
    // caso que [_looksLikeClock] tiene que reconocer.
    testWidgets('no se come ningún reloj de las mitades', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      _clockOnScreen(tester).start(Player.one);
      await tester.pump();
      // El turno entero y la reserva entera, y un poco más: así el reloj de
      // reserva ya va en contra.
      await tester.pump(const Duration(minutes: 19, seconds: 39));

      final seam = tester.getRect(find.byType(SeamControls));
      final clocks = tester
          .widgetList<Text>(find.byType(Text))
          .where((text) => _looksLikeClock(text.data));

      // Los cuatro: turno y reserva de cada mitad. Contarlos es lo que impide
      // que el bucle pase en vacío el día que la forma del reloj cambie y
      // ninguno se reconozca.
      expect(clocks, hasLength(4));
      for (final clock in clocks) {
        final rect = tester.getRect(find.byWidget(clock));
        expect(
          rect.overlaps(seam),
          isFalse,
          reason: 'la costura se come el reloj ${clock.data}',
        );
      }
    });
  });

  group('reiniciar el partido', () {
    // El reinicio se define por lo que no borra, y por eso se comprueba con
    // los tiempos cambiados y los dos nombres puestos: lo que sobrevive es
    // tan parte del trato como lo que se va.

    testWidgets('el control no existe antes de empezar', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      expect(_resetControl, findsNothing);
    });

    testWidgets('pide confirmación describiendo la consecuencia', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);

      await tester.tap(_resetControl);
      await _settle(tester);

      expect(find.text('Reset the timer?'), findsOneWidget);
      // El diálogo dice lo que se pierde antes de tocar nada. Que el nombre
      // del oponente vuelva a su valor por defecto lo cubre su propio test:
      // aquí solo se comprueba que se avisa.
      expect(
        find.textContaining('The current timers will be lost'),
        findsOneWidget,
      );
      // Preguntar no es hacer: hasta confirmar, el partido sigue donde estaba.
      expect(_clockOnScreen(tester).state, MatchState.running);
    });

    testWidgets('cancelar deja el partido intacto', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);
      final spent = _clockOnScreen(tester).turnOf(Player.one);

      await tester.tap(_resetControl);
      await _settle(tester);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);

      expect(_clockOnScreen(tester).state, MatchState.running);
      // Sigue gastando turno donde lo dejó: preguntar no detiene el reloj, así
      // que lo que importa es que no haya vuelto a los cuatro minutos.
      expect(
        _clockOnScreen(tester).turnOf(Player.one),
        lessThanOrEqualTo(spent),
      );
    });

    testWidgets('confirmar devuelve los relojes a su valor inicial', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);

      await _confirmReset(tester);

      final clock = _clockOnScreen(tester);
      expect(clock.turnOf(Player.one), const Duration(minutes: 4));
      expect(clock.reserveOf(Player.one), const Duration(minutes: 15));
      expect(clock.reserveOf(Player.two), const Duration(minutes: 15));
    });

    testWidgets('confirmar deja el partido esperando el toque inicial', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);

      await _confirmReset(tester);

      expect(_clockOnScreen(tester).state, MatchState.notStarted);
      expect(_clockOnScreen(tester).activePlayer, isNull);
      // Y el toque siguiente vuelve a elegir quién recibe: la invitación de
      // cada mitad ha vuelto, que es la señal de que el partido no ha
      // empezado.
      expect(find.text('Tap to start'), findsNWidgets(2));
      await tester.tap(find.text('Tap to start').last);
      await _settle(tester);
      expect(_clockOnScreen(tester).activePlayer, Player.one);
    });

    // La invitación esperaba a la presentación del escudo la primera vez, pero
    // no al reiniciar: se quedaba encima de un escudo que se estaba volviendo
    // a dibujar. Reiniciar devuelve la pantalla a antes de empezar, y eso
    // incluye volver a esperar.
    testWidgets('reiniciar hace esperar la invitación a la presentación', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      expect(_inviteAlpha(tester), 0);

      await _passReveal(tester);
      expect(_inviteAlpha(tester), 1);

      await _startAndSpend(tester);
      expect(_inviteAlpha(tester), 0);

      await _confirmReset(tester);

      expect(_inviteAlpha(tester), 0);
      await _passReveal(tester);
      expect(_inviteAlpha(tester), 1);
    });

    testWidgets('reiniciar pausado no deja el partido pausado', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _startAndSpend(tester);
      await tester.tap(find.bySemanticsLabel('Pause'));
      await _settle(tester);

      await _confirmReset(tester);

      expect(_clockOnScreen(tester).state, MatchState.notStarted);
      expect(find.text('Paused. Tap anywhere to resume'), findsNothing);
    });

    testWidgets('conserva la configuración de tiempos', (tester) async {
      final store = MemorySettingsStore();
      await store.writeSeconds('turn_seconds', 180);
      await store.writeSeconds('reserve_seconds', 600);
      await tester.pumpWidget(_app(store: store));
      await _settle(tester);
      await _startAndSpend(tester);

      await _confirmReset(tester);

      final clock = _clockOnScreen(tester);
      expect(clock.turnOf(Player.one), const Duration(minutes: 3));
      expect(clock.reserveOf(Player.one), const Duration(minutes: 10));
    });

    testWidgets('conserva el nombre del jugador uno', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _rename(tester, from: 'Me', to: 'Ivan');
      await _startAndSpend(tester);

      await _confirmReset(tester);

      expect(find.text('Ivan'), findsOneWidget);
    });

    testWidgets('devuelve el del jugador dos al valor por defecto', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _rename(tester, from: 'My opponent', to: 'Nurgle');
      await _startAndSpend(tester);

      await _confirmReset(tester);

      expect(find.text('My opponent'), findsOneWidget);
      expect(find.text('Nurgle'), findsNothing);
    });
  });

  // Se busca por el texto en inglés, que es el idioma al que cae el banco de
  // pruebas, igual que en los nombres.
  group('el acta', () {
    testWidgets('sale sola al pasar el turno 16 del segundo jugador', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await tester.tap(_halfShowing('Me'));
      await _settle(tester);

      // No hay botón de terminar: el acta llega cuando lo dice la cuenta, y
      // no puede llegar antes del último pase.
      for (var pass = 1; pass < _passesPerMatch; pass++) {
        await tester.tap(_passTurnControl);
        await _settle(tester);
        expect(
          _endMatchButton,
          findsNothing,
          reason: 'el acta no puede salir en el pase $pass',
        );
      }

      await tester.tap(_passTurnControl);
      await _settle(tester);

      expect(_clockOnScreen(tester).state, MatchState.finished);
      expect(_endMatchButton, findsOneWidget);
    });

    testWidgets('nombra los tiempos y a los dos jugadores', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _playWholeMatch(tester);

      // Cada nombre, una vez, al lado de su tramo de la barra.
      expect(find.text('Me'), findsOneWidget);
      expect(find.text('My opponent'), findsOneWidget);

      // El tiempo de juego encabeza y el total va debajo. Lo parado no lleva
      // fila: es la diferencia entre los dos.
      expect(find.text('Play time'), findsOneWidget);
      expect(
        find.textContaining('Total '),
        findsOneWidget,
        reason: 'el total va debajo de la cifra grande',
      );
    });

    // La barra llegó a estar montada y con las etiquetas bien, pero con los
    // dos tramos a cero de alto: se veía el hueco y no la barra. Que el
    // widget exista no prueba que se pinte, así que esto lo mide.
    testWidgets('la barra se pinta con alto y reparte el ancho', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);

      await _playLopsidedMatch(tester);

      final one = tester.getSize(find.byKey(MatchReport.barKeyOne));
      final two = tester.getSize(find.byKey(MatchReport.barKeyTwo));

      expect(one.height, ClockTheme.reportBarHeight);
      expect(two.height, ClockTheme.reportBarHeight);
      expect(
        one.width,
        greaterThan(two.width),
        reason: 'el jugador uno consumió más, así que su tramo es más ancho',
      );
    });

    // La gráfica no puede dibujar lo que nadie ha guardado: si el reloj no
    // apuntara cada turno al pasarlo, esto saldría vacío.
    testWidgets('dibuja la gráfica de lo que duró cada turno', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _playWholeMatch(tester);

      expect(find.text('TIME PER TURN'), findsOneWidget);

      final clock = _clockOnScreen(tester);
      expect(clock.turnsOf(Player.one), hasLength(_passesPerMatch ~/ 2));
      expect(clock.turnsOf(Player.two), hasLength(_passesPerMatch ~/ 2));
    });

    // El acta es un documento y no una pantalla de juego: de ella se hace una
    // captura que va al responsable de la liga, y media acta girada sería
    // media captura del revés.
    testWidgets('se lee entera en vertical, sin nada girado', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _playWholeMatch(tester);

      // Una sola vez, no una por jugador: el acta se lee de arriba abajo.
      expect(find.text('FULL TIME'), findsOneWidget);
      expect(
        find.byType(RotatedBox),
        findsNothing,
        reason: 'nada del acta se lee del revés',
      );
    });

    // El orden es el de la lectura: primero lo de cada uno, que es lo
    // comparable, y debajo lo que es de los dos.
    testWidgets('pone a los jugadores por encima de las cifras comunes', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _playWholeMatch(tester);

      double topOf(Finder finder) => tester.getTopLeft(finder).dy;

      // De arriba abajo: qué pasó, cuánto se jugó, cómo se repartió, y turno
      // a turno de dónde salió ese reparto.
      expect(
        topOf(find.text('FULL TIME')),
        lessThan(topOf(find.text('Play time'))),
      );
      expect(
        topOf(find.text('Play time')),
        lessThan(topOf(find.text('Me'))),
      );
      expect(
        topOf(find.text('Me')),
        lessThan(topOf(find.text('TIME PER TURN'))),
      );
      expect(
        topOf(find.text('TIME PER TURN')),
        lessThan(topOf(_endMatchButton)),
      );

      // Los dos jugadores van a la misma altura, uno a cada lado de la barra,
      // y no uno debajo del otro: es una comparación, no una lista.
      expect(topOf(find.text('Me')), topOf(find.text('My opponent')));
    });

    // El acta se monta sola al salir. Lo que se comprueba es que arranca de
    // un estado neutro y acaba en el dato: que la barra parte del reparto a
    // medias y se abre, y que la cifra grande no esta puesta hasta el final.
    // Como se ve el recorrido entre medias es cosa de mirarlo, no de medirlo.
    testWidgets('el acta se monta sola: la barra parte de medias', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      // Desigual a proposito: con los dos empatados la barra acaba donde
      // empieza y no habria desviacion que comprobar.
      await _playLopsidedMatch(tester, settle: false);

      final startOne = tester.getSize(find.byKey(MatchReport.barKeyOne)).width;
      final startTwo = tester.getSize(find.byKey(MatchReport.barKeyTwo)).width;
      expect(
        (startOne - startTwo).abs(),
        lessThan(1),
        reason: 'recien salida, la barra esta a medias',
      );

      final clock = _clockOnScreen(tester);
      final playTime = formatElapsed(
        clock.playedOf(Player.one) + clock.playedOf(Player.two),
      );
      expect(
        find.text(playTime),
        findsNothing,
        reason: 'la cifra todavia esta subiendo',
      );

      await _settleReport(tester);

      final endOne = tester.getSize(find.byKey(MatchReport.barKeyOne)).width;
      final endTwo = tester.getSize(find.byKey(MatchReport.barKeyTwo)).width;
      expect(
        (endOne - endTwo).abs(),
        greaterThan((startOne - startTwo).abs()),
        reason: 'se abre hasta donde cayo el reparto',
      );
      expect(find.text(playTime), findsOneWidget);
    });

    // Compartir hace una foto del acta y se la da al sistema. Lo que se
    // comprueba aquí es que la foto se hace y llega: abrir el menú de
    // compartir es de la plataforma y no pasa por el banco de pruebas.
    //
    // Va dentro de `runAsync` porque pintar un trozo del árbol en una imagen
    // cruza al motor de verdad, y el reloj falso de los tests no resuelve esa
    // espera.
    testWidgets('compartir entrega una imagen del acta', (tester) async {
      final sharer = _RecordingSharer();
      await tester.pumpWidget(
        _app(store: MemorySettingsStore(), sharer: sharer),
      );
      await _settle(tester);
      await _playWholeMatch(tester);

      await tester.runAsync(() async {
        await tester.tap(find.text('Share'));
        await tester.pump();
        // La foto se hace en dos esperas, la imagen y su codificación: se les
        // deja terminar antes de mirar.
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });

      expect(sharer.calls, hasLength(1));
      final call = sharer.calls.single;
      expect(call.name, MatchReport.fileName);
      expect(
        call.png,
        isNotEmpty,
        reason: 'lo que se comparte es la imagen, no un hueco',
      );
      // La firma de un PNG, para no dar por buena cualquier ristra de bytes.
      expect(call.png.take(4), [0x89, 0x50, 0x4E, 0x47]);

      // El texto nombra a los dos: en una bandeja de entrada es lo único que
      // distingue un acta de la siguiente sin abrir la imagen.
      expect(call.text, contains('Me'));
      expect(call.text, contains('My opponent'));
    });

    // Lo que se comparte es el acta y no la pantalla, así que los dos botones
    // van por debajo de todo lo que el acta enseña. Que caigan fuera del
    // marco de la foto lo garantiza el árbol, que los deja fuera del
    // `RepaintBoundary`; esto comprueba lo que sí se puede medir, que es que
    // están debajo y en el orden que toca.
    testWidgets('los botones van debajo del acta y en orden', (tester) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _playWholeMatch(tester);

      double topOf(Finder finder) => tester.getTopLeft(finder).dy;

      final documentBottom = tester
          .getRect(find.text('TIME PER TURN'))
          .bottom;
      expect(topOf(find.text('Share')), greaterThan(documentBottom));
      expect(
        topOf(_endMatchButton),
        greaterThan(topOf(find.text('Share'))),
        reason: 'compartir va primero: es lo que se hace nada más acabar',
      );
    });

    // No hay abandono a mitad de partido: eso ya lo cubre reiniciar, que
    // además avisa de lo que se pierde. Aquí no hay nada que avisar, porque el
    // partido ya se ha acabado.
    testWidgets('terminar devuelve a antes de empezar sin preguntar', (
      tester,
    ) async {
      await tester.pumpWidget(_app(store: MemorySettingsStore()));
      await _settle(tester);
      await _playWholeMatch(tester);

      await tester.tap(_endMatchButton);
      await _settle(tester);

      expect(_clockOnScreen(tester).state, MatchState.notStarted);
      expect(_endMatchButton, findsNothing);
      expect(_resetControl, findsNothing);
    });
  });

  group('la mitad en una pantalla corta', () {
    // 320x568 es el móvil pequeño de referencia. Con las medidas fijas la
    // columna se desbordaba por abajo y los dos relojes de tiempo extra se
    // iban fuera de la pantalla, uno por arriba y otro por abajo.
    testWidgets('los dos relojes de tiempo extra caben dentro', (tester) async {
      await _withSurface(tester, const Size(320, 568), () async {
        await tester.pumpWidget(_app(store: MemorySettingsStore()));
        await _settle(tester);

        for (final half in tester.widgetList<PlayerHalf>(
          find.byType(PlayerHalf),
        )) {
          final rect = tester.getRect(
            find.descendant(
              of: find.byWidget(half),
              matching: find.text(formatClock(half.reserve)),
            ),
          );
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(568));
        }
      });
    });

    // Lo que se encoge son las medidas, no el reparto: la pantalla normal
    // tiene que quedarse exactamente igual que antes.
    test('a tamaño normal no encoge nada', () {
      final metrics = ClockTheme.metricsFor(const Size(2000, 2000));

      expect(metrics.turnSize, ClockTheme.turnSize);
      expect(metrics.reserveSizeSpent, ClockTheme.reserveSizeSpent);
      expect(metrics.clockToSlotGap, ClockTheme.clockToSlotGap);
    });
  });
}

/// Corre el cuerpo con la pantalla a la medida dada y la devuelve a la suya al
/// terminar, pase lo que pase.
Future<void> _withSurface(
  WidgetTester tester,
  Size size,
  Future<void> Function() body,
) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await body();
}

Widget _app({
  required SettingsStore store,
  ReportSharer? sharer,
  Key? key,
}) => TurnoverApp(
  key: key,
  alerts: const AlertPlayer(_SilentDevice()),
  screen: const _IgnoredScreen(),
  sharer: sharer ?? const _MuteSharer(),
  store: store,
);

/// El ticker del cronómetro corre en todos los fotogramas, así que la
/// aplicación no llega nunca a asentarse: hay que pedir los fotogramas a mano.
/// Deja terminar la presentación de la costura. El contorno del escudo se lee
/// de un asset, así que primero hay que dejar resolver esa espera y solo
/// después correr la animación: con un `pump` de duración fija, el reparto de
/// microtareas decide si da tiempo o no.
Future<void> _settle(WidgetTester tester) async {
  // Bastante para que entre o salga el diálogo, que es la única animación
  // que hay que dejar terminar.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _rename(
  WidgetTester tester, {
  required String from,
  required String to,
  bool confirm = true,
}) async {
  await tester.longPress(_halfShowing(from));
  await _settle(tester);
  await tester.enterText(find.byType(TextField), to);
  await tester.tap(find.text(confirm ? 'Save' : 'Cancel'));
  await _settle(tester);
}

/// El botón de volver de Android, por el mismo camino que lo recibe la
/// aplicación de verdad: el mensaje de la plataforma, no una llamada al
/// Navigator.
Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await _settle(tester);
}

final _resetControl = find.bySemanticsLabel('Reset timer');
final _passTurnControl = find.bySemanticsLabel('End my turn');
final _endMatchButton = find.text('End match');

/// Los pases que dura un partido sin Time-Outs: dos partes de ocho turnos por
/// jugador, y en cada parte el segundo jugador cierra con el suyo.
const _passesPerMatch = 32;

/// Juega el partido entero desde el toque inicial, que es la única forma de
/// llegar al acta: no hay botón de terminar.
Future<void> _playWholeMatch(WidgetTester tester, {bool settle = true}) async {
  await tester.tap(_halfShowing('Me'));
  await _settle(tester);
  for (var pass = 0; pass < _passesPerMatch; pass++) {
    await tester.tap(_passTurnControl);
    await _settle(tester);
  }
  if (settle) await _settleReport(tester);
}

/// Deja que el acta termine de montarse.
///
/// Se monta sola al salir: las cifras suben desde cero, la barra se abre
/// desde el medio y las lineas recorren sus turnos. Los tests miran el acta
/// hecha y no a medio hacer, porque si no lo que midan depende de cuando
/// miren, que es la receta de un test que falla un dia de cada diez.
Future<void> _settleReport(WidgetTester tester) async {
  await tester.pump(ClockTheme.reportRevealDuration);
  await tester.pump();
}

/// Juega el partido entero dejando que el jugador uno consuma bastante mas.
///
/// Con `_playWholeMatch` los dos acaban con el mismo tiempo, porque cada pase
/// cuesta lo mismo: el reparto sale a medias y no hay nada que comparar ni
/// ninguna desviacion que animar. Aqui se le da seis veces mas reloj al uno.
Future<void> _playLopsidedMatch(
  WidgetTester tester, {
  bool settle = true,
}) async {
  await tester.tap(_halfShowing('Me'));
  await _settle(tester);
  for (var pass = 0; pass < _passesPerMatch; pass++) {
    // A quien le toca se le pregunta al reloj y no se deduce del numero de
    // pase: al cambiar de parte el orden se invierte y uno juega dos turnos
    // seguidos, asi que alternando por pares los dos acaban igual otra vez.
    final active = _clockOnScreen(tester).activePlayer;
    await tester.pump(
      active == Player.one
          ? const Duration(seconds: 30)
          : const Duration(seconds: 5),
    );
    await tester.tap(_passTurnControl);
    await _settle(tester);
  }
  if (settle) await _settleReport(tester);
}

/// El objetivo táctil mínimo de Material, que es también el de Apple en sus
/// propias unidades. Por debajo de esto el control se falla al golpear la
/// pantalla sin apuntar, que es como se juega en una mesa.
const _minimumTapTarget = 48.0;

/// Si ese texto es uno de los cuatro relojes. Se reconocen por la forma,
/// `m:ss` o `mm:ss`, que no la tiene ningún otro texto de la pantalla.
///
/// El signo entra en la forma: en overtime el reloj se escribe `-0:39`, y es
/// justo el estado en el que hay que mirar si la costura tapa algo, porque la
/// reserva agotada crece hasta [ClockTheme.reserveSizeSpent].
bool _looksLikeClock(String? text) =>
    text != null && RegExp(r'^-?\d{1,2}:\d{2}$').hasMatch(text);

/// La mitad que pinta ese nombre. La pulsacion larga va sobre la mitad entera,
/// asi que hay que apuntar a ella y no al texto.
Finder _halfShowing(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(PlayerHalf));

/// Arranca el partido y gasta un rato, que es el estado desde el que reiniciar
/// significa algo: con los relojes intactos no se distingue de no hacer nada.
Future<void> _startAndSpend(WidgetTester tester) async {
  _clockOnScreen(tester).start(Player.one);
  await tester.pump();
  await tester.pump(const Duration(seconds: 70));
}

/// Lo transparente que está la invitación a empezar. Siempre está en el árbol,
/// para que su hueco no cambie de tamaño, así que buscarla no dice nada: lo que
/// se mira es su alfa.
double _inviteAlpha(WidgetTester tester) =>
    tester.widget<Text>(find.text('Tap to start').last).style!.color!.a;

/// Deja terminar la presentación del escudo, que dura lo que suman
/// `logoTraceDuration` y `logoSettleDuration`.
///
/// Se avanza a pasos y no de una vez. El contorno se lee antes de arrancar la
/// animación, así que en un solo salto el reloj se adelantaría entero mientras
/// no corre nada y la presentación se quedaría sin empezar. A pasos, la lectura
/// se resuelve en uno de ellos y los siguientes ya mueven la animación.
Future<void> _passReveal(WidgetTester tester) async {
  const step = Duration(milliseconds: 100);
  final total = ClockTheme.logoTraceDuration + ClockTheme.logoSettleDuration;
  // De sobra: lo que importa es que la presentación haya acabado, no clavar
  // su duración.
  for (var spent = Duration.zero; spent <= total * 2; spent += step) {
    await tester.pump(step);
  }
}

Future<void> _confirmReset(WidgetTester tester) async {
  await tester.tap(_resetControl);
  await _settle(tester);
  await tester.tap(find.text('Reset'));
  await _settle(tester);
}

/// El luma del color que más se repite en la escena ya compuesta, que es el
/// del fondo. Un destello es una superficie entera que se aclara, así que la
/// moda lo ve y una media la escondería entre los textos.
/// La luma de un color en la misma escala que [_dominantLuma]: la media de los
/// tres canales.
int _lumaOf(Color color) => ((color.r + color.g + color.b) * 255 / 3).round();

/// El techo de la prueba del destello: el más claro de los dos colores que
/// pueden dominar la pantalla durante la transición. Los ajustes son fondo
/// entero, y en el cronómetro lo que más se repite son las dos tarjetas, que
/// ocupan casi todo. Por encima de ese techo la transición se estaría
/// aclarando, que es justo lo que se vigila.
int _transitionCeiling(ClockColors colors) =>
    math.max(_lumaOf(colors.background), _lumaOf(colors.inactive));

Future<int> _dominantLuma(WidgetTester tester) async {
  final layer =
      tester.binding.rootElement!.renderObject!.debugLayer! as OffsetLayer;

  late int dominant;
  await tester.runAsync(() async {
    final image = await layer.toImage(
      ui.Offset.zero & tester.view.physicalSize,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = data!.buffer.asUint8List();
    image.dispose();

    final histogram = <int, int>{};
    for (var i = 0; i < bytes.length; i += 4) {
      final luma = (bytes[i] + bytes[i + 1] + bytes[i + 2]) ~/ 3;
      histogram.update(luma, (n) => n + 1, ifAbsent: () => 1);
    }
    var most = 0;
    dominant = 0;
    histogram.forEach((luma, count) {
      if (count > most) {
        most = count;
        dominant = luma;
      }
    });
  });
  return dominant;
}

MatchClock _clockOnScreen(WidgetTester tester) =>
    tester.widget<ClockScreen>(find.byType(ClockScreen)).clock;

class _SilentDevice implements AlertDevice {
  const _SilentDevice();

  @override
  Future<void> play(AlertSound sound) async {}

  @override
  Future<void> vibrate(VibrationLevel level) async {}
}

/// El que no comparte nada, para los tests a los que compartir les da igual.
class _MuteSharer implements ReportSharer {
  const _MuteSharer();

  @override
  Future<void> share(
    Uint8List png, {
    required String name,
    String? text,
  }) async {}
}

/// El que apunta lo que le piden, para el test que mira que se comparta.
class _RecordingSharer implements ReportSharer {
  final calls = <({Uint8List png, String name, String? text})>[];

  @override
  Future<void> share(
    Uint8List png, {
    required String name,
    String? text,
  }) async {
    calls.add((png: png, name: name, text: text));
  }
}

class _IgnoredScreen implements Screen {
  const _IgnoredScreen();

  @override
  Future<void> keepOn(bool on) async {}
}
