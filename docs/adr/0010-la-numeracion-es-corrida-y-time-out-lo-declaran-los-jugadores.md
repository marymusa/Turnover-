# 0010 - La numeración es corrida y Time-Out lo declaran los jugadores

Fecha: 2026-09-19
Estado: aceptado

Modifica al ADR-0008 en tres puntos: cómo se numeran los turnos, dónde se ofrece
Time-Out y con qué nombre se le llama. El resto del ADR-0008 sigue en pie.

## Contexto

El ADR-0008 decidió que la cuenta es por jugador, de 1 a 8, y que es la del tablero.
Con esa numeración la parte no se distingue en el número, así que hacía falta un
indicador aparte, y el prototipo del ticket #14 lo probó en la costura. No salió: la
etiqueta girada se leía, pero el sitio simétrico que le tocaba al marcador quedaba
recortado contra el borde de la tarjeta, y además era un elemento permanente en
pantalla para algo que cambia una vez por partido.

La alternativa apareció mirando el prototipo: si la segunda parte numera de 9 a 16, la
parte se lee en el propio número y no hace falta nada más.

Eso dejaba un problema. Time-Out mueve las fichas sin topes, así que una parte puede
durar siete turnos o nueve, y entonces la segunda parte no empieza necesariamente en
el 9. Con la aplicación detectando la tirada no había respuesta buena: o la numeración
mentía sobre lo jugado, o el 9 dejaba de marcar el comienzo de la parte.

El problema se disuelve al darse cuenta de que la aplicación no tiene por qué
detectar nada. Los jugadores ya paran el reloj para desplegar; declarar el Time-Out
ahí es una pulsación en un momento en que ya están tocando la pantalla.

## Decisión

**La numeración es corrida.** La primera parte va de 1 a 8 y la segunda de 9 a 16. La
parte se lee en el número y no hay indicador de parte.

El número que se muestra es de cara al jugador. La regla lee el **turno de tablero**:

    turnoTablero = ((mostrado - 1) % 8) + 1

La segunda parte siempre empieza en el 9, pase lo que pase en la primera.

**Time-Out lo declaran los jugadores.** Hay un botón en el velo de pausa; al pulsarlo
se quita la pausa y se aplica la regla. La aplicación no conoce la tirada ni pregunta
por ella.

La regla no cambia respecto al ADR-0008: lee la ficha del equipo pateador, que es el
jugador inactivo, y si su turno de tablero es 6, 7 u 8 ambos retroceden un espacio; en
cualquier otro caso ambos avanzan uno. Sin topes.

**Se llama Time-Out**, que es su nombre en el reglamento, y no "Tiempo Muerto". Es el
resultado de una tabla, como "drive", y los nombres del reglamento no se traducen.

### Los casos

| caso | antes | activo | pateador | tablero | resultado |
|---|---|---|---|---|---|
| UC1 | 9, 9 | p2 | p1 (9) | 1 | 10, 10 |
| UC2 | 8, 8 | p1 | p2 (8) | 8 | 7, 7 |
| UC3 | 1, 1 | p1 | p2 (1) | 1 | 2, 2 |
| UC4 | 9, 9 | p1 | p2 (9) | 1 | 10, 10 |
| UC5 | 7, 6 | p1 | p2 (6) | 6 | 6, 5 |
| UC6 | 4, 3 | p1 | p2 (3) | 3 | 5, 4 |
| UC7 | 6, 5 | p1 | p2 (5) | 5 | 7, 6 |

UC1 y UC4 son los que obligan a leer el turno de tablero y no el mostrado: 9 es
tablero 1, así que avanzan. Leyendo el número mostrado, del 9 al 16 no se retrocedería
nunca y la segunda parte se comportaría distinto de la primera.

UC7 es el único que distingue leer al pateador de leer al jugador activo. En los otros
seis las dos lecturas coinciden, así que no prueban nada: el activo p1 está en tablero
6, que retrocedería, y el pateador p2 en tablero 5, que avanza. El resultado es 7 y 6,
que es lo que ya decía el ADR-0008.

## Consecuencias

La cuenta deja de coincidir con la ficha del tablero en la segunda parte, que es lo
que el ADR-0008 pedía expresamente. Se acepta porque el turno de tablero se recupera
con una operación y porque lo que se gana, que la parte no necesite sitio en pantalla,
vale más que la coincidencia literal. El jugador que quiera comparar con su ficha
resta ocho.

Se aparta de lo que decía el ADR-0008 sobre **cuándo** se ofrece Time-Out. Allí era al
continuar desde el despliegue, porque la tirada de la patada inicial es posterior a
colocar las miniaturas. Ahora está en el velo de pausa, que es donde los jugadores ya
están.

La pregunta de si el velo de despliegue llevaría también el botón se queda sin
plantear: los drives salen del alcance de esta versión y no hay más velo que el de
pausa. Vuelve a abrirse cuando se retomen.

La aplicación sigue sin decidir nada, y ahora menos: ya no infiere una tirada, la
recoge. Es coherente con ser un árbitro y no un juez.

Una cuenta declarada a mano puede quedar mal si nadie pulsa el botón. Para eso sigue
estando la corrección manual con una pulsación larga, que el ADR-0008 ya reservaba.
