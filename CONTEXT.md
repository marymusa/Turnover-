# Turnover!

Cronómetro para partidas de Blood Bowl. Un solo móvil sobre la mesa, dos jugadores,
sin red y sin sincronización.

La aplicación es un árbitro, no un juez: mide el tiempo, avisa con bocinas y
vibraciones, y no decide nada. Lo que ocurre cuando a un jugador se le agota la
reserva lo deciden los jugadores.

## Glosario

**turno**: el tiempo reglamentario del que dispone el jugador activo, 4 minutos por
defecto. Se reinicia al principio de cada turno.

**reserva**: el tiempo adicional del que dispone cada jugador para todo el partido,
15 minutos por defecto. Solo baja, nunca se recarga. Empieza a consumirse en cuanto
el turno llega a cero.

Nunca "bolsa de tiempo": la reserva es lo que se guarda para cuando hace falta, y
"bolsa" no lo dice. En el código, `turnClock` y `reserveClock`.

**jugador activo**: aquel cuyo turno corre. Solo hay uno en cada momento, y solo a
él le suenan los avisos.

**jugador inactivo**: el oponente mientras espera. Sus dos relojes están detenidos.

**overtime**: el tiempo que sigue contando una vez agotada la reserva, mostrado en
negativo. No detiene nada: deja constancia de cuánto se ha pasado un jugador.

**aviso previo**: los segundos que quedan de turno cuando suena la primera
bocina, 30 por defecto. Es uno de los tres tiempos configurables.

**pasar turno**: la única acción del jugador activo. Detiene sus relojes y activa
los del oponente.

**bocina**: cada uno de los tres avisos sonoros, de menor a mayor intensidad: queda
el aviso previo de turno, se agota el turno, se agota la reserva. Cada bocina lleva su
vibración, en la misma intensidad que ella.

**intensidad**: lo que gradúa un aviso, de suave a fuerte a más fuerte. La comparten
la bocina y la vibración, que salen siempre a la par: no hay aviso que suene fuerte y
vibre flojo. En el código, `AlertSound` y `VibrationLevel`. Nunca un número de
pulsaciones: lo que sube con la gravedad es la fuerza del golpe, no cuántos son
(ADR-0005).

## Reglas del dominio

- Los dos jugadores son simétricos en tiempo: mismo turno, misma reserva.
- El turno se reinicia en cada cambio de jugador. La reserva dura todo el partido.
- Pasar turno funciona siempre, también con la reserva consumiéndose. Lo único que
  lo impide es que el cronómetro esté pausado.
- Pausar y reanudar son el mismo botón, con dos estados excluyentes. Pausado se
  reanuda además tocando en cualquier sitio: el velo que lo anuncia se come el
  toque, para que reanudar no se confunda con pasar turno.
- El partido empieza al tocar al jugador que recibe la patada inicial. No hay botón
  de comenzar.
- La aplicación solo cuenta el tiempo en primer plano. Si se cierra o pasa a
  segundo plano, el tiempo se pausa. El compromiso es no tocar el móvil mientras
  corre el reloj.
- La pantalla se mantiene encendida mientras un reloj corre, y se libera al pausar.
- Los tres tiempos (turno, reserva y aviso previo) se configuran en una pantalla propia,
  a la que solo se llega antes de empezar: los tiempos se pactan con el partido parado
  (ADR-0006). Los nombres se pactan igual, y por la misma razón: con el partido en marcha
  la pantalla no ofrece nada que no sea jugar.
- Un cambio de tiempos redimensiona, no reinicia: lo ya gastado se conserva, de modo que
  ampliar la reserva de quince a veinte minutos con seis gastados deja catorce. Es la
  regla del reloj y vale siempre, aunque a los ajustes solo se llegue antes de empezar.
- Los nombres son una etiqueta y no tocan ningún reloj, pero solo se cambian antes de
  empezar, con una pulsación larga sobre la mitad del jugador. La mitad ya sirve para
  pasar turno, que es un toque, y los dos gestos no pueden convivir con el partido en
  marcha: un dedo lento abriría un diálogo en mitad del juego. Por defecto "Yo" y
  "Mi rival", localizados: el móvil es de uno de los dos y los nombres lo dicen, en vez
  de numerar a dos jugadores intercambiables. Borrar el nombre entero devuelve al valor
  por defecto.
- Lo que se guarda en el dispositivo son los tres tiempos y el nombre del jugador uno,
  y nada más: ni relojes, ni partido en curso, ni historial (ADR-0003). Al reiniciar el
  cronómetro, el del jugador dos vuelve a su valor por defecto.

## Fuera del alcance

Sin contador de turnos ni de drives, sin descanso entre partes, sin marcador. El
resultado 3 de la patada inicial mueve la cuenta de turnos del tablero, así que un
contador se desincronizaría y habría que corregirlo a mano: más fricción que valor.

Sin historial de partidos. Para dejar constancia de una partida se hace una captura
de pantalla, y por eso la aplicación no bloquea las capturas.

Sin modo espectador ni modo árbitro. Sin red y sin cuentas. Tampoco se pide copia de
seguridad en la nube, aunque en iOS los ajustes viajen igualmente en la de iCloud, que
es algo que no se puede desactivar sin rehacer el almacenamiento (ADR-0003).
