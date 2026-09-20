# Capturas (es-ES)

Ocho capturas en `screenshots/`, tomadas en un MI 9 a 1080x2340. Play pide entre
dos y ocho por idioma, de 320 a 3840 píxeles de lado, así que entran tal cual.

Play no pone texto sobre las capturas: lo que se ve es la pantalla y nada más. Si
alguna vez se montan con rótulo encima, la frase de cada una está aquí abajo.

| Fichero | Qué enseña | Rótulo si hiciera falta |
|---|---|---|
| `01-antes-de-empezar.png` | Las dos mitades con la invitación, antes de empezar | Quien toca su mitad recibe la patada inicial |
| `02-turno-corriendo.png` | Turno corriendo, el jugador activo en azul | Un toque pasa el turno |
| `03-tiempo-extra-consumiendose.png` | Turno a cero, el tiempo extra pasa a ser el número grande | Agotado el turno entra el tiempo extra |
| `04-overtime.png` | Tiempo extra agotado, contando en negativo | El reloj deja constancia de lo que se pasa cada uno |
| `05-pausado.png` | El velo de pausa, con los relojes legibles por debajo | Pausar deja leer el tiempo mientras se habla |
| `06-nombres.png` | Luke y Nuffle en sus mitades | Cada jugador se pone su nombre |
| `07-acta.png` | El acta al acabar: tiempo de juego, el reparto entre los dos y la gráfica turno a turno | Al acabar, quién se ha comido el reloj |
| `08-ajustes.png` | Los tres deslizadores | Turno, tiempo extra y aviso previo a medida |

El aviso previo tenía la suya y se cayó de la ficha: un reloj al que le quedan
ocho segundos se ve igual que un reloj cualquiera, así que la captura no
enseñaba lo que decía su rótulo. El estado sigue en `capture_main.dart`, que es
donde hace falta para mirarlo en el teléfono.

## Orden en la ficha

El orden de arriba es el que conviene: cuenta el partido de principio a fin y
deja los ajustes al final, que es lo menos vistoso. Play muestra las primeras
dos o tres sin desplazar, así que las que tienen que convencer son la 1 y la 2.

El acta va la séptima, justo antes de los ajustes: cierra el relato del partido,
que es donde tiene sentido, y además es la única captura que enseña de una vez
para qué sirve haber medido todo lo anterior.

## Cómo se toman

Con `scripts/capture_main.dart`, un entrypoint que siembra cada estado del
partido a mano en vez de esperar a que el reloj llegue solo. Reutiliza los
widgets de verdad: lo que se ve en las capturas es lo que pinta la aplicación,
no una maqueta.

La tanda entera la hace `scripts/tomar-capturas.ps1`:

```powershell
flutter build apk --debug -t scripts/capture_main.dart
adb install -r build/app/outputs/flutter-apk/app-debug.apk
powershell -File scripts/tomar-capturas.ps1 -Serial <serie>
```

Tres cosas que costaron un rato y conviene no volver a descubrir:

- **El entrypoint se versiona.** La primera versión vivía en `.scratch/`, que no
  se versiona, y se perdió. Volver a escribirla costó más que guardarla.
- **`ClockScreen` lleva una clave por captura.** Su `State` se queda con el
  primer reloj, que es un `late final`, así que sin clave Flutter lo reutiliza y
  todas las capturas salen iguales aunque el toque sí funcione.
- **Las capturas se traen con `pull`, no por la salida estándar.** Cualquier
  redirección de PowerShell trata el PNG como texto, le mete un BOM delante y lo
  corrompe. Y desde Git Bash la ruta `/sdcard/` se convierte en una ruta de
  Windows: por eso el script va en PowerShell.

El script espera cinco segundos antes de cada captura, que es lo que tarda la
presentación del escudo en terminar: se repite en cada arranque y en cada
captura, y sin esa espera el escudo sale a medio dibujar.

**El orden de la ficha ya no es el del recorrido.** `capture_main.dart` tiene
doce estados y a la ficha van ocho: sobran los tres que solo sirven para mirar
algo en el teléfono (el rival con el turno gastado, la segunda parte, el velo
con Time-Out) y el aviso previo. Y el acta es el último estado del recorrido
pero va la séptima en la ficha. Por eso el script lleva dos columnas: el nombre
del fichero, que manda el orden en Play, y el índice del estado, que es por
dónde se pasa en el teléfono. Al tocar una hay que mirar la otra.
