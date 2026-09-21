# 0013 - Solo iPhone

Fecha: 2026-09-21

Estado: aceptado

## Contexto

Turnover! se ve en vertical y solo en vertical. No es una preferencia estética: está
decidido y escrito en tres sitios que se sostienen entre sí.

- `main.dart` fija `DeviceOrientation.portraitUp` al arrancar.
- El manifiesto de Android declara `screenOrientation="portrait"`.
- `CONTEXT.md` explica por qué el acta se lee entera de arriba abajo: de ella se hace
  una captura que va al responsable de la liga, y "media acta girada sería media
  captura del revés".

Durante la primera subida a App Store, Apple rechazó el paquete:

> The "UIInterfaceOrientationPortrait" orientations were provided for the
> UISupportedInterfaceOrientations Info.plist key (...) but you need to include all of
> the "UIInterfaceOrientation*" orientations to support iPad multitasking.

El proyecto declaraba `TARGETED_DEVICE_FAMILY = "1,2"`, es decir iPhone y iPad. Ese
valor no lo eligió nadie: es el que trae la plantilla de Flutter. Y una aplicación que
dice soportar iPad tiene que admitir las cuatro orientaciones, porque en iPad la
aplicación comparte pantalla con otra y no manda sobre el giro.

La salida de siempre era `UIRequiresFullScreen`, que eximía del multitarea. Apple dejó
de atenderla a partir del SDK de iOS 26, que es contra el que compila Xcode 27. Ya no
existe esa puerta.

## Decisión

Turnover! se publica **solo para iPhone**: `TARGETED_DEVICE_FAMILY = 1`.

Se quita también `UISupportedInterfaceOrientations~ipad` del `Info.plist`, que era
configuración muerta en cuanto el iPad sale de la lista.

La alternativa era soportar iPad de verdad, y eso no es tocar un plist: obliga a
rediseñar en apaisado el acta y las dos mitades enfrentadas, y a quitar el bloqueo de
orientación. Es trabajo de interfaz contra una decisión ya tomada, no un ajuste de
publicación.

## Consecuencias

La aplicación se sigue pudiendo instalar en un iPad, en modo de compatibilidad de
iPhone. Lo que no ocurre es que aparezca listada como aplicación de iPad.

El sentido de la decisión importa: **se puede añadir iPad más adelante, pero no se
puede quitar después de publicar** sin dejar tirada a la gente que ya lo hubiera
instalado en uno. Por eso se decide antes de la primera subida y no después.

Si algún día se quiere iPad, este ADR no basta: hay que revisar antes la decisión de
vertical que documenta `CONTEXT.md`, porque es esa y no esta la que lo impide.
