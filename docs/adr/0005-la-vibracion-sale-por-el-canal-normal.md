# 0005 - La vibración sale por el canal de aviso, no por el de alarma

Fecha: 2026-09-16
Estado: aceptado (revisado el 2026-09-16 tras comprobarlo en un móvil real)

## Contexto

Cada bocina lleva su vibración. La forma directa de conseguirla en Flutter es el
paquete `vibration`, que acepta un patrón de milisegundos y una amplitud.

Ese paquete construye todos sus efectos con `USAGE_ALARM`, el canal de alarma de
Android. Ese canal está exento a propósito de la configuración de vibración del
jugador, porque es el que usa un despertador para sonar aunque el móvil esté en
silencio. El paquete no ofrece ninguna forma de cambiarlo.

Con ese canal, el móvil vibra siempre: la casilla de "sonido y vibración
desactivados, no hace nada" no se puede cumplir en ningún aparato que tenga motor.
Comprobar `hasVibrator()` no arregla nada, porque responde si hay motor, no si el
jugador quiere vibración.

## La primera decisión, y por qué no valía

La primera versión usó `HapticFeedback`, de Flutter, dando por hecho que salía por
el canal general de vibración. No sale. En Android va a
`View.performHapticFeedback`, el canal de las hápticas de la vista, que el sistema
apaga entero con la casilla de vibrar al tocar la pantalla. Esa casilla dice "no
quiero que vibre cuando toco", no "no quiero que me avisen", y son dos cosas
diferentes.

En un Xiaomi Mi 9 con esa casilla apagada y la vibración de avisos encendida no se
notaba ninguna bocina. Las llamadas devolvían éxito igualmente, así que no había
error que ver: por eso el fallo no salió hasta probarlo en un móvil de verdad.

La documentación del propio Flutter lo avisa: `HapticFeedback` "no sirve para
controlar con precisión el módulo háptico del sistema". Es para responder al dedo
del jugador, no para avisarle de nada.

## Decisión

Un canal propio por plataforma, porque Flutter no trae ninguna abstracción sobre
el motor de vibración y `HapticFeedback` es lo único que hay.

En Android, `Vibrator` con `USAGE_NOTIFICATION`: el canal de los avisos, que el
sistema silencia cuando el jugador apaga la vibración y que no depende de la
casilla de las hápticas al tocar.

En iOS, Core Haptics. Ahí no hay elección: no existe ninguna API pública para
mover el motor, así que las hápticas son el camino, y son las que dan intensidad
graduable. El aparato sin Taptic Engine se queda con `UIImpactFeedbackGenerator`.

El dominio nombra tres intensidades, `VibrationLevel`, a la par de las tres
bocinas. Con cuánta fuerza y durante cuánto sale cada una lo decide el adaptador,
que es quien conoce el motor.

## Cómo se gradúan las tres

Lo que separa un nivel de otro es la importancia del aviso, no lo que dura la
bocina que lo acompaña. Un aviso de cuatro segundos no pide cuatro segundos de
vibración: pide empezar a la vez que el sonido, y de eso se encarga `AlertPlayer`
lanzando los dos juntos. Android lo dice igual en sus principios de hápticas: la
intensidad va con la importancia y con cada cuánto ocurre la cosa.

Cada nivel es una onda que acaba en cero, para que el driver frene y el aviso corte
limpio en vez de dejar al motor zumbando. No se repite el golpe: la gravedad la
lleva cuánto dura, no cuántas veces suena.

Se probó a seguir la forma de cada bocina, midiendo sus tramos de sonido y
llevándolos a la onda: el cuerpo continuo de las dos primeras y los tres pitidos de
la última. No encaja. La bocina más larga dura 4,6 segundos, y recortar los
silencios para no estar vibrando todo ese rato deja la vibración adelantada
respecto al sonido desde el primer golpe, que es peor que no seguirlo. O se sigue
el sonido entero, con el móvil zumbando cuatro segundos y medio y tapando con el
ruido del motor la propia bocina, o no se sigue.

No se sigue. Lo que coincide es la entrada, que es lo que se nota: los dos salen a
la vez porque `AlertPlayer` los lanza juntos.

Lo que separa un nivel de otro en Android es sobre todo la duración. La primera
versión los separaba por amplitud, con tramos cortos y valores bajos siguiendo los
principios de hápticas de Android, y en el Mi 9 no se notaba ninguno: ese móvil
lleva un motor de masa giratoria y no uno lineal, tiene inercia, y por debajo de
unos 180 de amplitud no llega a moverse. Los consejos de Android sobre amplitudes
suaves y tramos de diez milisegundos están escritos para motores lineales. La
referencia buena es el tono de llamada del propio sistema, que usa 255 en los
golpes cortos.

| Nivel | Android | iOS |
|---|---|---|
| `soft` | 70 ms, amplitud 200 | 70 ms, intensidad 0,4, dureza 0,3 |
| `strong` | 180 ms, hasta 255 | 150 ms, intensidad 0,7, dureza 0,6 |
| `strongest` | 330 ms, hasta 255 | 300 ms, intensidad 1,0, dureza 1,0 |

El motor que no sabe graduar la fuerza se queda con la duración sola, que es lo
único que le distingue un nivel de otro. En iOS no hace falta nada de esto: el
Taptic Engine es lineal y la intensidad se nota tal cual se pide.

## El orden al preparar el sonido

No es vibración, pero sale del mismo diagnóstico y se rompe igual de callado. En
Android el modo de baja latencia es un SoundPool, y hay uno por cada configuración
de audio. El reproductor que nace antes de fijar el contexto se queda en el
SoundPool de por defecto y los demás van al nuevo; con las bocinas repartidas entre
dos, los identificadores de sonido se repiten de un SoundPool a otro y cada
reproductor pide el suyo y le sale el del vecino o ninguno. Sonaba solo la primera.

Por eso `prepare` fija el contexto antes de crear ningún reproductor. El orden es
el arreglo entero, y no hay ninguna prueba que lo sujete: `flutter test` no levanta
un SoundPool.

## Consecuencias

Las tres casillas de configuración del sistema se cumplen de verdad: el sonido lo
silencia `respectSilence` y la vibración la silencia el canal de avisos. La
aplicación no lee el estado del timbre. En Android pide el permiso `VIBRATE`, que
es normal y no se le pregunta al jugador.

A cambio hay código nativo en las dos plataformas, que es lo que se evitaba
usando `HapticFeedback`. Son unas sesenta líneas por lado y no se pueden probar
con `flutter test`: lo que las cubre es probarlas en un aparato de verdad, que es
justamente lo que hacía falta para ver el fallo.

Las dos plataformas no usan el mismo mecanismo, y eso se asume: cada una usa el
canal que de verdad sirve para avisar. El dominio no se entera, porque solo
nombra la intensidad.
