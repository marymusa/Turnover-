import 'package:flutter_test/flutter_test.dart';
import 'package:turnover/domain/awake_guard.dart';
import 'package:turnover/domain/match_clock.dart';

void main() {
  group('la pantalla encendida', () {
    test('sin partido empezado no se mantiene encendida', () {
      final (:clock, :screen, :guard) = newParts();

      guard.sync();

      expect(screen.isOn, isFalse);
    });

    test('se mantiene encendida mientras un reloj corre', () {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);

      guard.sync();

      expect(screen.isOn, isTrue);
    });

    test('se libera al pausar', () {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);
      guard.sync();

      clock.pause();
      guard.sync();

      expect(screen.isOn, isFalse);
    });

    test('vuelve a encenderse al reanudar', () {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);
      guard.sync();
      clock.pause();
      guard.sync();

      clock.resume();
      guard.sync();

      expect(screen.isOn, isTrue);
    });

    test('se libera cuando el partido se reinicia', () {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);
      guard.sync();

      clock.reset();
      guard.sync();

      expect(screen.isOn, isFalse);
    });

    // Sigue encendida con la reserva agotada: el overtime también se juega, y
    // que la pantalla se apagase ahí sería peor que en ningún otro momento.
    test('sigue encendida en overtime', () {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);
      clock.advance(const Duration(minutes: 20));

      guard.sync();

      expect(screen.isOn, isTrue);
    });

    // Pedirle lo mismo al aparato dos veces seguidas no le cuesta nada al
    // jugador, pero cada llamada cruza a la plataforma: se pide solo cuando
    // cambia.
    test('no se le pide dos veces lo mismo al aparato', () async {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);

      await guard.sync();
      await guard.sync();
      await guard.sync();

      expect(screen.requests, [true]);
    });

    // Si la plataforma falla, lo pedido no es lo que hay: dar por bueno lo que
    // no llegó a pasar dejaría la pantalla encendida el resto de la partida,
    // que es justo lo que este módulo evita.
    test('un fallo del aparato se reintenta en el siguiente toque', () async {
      final (:clock, :screen, :guard) = newParts(screenFails: true);
      clock.start(Player.one);

      await guard.sync();
      screen.fails = false;
      await guard.sync();

      expect(screen.isOn, isTrue);
    });

    test('soltar la pantalla al terminar no la deja pedida', () async {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);
      await guard.sync();

      await guard.release();

      expect(screen.isOn, isFalse);
    });
  });

  // ADR-0001: dejar el primer plano pausa, y lo hace llevando al mismo estado
  // que produce el botón, no a uno nuevo.
  group('el segundo plano', () {
    test('pausa el partido en curso', () {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);

      guard.onLeftForeground();

      expect(clock.state, MatchState.paused);
    });

    test('libera la pantalla al irse', () async {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);
      await guard.sync();

      await guard.onLeftForeground();

      expect(screen.isOn, isFalse);
    });

    test('conserva íntegro el estado del partido', () {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);
      clock.advance(const Duration(seconds: 70));

      guard.onLeftForeground();

      expect(clock.activePlayer, Player.one);
      expect(
        clock.turnOf(Player.one),
        const Duration(minutes: 4) - const Duration(seconds: 70),
      );
    });

    // Volver no reanuda: los jugadores encuentran el cronómetro pausado y lo
    // reanudan ellos.
    test('volver a primer plano no reanuda', () async {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);
      await guard.onLeftForeground();

      await guard.onReturnedToForeground();

      expect(clock.state, MatchState.paused);
      expect(screen.isOn, isFalse);
    });

    test('ningún reloj avanza mientras no está en primer plano', () {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);
      guard.onLeftForeground();

      clock.advance(const Duration(seconds: 30));

      expect(clock.turnOf(Player.one), const Duration(minutes: 4));
    });

    test('sin partido empezado el segundo plano no lo empieza', () {
      final (:clock, :screen, :guard) = newParts();

      guard.onLeftForeground();

      expect(clock.state, MatchState.notStarted);
    });

    test('irse ya pausado no cambia nada', () {
      final (:clock, :screen, :guard) = newParts();
      clock.start(Player.one);
      clock.pause();

      guard.onLeftForeground();

      expect(clock.state, MatchState.paused);
      expect(clock.activePlayer, Player.one);
    });
  });
}

class FakeScreen implements Screen {
  FakeScreen({this.fails = false});

  bool fails;
  final requests = <bool>[];

  bool get isOn => requests.isNotEmpty && requests.last;

  @override
  Future<void> keepOn(bool on) async {
    if (fails) throw Exception('sin pantalla');
    requests.add(on);
  }
}

({MatchClock clock, FakeScreen screen, AwakeGuard guard}) newParts({
  bool screenFails = false,
}) {
  final clock = MatchClock(
    turn: const Duration(minutes: 4),
    reserve: const Duration(minutes: 15),
    warning: const Duration(seconds: 30),
  );
  final screen = FakeScreen(fails: screenFails);
  return (clock: clock, screen: screen, guard: AwakeGuard(clock, screen));
}
