# 0006 - Los tiempos solo se configuran antes de empezar

Fecha: 2026-09-16
Estado: aceptado

## Contexto

Los tres tiempos configurables son el turno, la reserva y el aviso previo. El reloj
sabe redimensionarse sin reiniciarse, así que cambiarlos a media partida es posible
sin perder lo gastado: ampliar la reserva de quince a veinte minutos con seis
gastados deja catorce.

Que se pueda no quiere decir que convenga. Los tiempos son lo que los dos jugadores
han pactado antes de sentarse, y la aplicación es un árbitro que los mide, no un
juez que los negocia. Un acceso a los ajustes con el partido en marcha invita a
tocarlos con el reloj del oponente corriendo, que es justo la discusión que el
cronómetro existe para evitar.

Los nombres son otra cosa: una etiqueta que se corrige porque estaba mal escrita, que
no toca ningún reloj y no altera nada de lo pactado. Nada en el dominio impide
cambiarlos con el partido en marcha.

Lo que lo impide es el dedo. Renombrar se pide con una pulsación larga sobre la mitad
del jugador, y esa misma mitad es la que pasa turno con un toque. Una pulsación larga
empieza siendo un toque: quien pasa turno con el pulgar apoyado medio segundo de más
se encuentra un diálogo encima en mitad de la jugada. Los dos gestos no pueden convivir
sobre la misma superficie mientras el reloj corre.

## Decisión

A los ajustes de tiempo solo se llega con el partido sin empezar. Con el partido en
marcha, pausado incluido, no hay acceso: la costura lleva pasar turno, pausar y
reiniciar, y nada más.

Los nombres tampoco se cambian con el partido empezado. Se pactan antes, como los
tiempos, con una pulsación larga sobre la mitad de cada jugador. La asimetría de qué
nombre sobrevive sigue siendo la del ADR-0003.

La regla de redimensionar sin reiniciar se queda en `MatchClock`, aunque hoy nadie
pueda llegar a ella a media partida. Es del reloj, no de la pantalla, y quitarla
sería perder una regla correcta para ahorrar unas líneas.

## Consecuencias

Contradice la historia 44 del planteamiento inicial, que pedía corregir los tiempos
sobre la marcha. Se acepta a sabiendas: la historia describía una capacidad, y lo que
se decide aquí es que esa capacidad hace más daño que bien en la mesa.

Contradice también la historia 41, que pedía cambiar los nombres en cualquier momento.
Se acepta por lo mismo, y con una compensación: el gesto pasa a cubrir la mitad entera
en vez de solo el texto del nombre, que era pequeño y nadie encontraba. Se gana en
poder usarlo quien no sabía que existía, y se pierde en poder usarlo a media partida.
Un nombre mal escrito se aguanta hasta el final del partido, o se reinicia.

Para cambiar un tiempo con el partido ya empezado hay que reiniciar, lo que pierde el
partido en curso. Es el precio, y es deliberado: si hay que renegociar los tiempos, la
partida se ha parado de todas formas.

Si algún día se quiere volver atrás, el cable ya está puesto: basta con pintar el
acceso en la costura. Nada del dominio hay que tocar.
