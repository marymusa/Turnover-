# Capturas

Las mismas ocho pantallas para las dos tiendas y los dos idiomas. Lo que cambia
de una tienda a otra es el tamaño, y de un idioma a otro el texto que sale en la
pantalla: el guion es este y no se repite en ninguna parte.

| Tienda | Carpeta | Tamaño |
|---|---|---|
| Play | `play-store/<idioma>/screenshots/` | 1080x2340 |
| App Store, 6,9" | `app-store/<idioma>/screenshots/` | 1320x2868 |
| App Store, 6,7" | `app-store/<idioma>/screenshots-6.7/` | 1284x2778 |

Play pide entre dos y ocho por idioma, de 320 a 3840 píxeles de lado, así que
las ocho entran tal cual. App Store solo admite el tamaño exacto de cada ranura
y rechaza cualquier otro.

Ninguna de las dos tiendas pone texto sobre las capturas: lo que se ve es la
pantalla y nada más. Si alguna vez se montan con rótulo encima, la frase de cada
una está aquí abajo.

| Fichero | Qué enseña | Rótulo si hiciera falta |
|---|---|---|
| `01-antes-de-empezar.png` | Las dos mitades con la invitación, antes de empezar | Quien toca su mitad recibe la patada inicial |
| `02-turno-corriendo.png` | Turno corriendo, el jugador activo en azul, con su cuenta de turnos al lado | Un toque pasa el turno |
| `03-tiempo-extra-consumiendose.png` | Turno a cero, el tiempo extra pasa a ser el número grande | Agotado el turno entra el tiempo extra |
| `04-overtime.png` | Tiempo extra agotado, contando en negativo | El reloj deja constancia de lo que se pasa cada uno |
| `05-pausado.png` | El velo de pausa, con los relojes legibles por debajo | Pausar deja leer el tiempo mientras se habla |
| `06-nombres.png` | Luke y Nuffle en sus mitades | Cada jugador se pone su nombre |
| `07-acta.png` | El acta al acabar: tiempo de juego, el reparto entre los dos y la gráfica turno a turno con las medias | Al acabar, quién se ha comido el reloj |
| `08-ajustes.png` | Los deslizadores del turno, el tiempo extra y los dos avisos previos | Turno, tiempo extra y avisos a medida |

El aviso previo tenía la suya y se cayó de la ficha: un reloj al que le quedan
ocho segundos se ve igual que un reloj cualquiera, así que la captura no
enseñaba lo que decía su rótulo. El estado sigue en `capture_main.dart`, que es
donde hace falta para mirarlo en el teléfono.

El velo con el botón de Tiempo muerto tampoco entró, y es el candidato más claro
si algún día se sube a nueve: es lo único de la aplicación que no se explica
solo, porque hace falta saber de qué tabla del juego sale el botón. Hoy se
cuenta en la descripción, que es donde hay sitio para explicarlo.

## Orden en la ficha

El orden de arriba es el que conviene: cuenta el partido de principio a fin y
deja los ajustes al final, que es lo menos vistoso. Las dos tiendas muestran las
primeras dos o tres sin desplazar, así que las que tienen que convencer son la 1
y la 2.

El acta va la séptima, justo antes de los ajustes: cierra el relato del partido,
que es donde tiene sentido, y además es la única captura que enseña de una vez
para qué sirve haber medido todo lo anterior.

## Cómo se toman

Con `scripts/capture_main.dart`, un entrypoint que siembra cada estado del
partido a mano en vez de esperar a que el reloj llegue solo. Reutiliza los
widgets de verdad: lo que se ve en las capturas es lo que pinta la aplicación,
no una maqueta.

En Android, la tanda entera la hace `scripts/tomar-capturas.ps1`:

```powershell
flutter build apk --debug -t scripts/capture_main.dart
adb install -r build/app/outputs/flutter-apk/app-debug.apk
powershell -File scripts/tomar-capturas.ps1 -Serial <serie>
```

En iOS, `scripts/tomar-capturas-ios.sh`, que se explica en
`app-store/README.md`:

```sh
./scripts/tomar-capturas-ios.sh
./scripts/tomar-capturas-ios.sh --aparato "iPhone 14 Plus"
```

Para la tanda en inglés, el de iOS lleva el idioma:

```sh
./scripts/tomar-capturas-ios.sh --idioma en
```

Cambia el de la aplicación, no el del aparato, y con él la carpeta de destino:
`en-US` en lugar de `es-ES`. Las capturas en inglés no se pueden sacar de las
castellanas ni al revés, porque lo que se ve en la pantalla es texto.

**El de Android todavía no tiene esa opción**, así que las ocho de Play en
inglés están pendientes. El idioma no lo decide el aparato: `capture_main.dart`
lo lee de la segunda línea de la nota que busca en `Directory.systemTemp`, que
hoy solo escribe el script de iOS. En Android eso es el directorio de caché de
la aplicación, al que se llega con `adb shell run-as` porque el APK de capturas
es de depuración. Queda por hacer y por probar en el móvil, que es donde se
toman las de Play.

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

Los dos scripts esperan siete segundos antes de cada captura, que es lo que
marca la animación más larga de las que se fotografían: el acta montándose, que
dura cuatro y pico. La presentación del escudo, que se repite en cada arranque y
en cada captura, tarda dos y pico. Sin esa espera algo sale a medio dibujar.

**El orden de la ficha ya no es el del recorrido.** `capture_main.dart` tiene
doce estados y a la ficha van ocho: sobran los tres que solo sirven para mirar
algo en el teléfono (el rival con el turno gastado, la segunda parte, el velo
con Time-Out) y el aviso previo. Y el acta es el último estado del recorrido
pero va la séptima en la ficha. Por eso los scripts llevan dos columnas: el
nombre del fichero, que manda el orden en la tienda, y el índice del estado, que
es por dónde se pasa en el teléfono. Al tocar una hay que mirar la otra.
