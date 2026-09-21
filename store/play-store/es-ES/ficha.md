# Ficha de Play Store (es-ES)

Todo lo de aquí se copia tal cual en Play Console. Los límites de caracteres son
los que impone la tienda y cada campo lleva el suyo contado.

Esta es la ficha maestra: la descripción de App Store sale de aquí con dos
cambios contados, y la de inglés es su traducción. Al tocar un texto de aquí hay
que mirar `../en-US/ficha.md` y `../../app-store/es-ES/ficha.md`.

## Nombre de la aplicación

Límite: 30 caracteres. Ocupa 9.

```
Turnover!
```

## Descripción breve

Límite: 80 caracteres. Ocupa 66.

```
Cronómetro, cuenta de turnos y acta para juegos de mesa por turnos
```

La marca no aparece aquí a propósito: el nombre y la descripción breve son los
campos que indexa la tienda, y nombrar una marca ajena en ellos es lo que más
riesgo tiene (ADR-0007). En la descripción completa sí se nombra, que es uso
nominativo y va con su aviso al final.

## Descripción completa

Límite: 4000 caracteres. Ocupa 3730.

```
Turnover! mide el tiempo de una partida a dos, con un solo móvil sobre la mesa.
Sin cuentas, sin red y sin registrarse: se abre y se juega.

Está pensado para partidos de Blood Bowl, donde cada jugador dispone de un turno
reglamentario y de un tiempo extra para todo el encuentro, pero sirve para cualquier
juego de mesa por turnos que se juegue con reloj.

CÓMO FUNCIONA

La pantalla se parte en dos, una mitad para cada jugador, y cada una se lee de
frente desde su lado de la mesa. Quien toca su mitad recibe la patada inicial y
arranca el partido. A partir de ahí, un toque pasa el turno.

LOS DOS RELOJES

El turno es el tiempo reglamentario de cada jugada y se reinicia en cada cambio
de jugador. Son cuatro minutos por defecto.

El tiempo extra es el adicional de cada jugador para todo el partido. Solo
baja, nunca se recarga, y empieza a consumirse en cuanto el turno llega a cero.
Son quince minutos por defecto.

Agotado el tiempo extra, el reloj sigue contando en negativo: no detiene nada, deja
constancia de cuánto se ha pasado cada uno.

LA CUENTA DE TURNOS

Cada jugador lleva su turno al lado de su reloj. La primera parte va del 1 al 8 y
la segunda del 9 al 16, seguidos, así que la parte se lee en el propio número.

El cambio de parte no es un pase de turno más: el pase que cierra la primera parte
deja el partido en pausa, que es el rato en que se cambian los lados y se vuelve a
desplegar. El velo lo anuncia, y lo quita el mismo toque que quita cualquier pausa.

TIEMPO MUERTO

Es el resultado de la patada inicial que mueve la cuenta, y lo declaran los
jugadores: el velo de pausa lleva su botón. Al confirmarlo, ambos equipos avanzan
un turno, o retroceden uno si la ficha del equipo que patea está en su turno 6, 7
u 8. La aplicación no tira el dado: aplica la regla cuando se le dice, y con eso una
parte puede durar siete turnos o nueve, como en la mesa.

AVISOS

Tres bocinas, de menor a mayor intensidad: cuando queda un aviso previo, cuando el
turno se agota y cuando se agota el tiempo extra. Cada una lleva su vibración, con
la misma fuerza, y respetan el volumen y la configuración del móvil.

TIEMPOS A MEDIDA

El turno y el tiempo extra se ajustan antes de empezar, cada uno con su deslizador.
Los avisos previos son dos, el temprano y el tardío, y se mueven con los dos agarres
de un mismo deslizador: juntos son un aviso, separados son dos y los dos en cero es
no avisar. Por defecto suenan a los 55 y a los 30 segundos. Los tiempos se pactan
con el partido parado.

Cada jugador puede ponerse su nombre con una pulsación larga sobre su mitad.

EL ACTA

El partido termina con un acta que cuenta lo que ha pasado en el reloj: el tiempo
de juego de los dos, el total con las paradas dentro, una barra que reparte el
juego entre uno y otro, y una gráfica turno a turno con lo que le dura un turno de
media a cada jugador. Ahí se ve dónde se atascó la partida.

El acta se comparte como imagen desde el menú del sistema, para mandarla a quien
lleve la liga.

ADEMÁS

La pantalla se mantiene encendida mientras un reloj corre y se libera al pausar.

Pausar cubre la pantalla con un velo que deja leer los dos relojes por debajo:
se habla de la jugada y el tiempo se sigue viendo.

Sin publicidad, sin compras dentro de la aplicación y sin permisos. La aplicación
no recoge ningún dato ni se conecta a internet.

QUÉ NO HACE

No lleva el marcador ni apunta las anotaciones, y no guarda historial de partidos:
ni siquiera el acta, que se comparte en el momento o se pierde. Es un árbitro que
mide el tiempo, no un juez que decida nada.

Blood Bowl es una marca registrada de Games Workshop Limited. Esta aplicación no
es oficial y no está relacionada, patrocinada ni respaldada por Games Workshop.
```

## Categoría y etiquetas

- Categoría: Herramientas. La alternativa es Juegos, pero la aplicación no es un
  juego: no se juega con ella, se mide el tiempo del juego que hay en la mesa.
- Etiquetas sugeridas: cronómetro, temporizador, juegos de mesa, reloj de ajedrez.

## Detalles de contacto

- Correo: lukegothic@gmail.com
- Sitio web y teléfono: opcionales, se dejan vacíos si no hay.

## Clasificación de contenido

El cuestionario se responde como aplicación de utilidad sin contenido sensible:
sin violencia, sin lenguaje soez, sin contenido sexual, sin juego con dinero
real, sin compras y sin interacción entre usuarios. Resultado esperado: apta
para todos los públicos.

## Seguridad de los datos

La aplicación no recoge ni comparte ningún dato. En el formulario de Play:

- ¿Recoge o comparte datos de usuario? No.
- ¿Los datos se cifran en tránsito? No aplica, no hay datos que salgan.
- ¿Se pueden pedir el borrado? No aplica.

Lo único que se guarda vive en el propio dispositivo: los tiempos y el nombre del
jugador uno. No sale del móvil, así que no cuenta como recogida de datos
(ADR-0003).

Compartir el acta tampoco lo cambia. La aplicación entrega una imagen al menú de
compartir del sistema y ahí acaba su parte: a dónde va la decide quien pulsa, y
nosotros no recibimos nada. El temporal con el que viaja la imagen es del sistema
y se lo lleva él; la aplicación sigue sin guardar el acta (ADR-0003).

Salvedad de iOS, que va en la ficha de App Store: los ajustes viajan en la copia
de seguridad de iCloud, que es algo que no se puede desactivar sin rehacer el
almacenamiento. En Play no aplica.
