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

**pasar turno**: la única acción del jugador activo. Detiene sus relojes y activa
los del oponente.

**bocina**: cada uno de los tres avisos sonoros, de menor a mayor intensidad: quedan
30 segundos de turno, se agota el turno, se agota la reserva. Cada bocina lleva su
vibración (una, dos y tres pulsaciones).

## Reglas del dominio

- Los dos jugadores son simétricos en tiempo: mismo turno, misma reserva.
- El turno se reinicia en cada cambio de jugador. La reserva dura todo el partido.
- Pasar turno funciona siempre, también con la reserva consumiéndose. Lo único que
  lo impide es que el cronómetro esté pausado.
- Pausar y reanudar son el mismo botón, con dos estados excluyentes.
- El partido empieza al tocar al jugador que recibe la patada inicial. No hay botón
  de comenzar.
- La aplicación solo cuenta el tiempo en primer plano. Si se cierra o pasa a
  segundo plano, el tiempo se pausa. El compromiso es no tocar el móvil mientras
  corre el reloj.
- La pantalla se mantiene encendida mientras un reloj corre, y se libera al pausar.

## Fuera del alcance

Sin contador de turnos ni de drives, sin descanso entre partes, sin marcador. El
resultado 3 de la patada inicial mueve la cuenta de turnos del tablero, así que un
contador se desincronizaría y habría que corregirlo a mano: más fricción que valor.

Sin historial de partidos. Para dejar constancia de una partida se hace una captura
de pantalla, y por eso la aplicación no bloquea las capturas.

Sin modo espectador ni modo árbitro. Sin red, sin cuentas, sin copia de seguridad.
