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

Límite: 4000 caracteres.

```
Turnover! es el cronómetro para partidos creado por jugadores de Blood Bowl para jugadores de Blood Bowl.

Coloca un teléfono sobre la mesa y a jugar.

Turnover! está diseñado para partidos de Blood Bowl: controla el tiempo de cada turno, la reserva de tiempo extra, los avisos y el evento de Patada Inicial <b>Tiempo Muerto</b>.

<b>TU TURNO. TU CRONOMETRO</b>

Dos entrenadores se alternan y solo hay un cronómetro activo cada vez.

• <b>Tiempo de turno</b>: el entrenador dispone del tiempo reglamentario para completar su turno. Se reinicia al pasar el turno al rival. Valor predeterminado: 4 minutos.

• <b>Tiempo extra</b>: cada entrenador tiene su propia reserva para todo el partido. Solo disminuye, nunca se recupera, y empieza a consumirse al agotarse el tiempo de turno. Valor predeterminado: 15 minutos.

• <b>Una pulsación</b> termina tu turno y lo pasa al rival.

• Cuando se acaba el tiempo extra, Turnover! sigue contando en negativo. No detiene el partido ni decide qué ocurre: eso corresponde a los entrenadores.

<b>BLOOD BOWL, CON SUS REGLAS EN EL CRONO</b>

Turnover! no es un temporizador genérico con una apariencia de Blood Bowl. Su flujo está pensado alrededor de la estructura del juego.

Cada parte comprende ocho turnos por entrenador, numerados del 1 al 16.

Cuando el Evento de Patada Inicial es <b>Tiempo Muerto</b>, Turnover! aplica automáticamente la regla de Blood Bowl: ambos marcadores avanzan una casilla, salvo que el marcador del equipo que patea esté en el turno 6, 7 u 8 de esa parte; en ese caso, ambos retroceden una casilla.

Sin hacer cuentas. Sin mover fichas. Pausa el crono, marca "Tiempo muerto" y sigue jugando.

<b>LA MESA ES LA INTERFAZ</b>

La patada inicial comienza cuando el entrenador del equipo receptor pulsa su lado. A partir de ahí, solo el entrenador cuyo turno está activo controla su cronómetro.

Puedes pausar ambos cronómetros para desplegar, consultar una regla o hacer una pausa. Los cronómetros siguen visibles durante la pausa y tocar la pantalla reanuda la partida.

<b>AVISOS QUE PUEDES OÍR</b>

No deberías tener que mirar el teléfono mientras decides una jugada.

Turnover! ofrece tres niveles de aviso sonoro, cada uno acompañado por una vibración equivalente, para los tiempos que se acercan a cero, el final del tiempo de turno y del tiempo extra. Los avisos previos son configurables; por defecto suenan cuando quedan 55 y 30 segundos.

<b>CONFIGÚRALO ANTES DE LA PATADA INICIAL</b>

Antes de empezar puedes elegir el tiempo de turno, el tiempo extra, los avisos y el nombre de cada entrenador. Una vez iniciado el partido, estas opciones quedan bloqueadas.

La pantalla permanece encendida mientras el cronómetro funciona.

<b>CUANDO TERMINE EL PARTIDO</b>

Al finalizar el último turno de la segunda parte, Turnover! prepara un acta del partido con:

• el tiempo de juego de cada entrenador y el tiempo total transcurrido, incluidas las pausas
• una comparativa del tiempo utilizado por cada entrenador
• un gráfico turno a turno con la duración de cada turno y la media de cada entrenador

Así puedes ver dónde se fueron esos cuatro minutos... y en qué turno empezó todo a complicarse.

El acta se puede compartir como imagen mediante el sistema de compartir del teléfono, para enviarla al organizador de la liga.

<b>SIN CUENTAS. SIN ANUNCIOS. SIN COMPLICACIONES</b>

Turnover! no necesita cuenta ni conexión a Internet. No tiene anuncios ni compras integradas y no guarda un historial de partidos.

El estado de un partido no se conserva al cerrar la aplicación, y el acta se comparte en ese momento o se pierde.

Turnover! mide el tiempo. No arbitra el partido, no registra touchdowns y no decide qué sucede cuando el cronómetro llega a cero.

Tú pones los equipos. Tú pones los dados. Tú tomas las decisiones cuestionables.

<b>Turnover! pone el crono</b>

Blood Bowl es una marca registrada de Games Workshop Limited. Esta aplicación no es oficial y no está afiliada, patrocinada ni respaldada por Games Workshop.
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
