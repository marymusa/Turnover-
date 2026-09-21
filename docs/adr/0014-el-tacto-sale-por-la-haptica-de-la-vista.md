# 0014 - El tacto sale por la háptica de la vista, y solo en los cambios de estado

Fecha: 2026-09-21
Estado: aceptado

## Contexto

La queja era que la aplicación no responde al tocarla, sobre todo en Android. Al
tocar una mitad para pasar turno no pasa nada hasta que el turno ya ha pasado, y
en un móvil donde cualquier otra aplicación contesta al dedo eso se lee como un
toque perdido.

La aplicación ya vibra, pero solo con las bocinas, y esa vibración no tiene nada
que ver con esta. El ADR-0005 la puso en un canal propio con código nativo en
las dos plataformas, y rechazó expresamente `HapticFeedback` de Flutter. Lo
primero que hay que dejar claro es por qué aquí se usa justamente lo que allí se
descartó.

## Decisión

Dos cosas, y la segunda importa tanto como la primera.

### El tacto va por el canal de las hápticas de la vista

Por `HapticFeedback`, o sea por `View.performHapticFeedback` en Android y por
`UIImpactFeedbackGenerator` en iOS. Es el canal que el sistema apaga con la
casilla de vibrar al tocar la pantalla.

El ADR-0005 descartó ese canal para las bocinas, y tenía razón: un aviso tiene
que llegarle a alguien que no está mirando el móvil, y la casilla de vibrar al
tocar dice "no quiero que vibre cuando toco", que es otra cosa. Aquí el caso es
exactamente el contrario. El tacto contesta a un dedo que está encima del
cristal, así que es literalmente lo que esa casilla regula, y que la casilla lo
silencie no es un fallo que haya que sortear: es lo que el jugador ha pedido.

Los dos canales conviven a propósito. El dominio no se entera de ninguno de los
dos, porque el tacto no es un aviso y no tiene nivel que nombrar.

Con esto no hay código nativo nuevo, ni permisos nuevos, ni ningún número que
medir: las intensidades de `HapticFeedback` son constantes de cada plataforma y
no se gradúan desde aquí. Es la diferencia con el ADR-0005, que sí tenía
números que ajustar en el aparato.

Lo que no significa es que se pueda elegir la intensidad leyendo su nombre. Los
nombres describen iOS. En Android cada uno va a una constante de
`HapticFeedbackConstants` que el fabricante gradúa como quiere, y **no están
ordenadas de flojo a fuerte**: `heavyImpact` sale más flojo que `mediumImpact`.
Más abajo está el caso y lo que se hace con él. Que no haya números que ajustar
no quiere decir que no haya que probarlo.

### Solo responden los cambios de estado

La pregunta de partida era si todos los toques tenían que notarse. No. Las guías
de las dos plataformas dicen lo mismo, y es lo razonable: lo que se nota siempre
deja de notarse.

Lo que responde es lo que cambia algo:

| Sitio | Intensidad |
|---|---|
| La mitad del jugador: empezar y pasar turno | `mediumImpact` |
| El botón de pasar turno de la costura | `mediumImpact` |
| Quitar el velo tocando en cualquier sitio | `lightImpact` |
| Pausar y reanudar desde la costura | `lightImpact` |
| Confirmar el reinicio | `heavyImpact` (en Android sale flojo, más abajo) |
| Confirmar un Time-Out | `mediumImpact` |
| Guardar un nombre, confirmar la salida | `lightImpact` |
| Cada paso de un deslizador | `selectionClick` |
| Pulsación larga para renombrar | `selectionClick` |

Y lo que no responde: los botones que solo abren un diálogo, todos los
"Cancelar", el acceso a los ajustes y el botón de pasar turno cuando está
bloqueado por la pausa.

Tres decisiones dentro de la tabla que no son obvias:

**Pasar turno pesa más que el resto.** Es el único gesto que se hace en mitad de
una partida y muchas veces sin mirar la pantalla, así que es el único que tiene
que poder confirmarse solo con el dedo. Y pesa lo mismo desde la mitad que desde
el botón de la costura, porque son la misma acción: notarlas distinto diría que
no lo son.

**Reiniciar pide el más fuerte, y en Android no lo consigue.** La intención era
que el peso fuera el aviso: pierde el partido en curso y no se deshace. No se
sostiene, y se vio al probarlo en el Mi 9.

`heavyImpact` es `CONTEXT_CLICK` en Android, que es un golpe corto y flojo, más
flojo que el `KEYBOARD_TAP` al que va `mediumImpact`. O sea que en Android
confirmar el reinicio se nota **menos** que pasar turno. Los cinco nombres de
`HapticFeedback` describen iOS, donde sí son una escala de pesos; en Android son
cinco constantes que cada fabricante gradúa como quiere, y no están ordenadas.

Se queda así. Lo que pega fuerte de verdad en Android es
`HapticFeedback.vibrate`, que es `LONG_PRESS`: la respuesta a una pulsación
larga. Usarla aquí sería sacar el peso llamando a una háptica para lo que no es,
y el tacto pasaría a decir "pulsación larga" donde ha habido un botón. El aviso
de que reiniciar no se deshace lo da el diálogo, que está escrito justamente
para eso, y no hace falta que lo repita el motor.

Flutter tiene además la familia de notificación, `successNotification`,
`warningNotification` y `errorNotification`, que es la API pensada para "una
acción ha salido bien, ha avisado o ha fallado". Sería lo semánticamente
correcto, pero pide API 30 y el Mi 9 con el que se prueba es API 29, así que ahí
no haría nada. Es por dónde mirar el día que el suelo de versiones suba.

**Abrir un diálogo no responde, confirmar sí.** Abrir no cambia nada. Por eso el
botón de reiniciar de la costura y el de Time-Out del velo no se notan, y sí se
nota el "Reiniciar" o el "Aplicar" de dentro.

La pulsación larga para renombrar es la excepción a lo de que navegar no
responde, y ya estaba antes de esto. Un toque se sabe dado porque el dedo ha
bajado; una pulsación larga no tiene ningún momento visible en el que cruce su
umbral, así que sin tacto solo se sabe que ha entrado cuando ya ha salido el
diálogo. Las dos plataformas hacen lo mismo con este gesto.

### Lo bloqueado no responde

Pasar turno está deshabilitado mientras el reloj está pausado, y no responde.

Android tiene una háptica de rechazo para justo esto,
`HapticFeedbackConstants.REJECT`, y Flutter sí la expone, por
`errorNotification`. No se usa por dos razones, y la segunda es la que manda:
pide API 30 y el Mi 9 es API 29, y sobre todo el toque nunca llega al botón
deshabilitado. Un `InkWell` sin `onTap` no recoge el toque, así que se lo queda
el velo que tiene debajo, que reanuda: se nota como reanudar, que es lo que de
verdad ha pasado.

## Sin interruptor propio en los ajustes

Cabía uno y no se pone. La casilla del sistema ya es ese interruptor y está
donde el jugador la busca; duplicarla deja dos fuentes de verdad y la pregunta
de por qué una dice una cosa y la otra otra.

Es además lo mismo que decide el ADR-0005 para el sonido y para la vibración de
las bocinas: la aplicación no impone nada por encima del móvil ni lee su estado
para llevarle la contraria.

## Probado en el Mi 9, y no en iPhone

Sí se nota. Con la casilla encendida se comprobó en la mano: pasar turno desde
la mitad y desde la costura, pausar, confirmar el reinicio y arrastrar el
deslizador del turno. Pasar turno y pausar se distinguen sin esfuerzo. Los pasos
del deslizador salen uno por minuto y limpios, que es lo único de todo esto que
podía estar mal por código propio y no por la plataforma.

De ahí salieron las dos correcciones que esta decisión lleva dentro: que
`heavyImpact` sale flojo y que el motor de masa giratoria no estorba. Ninguna de
las dos se veía leyendo.

**En iOS no se ha probado.** No hay iPhone a mano y el simulador no tiene motor,
igual que cuando se escribió el ADR-0005. El riesgo es menor que allí, porque no
hay ningún número propio, son las constantes de Apple tal cual; pero después de
lo de `heavyImpact` no se va a decir que se pueda juzgar leyéndolo.

### El registro miente, aquí no sirve

Vale la pena dejarlo escrito, porque el siguiente que mire los registros se lo
va a encontrar. `VibratorService` de MIUI escupe
`Unknown prebaked effect type (value=40)` en cada `mediumImpact`, y detrás un
`vibratorOff command failed`; con `lightImpact` no escupe nada en absoluto.
Leído solo, eso dice que el efecto se ha caído y que no vibra nada. No es
verdad: los dos se notan. Tampoco aparecen en el histórico de `dumpsys
vibrator`, donde sí salen las vibraciones de las bocinas del ADR-0005, porque no
van por el mismo camino. La única comprobación que vale es la mano.

## Lo que hay que saber antes de juzgarlo

**El jugador que se quejaba tiene el tacto apagado.** En el Mi 9 con el que se
prueba, `haptic_feedback_enabled` valía `0`. Con esa casilla apagada, todo lo
que decide este ADR no hace absolutamente nada, y no hay forma legítima de que
la haga: saltársela sería volver al canal de avisos, que es imponerse al móvil.

Eso deja una consecuencia incómoda y hay que decirla: **si quien nota la
aplicación poco responsiva la tiene apagada, esto no le arregla nada**. Lo que
le falta entonces no es tacto, es respuesta visual al pulsar, que hoy no existe
en la mitad del jugador. Se miró y se dejó fuera a propósito, porque la queja
que abrió esto era de tacto; si vuelve con la casilla encendida, ahí está lo
siguiente que mirar.

**El motor de masa giratoria no era el problema que se temía.** Esta decisión
llegó a escribir que, siendo el del Mi 9 de masa giratoria y no lineal como
explica el ADR-0005, los golpes de `lightImpact` y `mediumImpact` saldrían romos
y costaría distinguirlos. Probado en el aparato, se distinguen sin esfuerzo:
pasar turno y pausar se notan como dos cosas distintas.

El razonamiento venía del ADR-0005 y no valía aquí. Allí el suelo de amplitud
180 era real, pero porque se pedía al motor una vibración de segundos con una
amplitud elegida a mano. Un golpe corto de la háptica del sistema no es eso: lo
gradúa el fabricante para su propio motor, y en este lo gradúa bien.

Lo que sí queda tocado es la escala de pesos, y no por el motor sino por las
constantes: `heavyImpact` sale por debajo de `mediumImpact`, como está contado
más arriba.

## Consecuencias

Nada de código nativo, ningún permiso nuevo y ningún número propio que ajustar:
es la diferencia de fondo con el ADR-0005. Lo que no se sostiene es la
conclusión que se le quiso sacar, que por eso se podría juzgar leyéndolo: las
dos cosas que salieron mal, `heavyImpact` flojo y el miedo al motor, solo
aparecieron al tenerlo en la mano.

Todo el mapa vive en `lib/ui/touch_feedback.dart` y no repartido por los
widgets. Lo que hay que poder leer de un tirón no es qué intensidad lleva un
botón suelto, sino la escala entera: qué se considera un cambio de estado y qué
no.

Los dos deslizadores de los ajustes pasan a tener estado. No por lo que
muestran, sino por el tacto: `onChanged` llega en cada movimiento del dedo y no
en cada paso, así que hay que recordar en qué paso se estaba. Ese paso anterior
no se puede leer de lo que ya está guardado, porque `MatchSettings.save` escribe
en disco antes de avisar y durante un arrastre rápido va por detrás. Lo fija
`onChangeStart`, que es exacto. El de los avisos lleva un paso por agarre: mover
uno no puede hacer sonar al otro.

Esto sí se puede probar con `flutter test`, al revés que el ADR-0005: es todo
Dart y sale por un canal de plataforma que el banco de pruebas intercepta. Lo
que se fija son las afirmaciones estructurales, que son las que un refactor
rompe sin hacer ruido, y no la intensidad de cada fila, que es lo que dice esta
tabla: que un gesto responda una vez y no dos, que lo bloqueado no se note como
un pase, que cancelar no responda, y que un deslizador responda por paso y no
por movimiento.

Queda una incoherencia que no se toca. Los `InkWell` de la costura y del velo no
declaran `enableFeedback`, así que vale `true` y en Android ya sueltan el clic
del sistema al tocarlos; la mitad del jugador es un `GestureDetector` pelado y
no suelta nada. O sea que hoy unos controles suenan y otros no, y eso no lo
decidió nadie. Apagarlo es un cambio audible y merece su propia decisión;
encenderlo en la mitad significaría un clic en cada pase de turno durante toda
la partida, que es peor.

Tampoco se hace nada con que un pase de turno caiga en el mismo instante que una
bocina. Son canales distintos, y una vibración de aviso de varios segundos se
come un golpe de milisegundos sin enterarse; para evitarlo habría que contarle
al tacto en qué estado está el partido, que es romper la separación por un
choque que no se va a notar.
