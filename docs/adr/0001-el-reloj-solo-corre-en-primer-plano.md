# 0001 - El reloj solo corre en primer plano

Fecha: 2026-09-15
Estado: aceptado

## Contexto

Un cronómetro de mesa tiene que seguir midiendo aunque el móvil se bloquee o el
jugador reciba una llamada. La solución habitual es guardar el instante en que
empezó el turno y derivar el tiempo transcurrido del reloj del sistema, de modo que
la cuenta sobreviva a que la aplicación pase a segundo plano.

Esa solución trae consigo el ciclo de vida de cada plataforma, las diferencias entre
iOS y Android al suspender procesos, y la posibilidad de que el reloj del sistema
cambie mientras tanto.

## Decisión

La aplicación solo cuenta el tiempo mientras está en primer plano. Al pasar a
segundo plano, por la razón que sea, el tiempo se pausa y el estado se mantiene.
Al volver, los jugadores encuentran el cronómetro pausado, igual que si alguien
hubiera pulsado el botón.

Mientras un reloj corre, la pantalla se mantiene encendida. Al pausar se libera.

## Consecuencias

El compromiso deja de ser técnico y pasa a ser de los jugadores: mientras el reloj
corre, nadie toca el móvil. Quien necesite cogerlo avisa y pausa.

A cambio, la cuenta es siempre correcta por construcción, sin depender del reloj del
sistema ni de cómo suspenda procesos cada plataforma.

El partido no sobrevive a cerrar la aplicación. Cerrarla a media partida la pierde,
lo mismo que reiniciar el cronómetro.
