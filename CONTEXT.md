# Turnover!

Cronómetro para partidas de Blood Bowl. Un solo móvil sobre la mesa, dos jugadores,
sin red y sin sincronización.

La aplicación es un árbitro, no un juez: mide el tiempo, avisa con bocinas y
vibraciones, y no decide nada. Lo que ocurre cuando a un jugador se le agota el
tiempo extra lo deciden los jugadores.

## Glosario

**turno**: el tiempo reglamentario del que dispone el jugador activo, 4 minutos por
defecto. Se reinicia al principio de cada turno.

**tiempo extra**: el tiempo adicional del que dispone cada jugador para todo el
partido, 15 minutos por defecto. Solo baja, nunca se recarga. Empieza a consumirse
en cuanto el turno llega a cero.

Nunca "bolsa de tiempo". En el código sigue siendo `reserveClock`, y los ajustes
guardados conservan su clave: el nombre de cara al jugador cambió después, y
renombrar el almacenamiento habría perdido la configuración de quien ya tenía la
aplicación instalada.

**jugador activo**: aquel cuyo turno corre. Solo hay uno en cada momento, y solo a
él le suenan los avisos.

**jugador inactivo**: el oponente mientras espera. Sus dos relojes están detenidos.

**overtime**: el tiempo que sigue contando una vez agotado el tiempo extra, mostrado en
negativo. No detiene nada: deja constancia de cuánto se ha pasado un jugador.

**aviso previo**: los segundos que quedan cuando suena una bocina suave. Son dos,
el temprano y el tardío, y se configuran con los dos agarres de un mismo
deslizador: juntos son un aviso, separados son dos, y los dos en cero es no
avisar. Por defecto son dos, a 55 y a 30 segundos: nacen separados para que se
vea que son dos y que se mueven. Valen igual para el turno y para el tiempo
extra.

**agarre**: cada uno de los dos puntos que se arrastran en el deslizador de los
avisos previos. El de la derecha marca el aviso temprano, porque el deslizador
mide lo que queda cuando suena y al temprano le queda más. En el código, el
`RangeSlider` de Material.

**pasar turno**: la única acción del jugador activo. Detiene sus relojes y activa
los del oponente.

**parte**: cada una de las dos mitades del partido, de ocho turnos por jugador. La
primera parte termina cuando el segundo jugador pasa su turno 8.

**drive**: cada una de las entradas en que se divide una parte. Empieza con el
despliegue de las miniaturas y la patada inicial, y termina con una anotación o con el
final de la parte. No se traduce: es el término del reglamento.

**despliegue**: el parón al comienzo de cada drive, mientras los jugadores colocan las
miniaturas. El reloj no corre y ese tiempo no es de nadie.

**Time-Out**: el resultado 3 de la patada inicial. Si la ficha del equipo pateador
está en el turno 6, 7 u 8, ambos entrenadores retroceden un espacio; en cualquier otro
caso, ambos avanzan uno. Se aplica sin topes.

Se llama por su nombre del reglamento en inglés, como "drive": es el resultado de una
tabla, no una descripción. Antes figuraba aquí como "Tiempo Muerto" (ADR-0010).

La aplicación no lo detecta: lo declaran los jugadores con un botón en el velo de
pausa, que al pulsarlo quita la pausa y aplica la regla (ADR-0010). La tirada es
posterior al despliegue, y los jugadores ya paran para desplegar.

La regla lee el **turno de tablero**, de 1 a 8, y no el número que se muestra, que en
la segunda parte va de 9 a 16: `turnoTablero = ((mostrado - 1) % 8) + 1`. Y lee la
ficha del equipo pateador, que es el jugador inactivo en ese momento.

**anotación**: el tanto que termina un drive. Nunca "gol", que es de otro juego. Lo
apunta quien anota al pulsar, porque después hay que desplegar otra vez.

**acta**: la pantalla que cierra el partido, al pasar el turno 16 del segundo jugador.
Muestra el tiempo de juego total, el que ha jugado cada uno y el que ha estado parado,
que es el de las pausas. No se guarda (ADR-0003).

No muestra resultado: la anotación queda fuera de esta versión, así que no hay
marcador que enseñar.

**bocina**: cada uno de los tres sonidos, de menor a mayor intensidad: queda un
aviso previo, se agota el turno, se agota el tiempo extra. Son tres bocinas para
seis avisos, porque los cuatro previos, los dos del turno y los dos del tiempo
extra, comparten la suave: lo que distingue al temprano del tardío es el reloj,
no el sonido. Cada bocina lleva su vibración, en la misma intensidad que ella.

**intensidad**: lo que gradúa un aviso, de suave a fuerte a más fuerte. La comparten
la bocina y la vibración, que salen siempre a la par: no hay aviso que suene fuerte y
vibre flojo. En el código, `AlertSound` y `VibrationLevel`. Nunca un número de
pulsaciones: lo que sube con la gravedad son la fuerza y la duración de una sola
vibración, no cuántas son (ADR-0005).

## Reglas del dominio

- Los dos jugadores son simétricos en tiempo: mismo turno, mismo tiempo extra.
- El turno se reinicia en cada cambio de jugador. El tiempo extra dura todo el partido.
- Pasar turno funciona siempre, también con el tiempo extra consumiéndose. Lo único que
  lo impide es que el cronómetro esté pausado.
- Pausar y reanudar son el mismo botón, con dos estados excluyentes. Pausado se
  reanuda además tocando en cualquier sitio: el velo que lo anuncia se come el
  toque, para que reanudar no se confunda con pasar turno.
- El partido empieza al tocar al jugador que recibe la patada inicial. No hay botón
  de comenzar. La invitación de cada mitad dice "Pulsa para comenzar" y no de quién
  es la patada: el reloj no reparte el saque, lo reparte el dado antes de tocar
  nada, y la pantalla solo recoge lo que los jugadores ya han acordado. Ese toque
  arranca el reloj del jugador que recibe.
- La segunda parte no se toca para elegir lado. El orden lo fijan las reglas y la
  aplicación no reparte nada: quien recibe en la primera parte juega primero en ella,
  y en la segunda patea y juega segundo.
- La cuenta de turnos es de cada jugador. La primera parte va de 1 a 8 y la segunda de
  9 a 16: la numeración es corrida, y así la parte se lee en el propio número sin
  ningún indicador aparte (ADR-0010). El turno de tablero, que es el que está en la
  mesa y el que leen las reglas, se recupera con `((mostrado - 1) % 8) + 1`.
- Time-Out mueve la cuenta según su regla, sin topes: una parte puede durar siete
  turnos o nueve, como en la mesa. Lo que la aplicación no ve, como un turno que nadie
  pasó, se corrige a mano con una pulsación larga sobre el número.
- El velo de pausa lleva el botón de Time-Out. Pulsarlo quita la pausa y aplica la
  regla (ADR-0010).
- La aplicación solo cuenta el tiempo en primer plano. Si se cierra o pasa a
  segundo plano, el tiempo se pausa. El compromiso es no tocar el móvil mientras
  corre el reloj.
- Volver atrás con el partido empezado no es pausar: cierra la aplicación, y el partido
  no se guarda en ninguna parte (ADR-0003), así que se pierde entero. Por eso se pausa y
  se pregunta antes, describiendo lo que se pierde. Sin empezar no hay nada que perder y
  se sale sin más.
- La pantalla se mantiene encendida mientras un reloj corre, y se libera al pausar.
- El modo claro u oscuro lo decide el aparato y la aplicación no lo pregunta ni ofrece
  un selector propio. Con la luz cambian el marco y la mitad del jugador que espera.
  La mitad cuyo turno corre se queda con su color en los dos modos, porque el color es
  lo único que dice de quién es el turno. Eso parte en dos la letra y el aviso de turno
  agotado, que van cada uno con su mitad (ADR-0009).
- Los tiempos (turno, tiempo extra y los dos avisos previos) se configuran en una pantalla propia,
  a la que solo se llega antes de empezar: los tiempos se pactan con el partido parado
  (ADR-0006). Los nombres se pactan igual, y por la misma razón: con el partido en marcha
  la pantalla no ofrece nada que no sea jugar.
- Un cambio de tiempos redimensiona, no reinicia: lo ya gastado se conserva, de modo que
  ampliar el tiempo extra de quince a veinte minutos con seis gastados deja catorce. Es la
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

Sin drives y sin anotación, de momento. La aplicación conoce los turnos y las partes,
pero no las entradas en que se divide una parte: no hay velo de despliegue, no hay
botón de anotar y no hay marcador. El glosario conserva los términos, que son del
juego y no de la aplicación, y se retomarán con sus tickets.

Sin prórroga. Seguía fuera (ADR-0008), y sin marcador tampoco hay empate que nombrar,
así que el acta ni la menciona.

Los ocho turnos por parte no se configuran. Es la regla de Blood Bowl, y un ajuste
devolvería la aplicación al terreno genérico.

Sin historial de partidos. Ni siquiera el acta se guarda (ADR-0003). Para dejar
constancia de una partida se hace una captura de pantalla, y por eso la aplicación no
bloquea las capturas.

Sin modo espectador ni modo árbitro. Sin red y sin cuentas. Tampoco se pide copia de
seguridad en la nube, aunque en iOS los ajustes viajen igualmente en la de iCloud, que
es algo que no se puede desactivar sin rehacer el almacenamiento (ADR-0003).
