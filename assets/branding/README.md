# Icono y pantalla de arranque

Las cuatro imágenes desde las que se generan el icono de la aplicación y la pantalla
de arranque de cada plataforma. No se empaquetan: no están en la lista de `assets`
del `pubspec.yaml` y no se leen en tiempo de ejecución.

| Fichero | Para qué |
|---|---|
| `icon.png` | el icono normal, con el fondo del tema ya puesto |
| `icon_foreground.png` | la capa de dibujo del icono adaptativo de Android, con fondo transparente |
| `splash.png` | la pantalla de arranque hasta Android 11 y en iOS |
| `splash_android12.png` | la de Android 12 en adelante, que recorta en un círculo |

Las cuatro salen del logotipo original, al que se le quitó el fondo casi negro para
que el dibujo caiga sobre el color del tema y no sobre un recuadro de otro negro. El
original tampoco se guarda aquí: ocupa casi dos megas y ya está recogido en lo que
generan estas cuatro.

El icono adaptativo de Android se recorta según la forma que elija el lanzador, y
puede comerse hasta un 25% por lado. Por eso `icon_foreground.png` lleva el dibujo
al 64% del lienzo y el resto transparente: así el banderín de "TURNOVER!" se lee
entero también cuando el recorte es un círculo.

El color de fondo es `#0B0F19`, el mismo de `ClockTheme.background`, y está escrito
en tres sitios: aquí en la configuración del `pubspec.yaml`, en `colors.xml` y en el
tema de Dart. Cambiar uno pide cambiar los tres.

## Cómo se regeneran

Después de tocar cualquiera de las cuatro imágenes o su configuración en el
`pubspec.yaml`:

```sh
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Los dos paquetes son `dev_dependencies`: no entran en la aplicación, solo escriben
ficheros en `android/` y en `ios/`.
