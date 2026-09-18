# 0009 - Las dos mitades siguen oscuras en modo claro

Fecha: 2026-09-18
Estado: aceptado

## Contexto

La aplicación pasa a seguir el modo claro u oscuro del aparato, sin selector
propio. Lo natural al hacerlo es dar la vuelta a la paleta entera: fondo claro,
tarjetas claras, letra oscura.

La paleta de la aplicación no se puede invertir así. Sus colores no son
decorativos, salieron de medir contraste, y hay uno que ata a los demás: el
amarillo del tiempo extra agotado. Es el color que avisa de que el turno se ha
consumido, y se pinta sobre tres superficies diferentes, las dos mitades activas
y la del jugador que espera. El requisito que lo eligió es que pase de 5:1 sobre
las tres.

Las dos mitades activas van saturadas, azul y naranja, porque el color es lo
único que dice de quién es el turno. Contra ellas, un aviso solo destaca si es
claro.

## La comprobación

Con la tarjeta del jugador inactivo en claro, el amarillo tendría que ser a la
vez claro, para despegarse de las mitades, y oscuro, para despegarse de la
tarjeta. Las dos condiciones no se solapan:

| Superficie | Luminancia | Para pasar de 5:1 hace falta |
|---|---|---|
| Mitad activa (azul) | 0,11 | luminancia por encima de 0,75 |
| Mitad del rival (naranja) | 0,11 | luminancia por encima de 0,77 |
| Tarjeta inactiva en claro | 0,80 | luminancia por debajo de 0,12 |

Se barrió el espacio de color entero, los 360 tonos por saturación y
luminosidad, y no hay ninguna solución. Tampoco bajando el listón a 4,5:1. El
primer color que aparece pide bajar cerca de 3:1, que es el umbral de los
elementos gráficos y no el de algo que hay que leer.

## Decisión

En modo claro se aclara el marco y no las tarjetas. El fondo de la pantalla, los
ajustes, los diálogos y la barra superior pasan a claro, con letra oscura. Las
dos mitades se quedan oscuras en los dos modos, y con ellas la letra clara que
llevan encima.

Eso deja la paleta con dos colores de letra en vez de uno, y por eso
`ClockColors` los nombra por separado:

- `text`, la que va sobre las tarjetas. Clara en las dos paletas.
- `onSurface`, la que va sobre el marco. Es la que cambia con la luz.

El azul y el naranja se eligieron otra vez para la paleta clara, no se copiaron.
Siguen siendo azul y naranja, porque esa lectura tiene que sobrevivir al cambio
de fondo, pero apuntando a las razones de contraste que tenía la oscura y no a
las máximas posibles: subidos hasta el tope, las dos mitades se volvían dos
bloques casi negros sobre una página blanca.

## Consecuencias

El modo claro no se parece a la inversión que espera quien lo enciende: lo que
se aclara es el marco, y el cronómetro en sí sigue viéndose igual. Es
deliberado. El cronómetro se mira desde el otro lado de una mesa y con el móvil
plano, y ahí las dos mitades oscuras con los números claros es lo que se lee de
lejos.

Lo que de verdad arregla el modo claro es el salto al abrir la aplicación, que es
de donde vino la petición: ya no hay un fondo negro entrando en una pantalla
clara.

Las paletas no se pueden retocar a ojo. `test/clock_colors_test.dart` vuelve a
medir el contraste de las dos en cada ejecución, incluidas las alfas, que se
miden sobre la mezcla y no sueltas. Un valor cambiado a mano que rompa alguna de
las condiciones sale ahí.

Queda sin comprobar por las pruebas lo que solo se ve en un móvil: que la paleta
clara no deslumbre y que el cambio de ajuste del sistema con la aplicación
abierta no deje nada a medias. Ver `docs/agents/device-testing.md`.
