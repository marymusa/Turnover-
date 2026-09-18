# 0009 - La mitad activa no se aclara, y el aviso de turno agotado va por mitad

Fecha: 2026-09-18
Estado: aceptado

## Contexto

La aplicación pasa a seguir el modo claro u oscuro del aparato, sin selector
propio. Lo natural al hacerlo es dar la vuelta a la paleta entera: fondo claro,
tarjetas claras, letra oscura.

La paleta no se puede invertir así del todo. Sus colores no son decorativos,
salieron de medir contraste, y el color es lo único que dice de quién es el
turno: la mitad que juega va en azul y la del rival en naranja, los dos
saturados. Esos dos no pueden aclararse sin perder lo que significan.

## Decisión

En modo claro se aclaran el marco y la mitad del jugador que espera. La mitad
cuyo turno corre se queda con su color en las dos paletas.

Eso deja dos superficies diferentes dentro del cronómetro, y lo que se pinta
encima se parte en dos también:

- `text` y `activeText`, la letra de la mitad que espera y la de la que juega.
  La primera cambia con la luz, la segunda es clara siempre porque el azul y el
  naranja son oscuros en las dos paletas.
- `reserve` e `inactiveReserve`, el aviso de que el turno se ha agotado. El
  amarillo destaca sobre las mitades saturadas pero se queda en 1,2:1 sobre la
  tarjeta clara del que espera; ahí hace falta un ámbar oscuro, que da 6,5:1.

Se comprobó barriendo el espacio de color entero, los 360 tonos por saturación
y luminosidad: no hay ningún color que pase de 5:1 sobre las mitades saturadas
y sobre una tarjeta clara a la vez. Tampoco a 4,5:1. Por eso son dos y no uno.

El azul y el naranja se eligieron otra vez para la paleta clara, no se
copiaron. Siguen siendo azul y naranja, porque esa lectura tiene que sobrevivir
al cambio de fondo, pero apuntando a las razones de contraste que tenía la
oscura y no a las máximas posibles: subidos hasta el tope, las dos mitades se
volvían dos bloques casi negros sobre una página blanca.

## Los botones son botones de Material

Los controles redondos de la costura se pintaban tiñendo el fondo con un 0,07
de la letra. Eso los dejaba a 1,15:1 de la pantalla en las dos paletas, y a esa
distancia no se leen como botones puestos encima sino como manchas pegadas,
cosa que en la paleta clara salta a la vista.

Pasan a ser lo que aparentan: un `Material` con su superficie y su elevación,
como cualquier botón redondo del sistema. Pasar turno va más alto que los otros
dos, porque en Material la altura dice cuál manda.

Cada paleta se despega del fondo por donde puede, que es lo que hace Material:
en la clara con la sombra, porque el blanco del botón sobre el gris del fondo
se queda en 1,1:1; en la oscura con la propia superficie, porque una sombra
negra sobre un fondo casi negro no se ve. Por eso hay `controlSurface` y
`controlShadow`, y la prueba pide que funcione uno de los dos, no los dos.

Con eso desaparece la distinción entre un control acompañado y uno suelto: la
subía para que el botón de los ajustes no se leyera como deshabilitado, y con
superficie propia ya no hace falta.

## El hueco de la costura

Las dos tarjetas se apartan la mitad por arriba y por abajo, y la mitad que les
falta contra el borde de la pantalla la pone la pantalla. Con la medida entera
a los cuatro lados, en la costura se sumaban los márgenes de las dos y el hueco
del centro salía del doble que los de fuera.

La mitad de arriba va girada entera, así que el `RotatedBox` gira también su
margen: lo que se ponga dentro de la mitad acaba en el lado que no es. Por eso
el margen de fuera vive en la pantalla y no en la mitad. Se midieron los píxeles
en el móvil para saberlo; deducirlo del código llevó a dos arreglos que no lo
eran.

## Consecuencias

El modo claro no es la inversión que espera quien lo enciende: la mitad que
juega sigue llevando su color, y es lo que se quiere, porque es la que dice de
quién es el turno.

Las paletas no se pueden retocar a ojo. `test/clock_colors_test.dart` vuelve a
medir el contraste de las dos en cada ejecución, cada letra contra su propia
superficie y cada aviso contra la suya. Un valor cambiado a mano que rompa
alguna de las condiciones sale ahí.

Lo que las pruebas no ven se comprobó en un Mi 9, las dos paletas y el cambio
de ajuste del sistema con la aplicación abierta, que repinta sin reiniciar. Ver
`docs/agents/device-testing.md`.
