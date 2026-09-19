# 0008 - La aplicación conoce la estructura del partido

Fecha: 2026-09-17
Estado: aceptado, modificado en parte por el ADR-0010

Supersede al ADR-0002.

El ADR-0010 cambia tres cosas de aquí: la numeración pasa a ser corrida, de 1 a 16 y
no de 1 a 8 por parte; Time-Out lo declaran los jugadores desde el velo de pausa en
vez de ofrecerse al continuar; y se le llama por su nombre del reglamento, Time-Out y
no "Tiempo Muerto". Lo demás sigue vigente, incluida la regla en sí y que lee la ficha
del equipo pateador.

## Contexto

El ADR-0002 decidió que la aplicación no muestra el turno ni el drive, y el
razonamiento sigue siendo correcto: el resultado 3 de la patada inicial mueve las
fichas de turno del tablero, así que una cuenta automática se separa de la de la
mesa. De ahí la conclusión de entonces, que un número orientativo pero equivocado es
peor que no tener número.

Lo que ha cambiado no es el razonamiento sino lo que se le pide a la aplicación. Esta
sustituye a otra que los jugadores ya usan, y esa lleva la cuenta de turnos y las dos
partes. Renunciar a ellas no es mantener una interfaz limpia: es pedir a la mesa que
acepte menos de lo que ya tenía.

La objeción del ADR-0002 se resuelve, además, por donde no se miró entonces. El
resultado 3 se llama Tiempo Muerto y su regla es cerrada: si la ficha del equipo
pateador está en el turno 6, 7 u 8, ambos entrenadores retroceden un espacio; en
cualquier otro caso, ambos avanzan uno. La aplicación puede aplicarla entera. El
control que el ADR-0002 descartó por ser "un control más" no es un parche genérico
para corregir una cuenta que se desvía, sino la tirada de la patada inicial, que es
parte del juego y que los jugadores ya hacen.

Lo del drive tampoco era lo que parecía. Un drive termina con una anotación, y la
aplicación no la ve, pero tampoco tiene que verla: quien anota pulsa, porque después
de anotar hay que volver a desplegar y el reloj tiene que pararse de todos modos.

## Decisión

La aplicación conoce la estructura del partido: dos partes de ocho turnos por jugador,
divididas en drives.

- **La cuenta es por jugador**, de 1 a 8, y es la que está en el tablero. Los dos
  jugadores no van por el mismo número: el segundo llega a cada número cuando el
  primero ya ha pasado.
- **La parte termina** cuando el segundo jugador pasa su turno 8. El orden de la
  segunda parte lo fijan las reglas, no la aplicación: quien recibe en la primera
  parte juega primero en ella, y en la segunda parte patea y juega segundo.
- **El comienzo de cada drive para el reloj.** Hay que volver a colocar las
  miniaturas, y ese tiempo no es de nadie.
- **Tiempo Muerto se aplica al continuar**, que es cuando se tira la patada inicial:
  después de desplegar, no antes.
- **Se lleva el marcador**, porque quien anota ya lo dice al pulsar. Se muestra en la
  costura y en el acta final, y no se guarda en ninguna parte (ADR-0003).
- **El partido termina** al pasar el turno 8 del segundo jugador de la segunda parte,
  y da paso a un acta con el resultado y los tiempos.

Ocho turnos por parte no se configura. Es la regla, y un ajuste devolvería la
aplicación al terreno genérico del que esta decisión la saca.

## Consecuencias

La aplicación deja de ser un contador de tiempo que no sabe nada de la partida que
mide. Sigue sin decidir nada: aplica reglas que ya están escritas y confirma lo que
los jugadores hacen en la mesa, pero ahora las conoce.

La regla de Tiempo Muerto se aplica sin topes. Desde el turno 8 ambos retroceden y la
parte se alarga; desde el turno 1 ambos avanzan y la parte dura siete. Es lo que hace
el tablero, y toparlo sería la aplicación corrigiendo las reglas.

La cuenta puede seguir desviándose por lo que la aplicación no ve, como un turno que
nadie pasó. Para eso queda una corrección manual, con una pulsación larga sobre el
número. Es el mismo gesto con el que se cambian los nombres, escondido por la misma
razón: se necesita poco y no debe estorbar.

El acta final no se guarda, igual que no se guarda nada (ADR-0003). Para dejar
constancia se hace una captura de pantalla, que es lo que ya decía CONTEXT y que el
acta hace más útil, no menos.

La prórroga queda fuera de esta iteración. El acta la nombrará cuando haya empate,
para que se sepa que la aplicación no la ignora, y se implementará cuando alguna liga
la juegue de verdad.
