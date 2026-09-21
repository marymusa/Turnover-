# Ficha de App Store (es-ES)

Todo lo de aquí se copia tal cual en App Store Connect. Cada campo lleva su
límite contado.

Lo escrito para Play está en `../../play-store/es-ES/ficha.md` y no se duplica:
la descripción es la misma salvo lo que se dice abajo. Lo que cambia de verdad
son los campos que App Store tiene y Play no, que son el subtítulo, el texto
promocional y las palabras clave.

## Dónde no entra la marca

El ADR-0007 decidió que la marca no aparece en los campos que indexa la tienda.
En Play esos campos son el nombre y la descripción breve. **En App Store son
tres: el nombre, el subtítulo y las palabras clave.** Las palabras clave son un
campo de búsqueda puro, así que es donde una marca ajena pesa más.

De modo que `Blood Bowl` aparece una sola vez en toda la ficha: en la
descripción, para situar la aplicación, y con su aviso al final. Es la misma
decisión del ADR-0007 aplicada a una tienda que indexa un campo más.

## Nombre

Límite: 30 caracteres. Ocupa 9.

```
Turnover!
```

## Subtítulo

Límite: 30 caracteres. Ocupa 30.

```
Cronómetro para juegos de mesa
```

El ADR-0004 fijó `Cronómetro para partidos de Blood Bowl`, y el ADR-0007 lo
retiró de los campos indexados. Este subtítulo dice lo mismo sin la marca y
entra justo en los 30, que es la mitad de lo que da Play para la descripción
breve.

## Texto promocional

Límite: 170 caracteres. Ocupa 160.

```
Mide el turno y el tiempo extra de cada jugador, lleva la cuenta de turnos y cierra el partido con un acta que se comparte. Sin cuentas, sin red y sin anuncios.
```

Este campo se cambia sin publicar una versión nueva, al revés que la
descripción. Sirve para anunciar algo puntual; mientras no haya nada que
anunciar, repite el argumento principal.

## Descripción

Límite: 4000 caracteres. Ocupa 3731.

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
la misma fuerza, y respetan el volumen y la configuración del iPhone.

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

Es la de Play con un cambio: `móvil` pasa a `iPhone` donde se habla del volumen
del aparato, y nada más. El resto se deja igual a propósito, porque el texto es
el mismo producto contado una sola vez y en un solo sitio.

## Palabras clave

Límite: 100 caracteres, separadas por comas. Ocupa 94.

```
temporizador,turnos,reloj,ajedrez,tablero,partida,wargame,rol,dados,árbitro,acta,dos jugadores
```

Tres cosas que conviene no tocar sin saberlas:

- **No van espacios detrás de las comas.** Cuentan como carácter y no aportan
  nada.
- **No se repite lo que ya está en el nombre ni en el subtítulo.** App Store
  indexa los tres campos juntos, así que repetir `cronómetro`, `juegos` o `mesa`
  gastaría sitio sin ganar ninguna búsqueda.
- **No va ninguna marca**, por el ADR-0007 y porque este es el campo donde más
  pesaría.

`acta` entró al añadirse la pantalla de final de partido, y salió `tiempo`, que
no ganaba ninguna búsqueda que no ganaran ya `temporizador` y `reloj`.

## Notas para el equipo de revisión

```
La aplicación es un cronómetro para partidas de juegos de mesa a dos jugadores.
No hace falta cuenta, ni usuario de prueba, ni conexión: se abre y funciona.

CÓMO PROBARLA

1. Al abrir se ven dos mitades enfrentadas, una para cada jugador. La mitad de
   arriba está girada 180 grados a propósito: los dos jugadores miran el mismo
   iPhone desde lados opuestos de la mesa.
2. Un toque en cualquiera de las dos mitades arranca el partido.
3. Cada toque siguiente pasa el turno al otro jugador. Cada jugador lleva su
   cuenta de turnos al lado de su reloj, del 1 al 16.
4. El botón central de pausa cubre la pantalla con un velo, y el de reinicio
   devuelve el partido al principio.
5. El velo de pausa lleva un botón de Tiempo muerto. Es un resultado de la
   tirada de patada inicial del juego de mesa, que los jugadores declaran a
   mano: mueve un turno las cuentas de los dos, y pregunta antes hacia dónde.
6. El engranaje abre los ajustes, donde se cambian el turno, el tiempo extra y
   los dos avisos previos.

Para ver el final del partido sin esperar: en los ajustes, dejar el turno y el
tiempo extra en su valor mínimo y jugar unos cuantos turnos. Al pasar el último
turno aparece el acta, que resume el tiempo de los dos jugadores y se puede
compartir como imagen por el menú del sistema.

SOBRE LA MARCA QUE SE NOMBRA EN LA DESCRIPCIÓN

La descripción nombra Blood Bowl una vez, para decir para qué juego está pensada
la aplicación. Es uso nominativo: la aplicación es un accesorio de mesa y no
reproduce ningún contenido del juego, ni su reglamento, ni sus marcas gráficas,
ni sus nombres propios. No aparece en el nombre, ni en el subtítulo, ni en las
palabras clave. La descripción termina con el aviso de que la marca es de Games
Workshop Limited y de que la aplicación no es oficial ni está relacionada con
ellos.

DATOS

No se recoge ningún dato y no hay ninguna conexión a internet. Lo único que se
guarda son los tiempos y el nombre de un jugador, en el almacenamiento local del
propio aparato.

Compartir el acta no cambia eso: la aplicación entrega una imagen a la hoja de
compartir del sistema y no decide su destino ni la guarda en ninguna parte.

Esos ajustes entran en la copia de seguridad de iCloud, como los de cualquier
aplicación que use el almacenamiento estándar del sistema. No es una recogida de
datos: no salen del aparato por iniciativa de la aplicación y nosotros no los
recibimos en ningún momento.

SOLO IPHONE

La aplicación se publica solo para iPhone. El diseño se lee en vertical y solo
en vertical, porque los dos jugadores se sientan enfrente el uno del otro y cada
mitad se lee desde su lado. En iPad la aplicación compartiría pantalla y no
mandaría sobre el giro, que es incompatible con eso.
```

## Categoría

Utilidades, no Juegos. Con la aplicación no se juega: se mide el tiempo del
juego que hay en la mesa. Es la misma decisión que en Play, donde la categoría
equivalente se llama Herramientas.

## Clasificación por edades

Cuestionario de utilidad sin contenido sensible: sin violencia, sin lenguaje
soez, sin contenido sexual, sin juego con dinero real, sin compras y sin
interacción entre usuarios. Resultado esperado: 4+.

## Cumplimiento de exportación

`ITSAppUsesNonExemptEncryption` está a `false` en el `Info.plist`. La aplicación
no cifra nada por su cuenta, y sin esa clave App Store Connect pregunta por el
cifrado en cada compilación y retiene la versión hasta que alguien contesta.

Esto se explica aquí y no en el propio `Info.plist` porque Xcode reescribe ese
fichero cuando le toca, ordenando las claves alfabéticamente y **borrando los
comentarios**. Ya pasó dos veces. El valor sobrevive; lo que se pierde es el
porqué, así que el porqué vive fuera.

## Privacidad de la aplicación

No se recoge ningún dato. En el cuestionario de App Store Connect, **No, no
recopilamos datos de esta app**, y no hay más que responder.

Compartir el acta tampoco es recogida: la imagen sale por la hoja de compartir
del sistema, a donde la mande quien pulsa, y no pasa por ningún servidor nuestro
(ADR-0003).

La salvedad de iCloud que anota la ficha de Play (ADR-0003) no cambia esta
respuesta: Apple pregunta por los datos que recoge el desarrollador, y aquí el
desarrollador no recibe nada. Va explicada en las notas para revisión por si
alguien la mira, no porque el cuestionario la pida.

## Derechos

`com.ares.bloodbowl.turnover`, Iván Pérez (equipo 4NCS2LYSMX). El
identificador no se puede cambiar una vez publicado (ADR-0004).

## Previsualizaciones

Todavía no hay. Son vídeo, no imagen, y están explicadas en
`../previsualizaciones.md`.
