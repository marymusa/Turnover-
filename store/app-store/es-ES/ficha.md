# Ficha de App Store (es-ES)

Todo lo de aquí se copia tal cual en App Store Connect. Cada campo lleva su
límite contado.

Lo escrito para Play está en `../../es-ES/ficha.md` y no se duplica: la
descripción es la misma salvo lo que se dice abajo. Lo que cambia de verdad son
los campos que App Store tiene y Play no, que son el subtítulo, el texto
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

Límite: 170 caracteres. Ocupa 161.

```
Mide el turno y el tiempo extra de cada jugador con un solo móvil sobre la mesa. Sin cuentas, sin red y sin anuncios. Se abre y se juega: un toque pasa el turno.
```

Este campo se cambia sin publicar una versión nueva, al revés que la
descripción. Sirve para anunciar algo puntual; mientras no haya nada que
anunciar, repite el argumento principal.

## Descripción

Límite: 4000 caracteres. Ocupa 2434.

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

Agotado el tiempo extra, el reloj sigue contando en negativo. No detiene nada: deja
constancia de cuánto se ha pasado cada uno, y lo que se hace con eso lo deciden
los jugadores.

AVISOS

Tres bocinas, de menor a mayor intensidad: cuando quedan treinta segundos de
turno, cuando el turno se agota y cuando se agota el tiempo extra. Cada una lleva su
vibración, con la misma fuerza. Salen por el canal normal del sistema, así que
respetan el volumen y la configuración del iPhone.

TIEMPOS A MEDIDA

El turno, el tiempo extra y el aviso previo se ajustan antes de empezar, cada uno con
su deslizador. Los tiempos se pactan con el partido parado. El aviso previo se
puede dejar en cero, y entonces el turno se acaba sin avisar antes.

Cada jugador puede ponerse su nombre con una pulsación larga sobre su mitad.

ADEMÁS

La pantalla se mantiene encendida mientras un reloj corre y se libera al pausar.

Pausar cubre la pantalla con un velo que deja leer los dos relojes por debajo:
se pausa para hablar de la jugada, y el tiempo se sigue viendo mientras se habla.

Sin publicidad, sin compras dentro de la aplicación y sin permisos. La aplicación
no recoge ningún dato ni se conecta a internet.

QUÉ NO HACE

No lleva la cuenta de turnos ni el marcador, y no guarda historial de partidos.
Es un árbitro que mide el tiempo, no un juez que decida nada.

Blood Bowl es una marca registrada de Games Workshop Limited. Esta aplicación no
es oficial y no está relacionada, patrocinada ni respaldada por Games Workshop.
```

Es la de Play con dos cambios: `móvil` pasa a `iPhone` donde se habla del
volumen del aparato, y nada más. El resto se deja igual a propósito, porque el
texto ya está decidido y revisado.

## Palabras clave

Límite: 100 caracteres, separadas por comas. Ocupa 96.

```
temporizador,turnos,reloj,ajedrez,tablero,partida,wargame,rol,dados,árbitro,tiempo,dos jugadores
```

Tres cosas que conviene no tocar sin saberlas:

- **No van espacios detrás de las comas.** Cuentan como carácter y no aportan
  nada.
- **No se repite lo que ya está en el nombre ni en el subtítulo.** App Store
  indexa los tres campos juntos, así que repetir `cronómetro`, `juegos` o `mesa`
  gastaría sitio sin ganar ninguna búsqueda.
- **No va ninguna marca**, por el ADR-0007 y porque este es el campo donde más
  pesaría.

## Notas para el equipo de revisión

```
La aplicación es un cronómetro para partidas de juegos de mesa a dos jugadores.
No hace falta cuenta, ni usuario de prueba, ni conexión: se abre y funciona.

CÓMO PROBARLA

1. Al abrir se ven dos mitades enfrentadas, una para cada jugador. La mitad de
   arriba está girada 180 grados a propósito: los dos jugadores miran el mismo
   iPhone desde lados opuestos de la mesa.
2. Un toque en cualquiera de las dos mitades arranca el partido.
3. Cada toque siguiente pasa el turno al otro jugador.
4. El botón central de pausa cubre la pantalla con un velo, y el de reinicio
   devuelve el partido al principio.
5. El engranaje abre los ajustes, donde se cambian el turno, el tiempo extra y
   el aviso previo.

Para ver el final del partido sin esperar: en los ajustes, dejar el turno y el
tiempo extra en su valor mínimo y jugar unos cuantos turnos.

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
guarda son los tres tiempos y el nombre de un jugador, en el almacenamiento
local del propio aparato.

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

## Privacidad de la aplicación

No se recoge ningún dato. En el cuestionario de App Store Connect, **No, no
recopilamos datos de esta app**, y no hay más que responder.

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
