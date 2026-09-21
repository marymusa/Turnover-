# Previsualizaciones de App Store

Todavía no hay ninguna, y esto explica por qué y qué haría falta.

## Son vídeo, no imagen

Las previsualizaciones de App Store (*app previews*) son **vídeos de entre 15 y
30 segundos**, hasta tres por idioma, en `.mov`, `.mp4` o `.m4v`. No son
capturas más grandes: es metraje de la aplicación funcionando.

Las capturas, que sí están hechas, viven en `es-ES/screenshots/` y se toman con
`scripts/tomar-capturas-ios.sh`. Eso ya está resuelto y no tiene nada que ver
con esto.

Las previsualizaciones son **opcionales**. Se puede publicar sin ellas, y para
la primera versión es lo que se propone.

## Los tamaños, y cuál se puede grabar aquí

Cada tamaño de pantalla tiene su ranura en App Store Connect, y el vídeo de una
ranura tiene que medir lo que mide esa pantalla:

| Pulgadas | Resolución | ¿Hay simulador en este Mac? |
|---|---|---|
| 6,9" | 1320x2868 | Sí, iPhone 17 Pro Max |
| 6,7" | 1284x2778 | Sí, iPhone 14 Plus (comprobado) |
| 6,5" | 1242x2688 | No, haría falta instalar un iPhone 11 Pro Max o XS Max |

**Las capturas están en la ranura de 6,9".** Conviene que la previsualización
vaya en la misma, es decir 1320x2868, y no en una de las otras dos: la ficha se
lee de una pieza y mezclar ranuras deja media ficha vacía según el aparato desde
el que se mire.

Grabar es un comando:

```sh
xcrun simctl io <udid> recordVideo --codec h264 previsualizacion.mov
```

## Lo que falta, que no es grabar

El problema es el mismo que con las capturas, y aquí no tiene arreglo barato:
**`simctl` no sabe tocar la pantalla**. Un vídeo de 15 a 30 segundos de un
cronómetro tiene que enseñar a alguien tocando: arrancar el partido, pasar el
turno, ver saltar el aviso, pausar. Nada de eso se puede guionizar con las
herramientas que ya hay.

Quedan dos caminos, y los dos cuestan:

1. **Grabar a mano.** Se lanza `recordVideo`, se toca el simulador con el ratón
   durante medio minuto y se corta. Sale hoy mismo, pero no se puede repetir
   igual: cada versión de la ficha es una toma nueva, y el pulso no es el mismo.
2. **Guionizar el recorrido.** Un `integration_test` que conduzca la aplicación
   con toques de verdad mientras corre la grabación. Se repite igual siempre y
   se puede rehacer en cada versión, pero es escribir y mantener una prueba que
   hoy no existe.

Antes de cualquiera de los dos hace falta decidir qué enseña el vídeo, que es
una decisión de ficha y no de herramienta: treinta segundos dan para una cosa
bien contada, no para el recorrido entero de las ocho capturas.

## Recomendación

Publicar la primera versión sin previsualización, con las ocho capturas, y
volver a esto cuando la ficha esté en pie. Si más adelante se hace, el camino 2
es el que vale la pena: el 1 hay que repetirlo entero cada vez que cambie algo
de la interfaz.
