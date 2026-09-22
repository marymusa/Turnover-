# 0015 - El precio de iOS, y Android gratis para siempre

Fecha: 2026-09-22
Estado: aceptado

## Contexto

ADR-0012 decidió que Turnover! no lleva publicidad y que el coste recurrente de iOS
se cubre "publicando allí una versión de pago, que es la dirección elegida y se
decidirá con su precio en su propio ticket". Este es ese ticket.

Desde entonces han aparecido dos hechos que no estaban sobre la mesa cuando se
escribió 0012, y uno de ellos cierra una puerta para siempre.

### Play ya no admite el cambio

La aplicación lleva un tiempo en pruebas cerradas en Play, esperando los catorce días
con doce probadores que Google exige a una cuenta personal antes de dejar publicar en
producción. Se dio por hecho que la decisión de precio seguía abierta hasta ese
momento. No lo estaba: la Play Console responde que

> tu aplicación está disponible como gratuita y no puede convertirse a "de pago"

y la documentación de Google lo dice igual de claro:

> Once your app has been offered for free, the app can't be changed to paid.

"Offered for free" incluye las pruebas cerradas. La puerta se cerró al publicar la
primera versión en el canal de pruebas, no al llegar a producción.

La única salida que ofrece Google es crear otra aplicación con otro nombre de paquete.
Eso choca de frente con ADR-0004, que fijó `com.ares.bloodbowl.turnover` precisamente
porque no se puede cambiar, y dejaría tirada a la gente que ya tiene la aplicación
instalada: no es una migración, es un abandono. No se hace.

Así que en Android no hay nada que decidir. Está decidido desde fuera.

### iOS está en revisión, y sale solo

La primera versión para iPhone está en revisión, con salida automática en cuanto
Apple la apruebe. El precio en App Store Connect es independiente de la revisión del
binario: cambiarlo no obliga a pasar por revisión otra vez. Pero si la aprobación
llega con el precio todavía a cero, la aplicación sale gratis, y **quien la descargue
en esa ventana la conserva gratis para siempre**. Eso no se deshace.

Por eso el precio se pone antes de que Apple apruebe, no después.

### Cuánto hay que cobrar

El coste a cubrir son los 99 $ al año de la cuenta de desarrollador de Apple, el
único gasto recurrente del proyecto. Los 25 $ de Play se pagaron una vez y no vuelven.

Contando el IVA español del 21% y la comisión del 15% del Programa para Pequeñas
Empresas de Apple, cada tramo de precio pide estas ventas al año:

| Precio | Neto por venta | Ventas al año para cubrir 99 € |
|---|---|---|
| 1,99 € | ~1,40 € | ~71 |
| 2,99 € | ~2,10 € | ~47 |
| 3,99 € | ~2,80 € | ~35 |
| 4,99 € | ~3,50 € | ~28 |

Lo que limita el precio no es lo que esta gente se puede gastar: quien juega a Blood
Bowl ya ha pagado 35 € por un equipo de miniaturas. Lo que limita es la categoría en la
que se lee la aplicación. "4,99 € por un cronómetro" es una reseña de una estrella
esperando a que la escriban; "2,99 € por el cronómetro de Blood Bowl" no lo es.

Además, subir un precio más adelante es fácil y bajarlo después de que te hayan puesto
las reseñas no arregla las reseñas.

## Decisión

**En iOS, 2,99 €, de pago por adelantado.** No hay compras dentro de la aplicación:
se paga al descargar y ya está.

El precio se fija en App Store Connect **antes de que Apple apruebe la versión que
está en revisión**, para que salga de pago desde el primer día.

**En Android, gratuita, y para siempre.** No es una elección: Play cerró esa puerta
al publicar en pruebas cerradas, y la única alternativa que ofrece Google —otro nombre
de paquete— se descarta por ADR-0004 y por la gente que ya la tiene instalada.

**Se entra en el Programa para Pequeñas Empresas de Apple**, que baja la comisión del
30% al 15% para quien facture menos de un millón de dólares al año. No es automático:
hay que solicitarlo. Los pasos, de la página de Apple:

1. Ser Account Holder del Apple Developer Program.
2. Revisar y aceptar el último acuerdo de aplicaciones de pago (Schedule 2 del Apple
   Developer Program License Agreement) en App Store Connect.
3. Declarar las cuentas de desarrollador asociadas, si las hubiera.

Se solicita en <https://developer.apple.com/app-store/small-business-program/enroll/>,
y está explicado en <https://developer.apple.com/app-store/small-business-program/>.

Este ADR **no sustituye a 0012**: lo confirma. La decisión de no llevar publicidad
sigue intacta y su aritmética no se ha movido. Lo que se añade aquí es el precio que
0012 dejó pendiente, y el hecho nuevo de que Android ya no puede ser de pago.

## Consecuencias

La aplicación es gratuita en Android y de pago en iPhone, y esa asimetría es honrada
aunque de primeras parezca incoherente: iOS tiene una factura de 99 € al año que
alguien tiene que pagar, y Android no tiene ninguna. Se cobra donde hay un coste
recurrente que cubrir. Si alguien pregunta por qué, esa es la respuesta.

**No hay que tocar una línea de código.** Una aplicación de pago por adelantado es
configuración de App Store Connect y nada más: sin `in_app_purchase`, sin StoreKit,
sin validar recibos, sin red. La aplicación que se compra es exactamente la misma que
está hoy en revisión.

**Las fichas de las tiendas siguen siendo ciertas tal como están escritas**, y no se
tocan. `play-store/es-ES/ficha.md` dice "no tiene anuncios ni compras integradas" y
`app-store/es-ES/ficha.md` dice "sin publicidad, sin compras dentro de la aplicación":
pagar por descargar no es una compra integrada, así que las dos frases se sostienen.
La política de privacidad tampoco cambia, por la misma razón por la que no cambiaba en
0012: no entra red ni SDK de nadie.

**La comisión del 15% tarda en aplicarse.** Apple ajusta los ingresos quince días
después de que termine el mes fiscal en que se aprueba la solicitud, así que las
primeras ventas pueden liquidarse todavía al 30%. Al 30%, los 99 € piden ~57 ventas
en vez de ~47. Conviene solicitarlo ya, no el día que haga falta.

**Android no volverá a estar en juego.** Quien vuelva sobre la monetización dentro de
un año no tiene que investigar si Play deja cambiar el precio: no deja, y está escrito
aquí con la frase de Google. Si algún día Android tuviera que aportar algo, la única
vía que queda abierta es la que dejó 0012: el patrocinio empaquetado, servido desde el
propio APK, sin socket y sin consentimiento.

El umbral sigue siendo el que puso 0012. Si un año después las ~47 ventas no llegan,
lo que hay que revisar no es el precio: es si la aplicación tiene bastante gente
jugando con ella como para que la pregunta tenga sentido.
