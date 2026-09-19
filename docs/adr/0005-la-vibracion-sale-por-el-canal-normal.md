# 0005 - La vibración sale por el canal de aviso, no por el de alarma

Fecha: 2026-09-16
Estado: aceptado (revisado el 2026-09-19: cómo se gradúan las tres cambia entero
tras las pruebas con jugadores; el canal sigue igual)

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

| Nivel | Android | iOS |
|---|---|---|
| `soft` | 1,5 s, amplitud 180 | 1,5 s, intensidad 0,4, dureza 0,3 |
| `strong` | 3 s, amplitud 220 | 3 s, intensidad 0,7, dureza 0,6 |
| `strongest` | 4,5 s, amplitud 255 | 4,5 s, intensidad 1,0, dureza 1,0 |

Los tres esperan 45 ms en Android y 30 ms en iOS antes de arrancar, para salir a
la vez que la bocina. El porqué está más abajo.

Los dos ejes suben juntos, la duración y la fuerza. Es lo que pidieron los
jugadores después de probarlo, y es lo contrario de lo que decía la primera
versión de esta sección.

### La versión anterior, y por qué se cayó

La primera versión daba un golpe corto y nada más: 70, 180 y 330 ms en Android.
El razonamiento era que lo que separa un nivel de otro es la importancia del
aviso y no lo que dura la bocina, que un aviso de cuatro segundos no pide cuatro
segundos de vibración sino empezar a la vez que el sonido, y que de eso ya se
encarga `AlertPlayer` lanzando los dos juntos.

Se probó además a seguir la forma de cada bocina, midiendo sus tramos de sonido y
llevándolos a la onda. Eso sigue sin valer: recortar los silencios para no estar
vibrando todo el rato deja la vibración adelantada respecto al sonido desde el
primer golpe, y es peor que no seguirlo.

Lo que se cayó no es eso, es el golpe corto. Varios probadores dijeron lo mismo
por separado, y se nota sin buscarlo: debajo de una bocina de tres o cuatro
segundos, un golpe de 70 ms no acompaña a nada. Empieza a la vez, sí, y se acaba
cuando el sonido apenas ha arrancado. La escala tampoco se leía: entre 180 y
330 ms no hay quien distinga cuál de los dos avisos ha sonado sin mirar.

### Lo que se hace ahora

Segundo y medio, tres segundos y cuatro y medio. El paso entre un nivel y el
siguiente es siempre el mismo, segundo y medio, y ese salto constante y grande es
justamente la decisión: lo que tiene que quedar claro al notar la vibración es
cuál de los tres avisos ha sonado, y una escala regular se lee sin pensar.

La duración de la bocina no entra en la cuenta. Son dos escalas distintas: las
bocinas duran tres, cuatro y cuatro y seis segundos, y no se pretende que
coincidan. La suave acaba mucho antes que la suya y la más fuerte casi a la vez,
y ninguna de las dos cosas importa. Lo que importa es que los tres niveles se
distingan entre ellos.

Los números salieron de probarlos en el móvil y no de decidirlos en el papel. Se
pasó por tres, cuatro y cinco segundos, que fue la primera especificación y en la
mano resultó larga, y por dos, tres y cuatro, que iban bien pero tenían el paso
más corto.

El miedo de la versión anterior era que el motor zumbando varios segundos taparía
con su ruido la propia bocina. No pasó en el Mi 9 con estas duraciones y estas
amplitudes. Si alguna vez pasa, lo que se baja son las amplitudes, no las
duraciones, porque la queja de los probadores era de las dos cosas a la vez.

La amplitud no baja de 180 en Android. El Mi 9 lleva un motor de masa giratoria y
no uno lineal: tiene inercia, y por debajo de unos 180 no llega a moverse lo
bastante para notarse. Los consejos de Android sobre amplitudes suaves están
escritos para motores lineales. Por eso los tres niveles reparten el tramo que sí
se nota, de 180 a 255, en vez de la escala entera de 0 a 255: una escala literal
de tres pasos dejaría la suave por debajo del suelo del motor, o sea en nada.

Cada nivel sigue acabando en cero, para que el driver frene y el aviso corte
limpio en vez de dejar al motor zumbando. Y sigue sin repetirse.

### Salir a la vez no es lanzarlas a la vez

`AlertPlayer` lanza la bocina y la vibración juntas con un `Future.wait`, y esta
decisión daba por hecho que con eso salían a la vez. No salen. Con las
vibraciones ya largas se nota sin buscarlo: la vibración entra un poco antes que
el sonido.

Son dos caminos de distinta longitud. La vibración es una llamada al motor y
arranca al momento; el sonido pasa por el SoundPool y por la salida de audio del
sistema, que tardan. Lanzarlas en el mismo instante de código no las hace salir
en el mismo instante en el oído, que es el único que cuenta.

Con el golpe corto de la versión anterior no se veía, porque un golpe de 70 ms no
da tiempo a comparar con nada. Al alargar la vibración aparece.

Así que la vibración espera antes de arrancar. En Android la espera es el primer
tramo de la onda, con amplitud cero; en iOS es el `relativeTime` del evento, que
es justo para esto.

Los 45 ms de Android salen del propio aparato y no de una estimación: el Mi 9
declara `latency=21 ms` y `measuredWarmup=8 ms` en su mezclador rápido, que se
leen con `dumpsys media.audio_flinger`, y encima de eso el SoundPool tiene que
arrancar su voz. Probado en el móvil, con 45 las dos entran juntas.

Lo que no cubre: por Bluetooth la latencia de audio es mucho mayor y estos 45 ms
se quedan cortos, así que con auriculares la vibración vuelve a ir por delante.
Queda sin corregir a propósito, porque es exactamente lo que había antes por el
altavoz y leer esa latencia obliga a complicar el adaptador.

Los 30 ms de iOS son del mismo orden, más cortos porque su salida de audio lo es.
**No están comprobados**: no hay ningún iPhone a mano. Es lo primero que hay que
mirar cuando lo haya.

El motor que no sabe graduar la fuerza se queda con la duración sola, que es lo
único que le distingue un nivel de otro. En iOS el Taptic Engine es lineal y la
intensidad se nota tal cual se pide, así que ahí no hace falta suelo ninguno.

El iPhone sin Taptic Engine no puede cumplir esto: `UIImpactFeedbackGenerator` da
un toque y no se estira a segundos. Se queda como está, con su toque de tres
pesos. Son aparatos de iPhone 6 y anteriores, y el aviso les sale igual por el
altavoz.

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

Para eso está `scripts/vibration_main.dart`: tres botones a pantalla completa,
uno por intensidad, que disparan bocina y vibración por el adaptador de verdad.
Ajustar cualquiera de estos números empieza por ahí, porque ninguno se puede
juzgar leyéndolo.

Las dos plataformas no usan el mismo mecanismo, y eso se asume: cada una usa el
canal que de verdad sirve para avisar. El dominio no se entera, porque solo
nombra la intensidad.
