# 0002 - Sin contador de turnos ni de drives

Fecha: 2026-09-15
Estado: aceptado

## Contexto

Mostrar en qué turno y en qué drive va la partida es agradable y parecía barato: la
aplicación ya sabe cuántas veces se ha pasado turno.

No lo es. El resultado 3 de la patada inicial mueve la cuenta de turnos del tablero,
de manera que la cuenta de la aplicación y la de la mesa se separan. Un drive, además,
termina con una anotación, que la aplicación no puede ver.

Las salidas posibles eran tres: dejar la cuenta como orientativa y aceptar que se
desvíe, dar a los jugadores un control para corregirla a mano, o no mostrarla.

## Decisión

No se muestra ni el turno ni el drive. La aplicación es un contador de tiempo y no
sabe nada de la partida que mide.

Queda fuera, por lo mismo, el descanso entre la primera y la segunda parte: depende
de contar los 16 turnos.

## Consecuencias

Un número orientativo pero equivocado es peor que no tener número: obliga a
descontarlo mentalmente justo cuando los jugadores discuten por la cuenta. Corregirlo
a mano habría hecho falta un control más en una interfaz cuyo valor está en tener
solo dos.

Si más adelante se quiere, se añade encima de lo que hay. Nada de lo que se construye
ahora lo impide.
