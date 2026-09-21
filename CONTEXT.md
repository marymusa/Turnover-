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

En la interfaz en castellano sí se traduce, y allí se lee "Tiempo muerto" (ADR-0011).
El código, este glosario y los ADR lo siguen llamando Time-Out: es la misma separación
que hay entre `reserveClock` y el tiempo extra, donde el nombre interno y el visible no
coinciden. El botón del velo se vio en el móvil y el nombre en inglés se leía como otra
forma de decir "pausado", que es lo que el velo ya dice.

La aplicación no lo detecta: lo declaran los jugadores con un botón en el velo de
pausa, que al pulsarlo quita la pausa y aplica la regla (ADR-0010). La tirada es
posterior al despliegue, y los jugadores ya paran para desplegar.

La regla lee el **turno de tablero**, de 1 a 8, y no el número que se muestra, que en
la segunda parte va de 9 a 16: `turnoTablero = ((mostrado - 1) % 8) + 1`. Y lee la
ficha del equipo pateador, que es el jugador inactivo en ese momento.

**anotación**: el tanto que termina un drive. Nunca "gol", que es de otro juego. Lo
apunta quien anota al pulsar, porque después hay que desplegar otra vez.

**acta**: la pantalla que cierra el partido, al pasar el turno 16 del segundo jugador.
No se guarda (ADR-0003).

Cuenta la misma historia tres veces, cada una con más detalle: el **tiempo de juego**,
que es lo que han consumido los dos relojes, con el **total** debajo, que lo incluye
todo y del que se resta el tiempo parado; una **barra enfrentada** que reparte ese
tiempo de juego entre los dos, con el de cada uno encima de su tramo; y una **gráfica
por turnos** con una línea por jugador, que dice lo que duró cada turno y dónde se
atascó la partida.

La gráfica lleva además, por cada jugador y a trazos, **lo que le dura un turno de
media**: es lo que convierte las dos líneas en una comparación, porque cada pico se
lee como lo que se salió de su propia media. A trazos justamente porque es una línea
de referencia y no un dato medido turno a turno.

El acta **se monta sola** al salir, una vez y en unos cuatro segundos: las cifras suben
desde cero, la barra parte del reparto a medias y se abre hasta donde cayó, y las dos
líneas recorren sus turnos; las medias entran al final, cuando ya hay dibujo del que
sacarlas. No es un adorno permanente, es la presentación de un resultado. Quien lleve
las animaciones apagadas en el sistema ve el acta hecha desde el primer fotograma, y
compartir a media animación la salta al final: la foto es del acta acabada.

El color de cada jugador, el de su mitad durante el partido, lo atraviesa todo: su
pastilla, su tramo de la barra, su línea y su media. Los dos están medidos como paleta de datos
y no elegidos a ojo, y en modo oscuro no son los mismos valores que en la mesa, porque
sobre el fondo casi negro los del partido no llegan al contraste que pide una marca.

El acta **se comparte**: un botón hace una foto de ella y la saca por el menú del
sistema. La foto es solo el acta, sin los botones, porque en la imagen que llega al
responsable de la liga no hay nada que pulsar. Sigue sin guardarse nada (ADR-0003): lo
que la aplicación hace es entregar unos bytes, y el temporal que haga falta para
compartirlos es del sistema y se lo lleva él. La captura de pantalla a mano sigue
valiendo, y ahora hay además un camino que no depende de acertar con los botones del
teléfono.

Es la única pantalla que no se parte en dos mitades enfrentadas. Se lee entera de
arriba abajo, en vertical: el partido ya ha terminado, los dos jugadores miran la
misma pantalla, y de ella se hace una captura que va al responsable de la liga, que
la abre como cualquier otra imagen. Media acta girada sería media captura del revés.

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

**tacto**: la respuesta al dedo, lo que confirma que un toque ha entrado. No es la
vibración de las bocinas y no comparte nada con ella: aquella avisa a quien no está
mirando la pantalla y sale por el canal de avisos, y el tacto contesta a un dedo que
está encima del cristal y sale por el canal de las hápticas de la vista, el que el
jugador apaga con la casilla de vibrar al tocar. Que esa casilla lo silencie es lo
que el jugador ha pedido, no un fallo. Solo lo llevan los cambios de estado: abrir un
diálogo no cambia nada y cancelar deja las cosas como estaban, así que ninguno de los
dos responde (ADR-0014).

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
- El cambio de parte no es un pase de turno más: el pase que cierra la primera parte
  entrega el turno a quien abre la segunda y acto seguido pausa, en vez de arrancarle
  el reloj en el mismo pase. Es un despliegue, con sus lados que se cambian y su
  patada inicial, y el velo de pausa hace de parón: dice "Segunda parte" en su fila
  de estado, que es también lo que explica el salto del 8 al 9 que se lee por detrás.
  Lo quita el mismo toque que quita cualquier pausa.
- La cuenta de turnos es de cada jugador. La primera parte va de 1 a 8 y la segunda de
  9 a 16: la numeración es corrida, y así la parte se lee en el propio número sin
  ningún indicador aparte (ADR-0010). El turno de tablero, que es el que está en la
  mesa y el que leen las reglas, se recupera con `((mostrado - 1) % 8) + 1`.
- Time-Out mueve la cuenta según su regla, sin topes: una parte puede durar siete
  turnos o nueve, como en la mesa.
- La corrección a mano, para lo que la aplicación no ve como un turno que nadie pasó,
  todavía no existe. El ADR-0008 la reservaba como una pulsación larga sobre el número,
  y al implementar la cuenta se vio que ese gesto no se sostiene: no lo anuncia nada y
  hace lo mismo que Time-Out con la dirección elegida a mano. Se decidirá en su propio
  ticket, y cuando llegue moverá las dos cuentas a la vez, que es como se corrige en la
  mesa: nunca la de un jugador suelto.
- El velo de pausa lleva el botón de Time-Out. Pulsarlo pregunta antes, porque mueve
  las dos cuentas y no se deshace, y la pregunta dice hacia dónde van a moverse, que es
  lo que se comprueba contra la ficha. Al confirmar quita la pausa y aplica la regla
  (ADR-0010).
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
pero no las entradas en que se divide una parte: no hay botón de anotar y no hay
marcador. El glosario conserva los términos, que son del juego y no de la aplicación,
y se retomarán con sus tickets.

De los despliegues, el único que la aplicación sabe localizar es el del cambio de
parte, que es el que para con el velo de pausa. Los demás empiezan con una anotación,
que la aplicación no ve, así que no hay parón que poner: el velo de despliegue propio
espera a su ticket, y con él la pregunta que el ADR-0010 dejó abierta, la de si ese
velo llevaría también el botón de Time-Out.

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

Sin publicidad (ADR-0012). No es solo que hoy no la haya: se estudiaron los tres
momentos en los que ningún reloj corre y se descartó, porque el SDK trae red, permisos
y consentimiento el primer día a cambio de unos euros al año. El coste recurrente es el
de iOS y se cubre por el precio, no por los anuncios.
