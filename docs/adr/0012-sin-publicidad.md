# 0012 - Sin publicidad

Fecha: 2026-09-20
Estado: aceptado

## Contexto

Turnover! es gratuita y no se conecta a internet. No pide ningún permiso salvo
`VIBRATE`, que no da acceso a nada, y la política de privacidad lo dice con todas las
letras: "no usa publicidad ni análisis de uso, y no incluye ningún componente de
terceros que recoja información".

Publicarla cuesta dinero, y conviene separar los dos costes porque no son de la misma
naturaleza:

- **Google Play: 25 $ una sola vez.** Ya está pagado y no vuelve.
- **Apple: 99 $ al año**, unos 90 €. Es el único coste recurrente, y solo existe si la
  aplicación va a iOS.

Se estudiaron tres huecos donde cabría un intersticial sin interrumpir una jugada, que
son los tres únicos momentos en los que ningún reloj corre:

1. **Al abrir la aplicación**, antes de "Pulsa para comenzar".
2. **Al pasar a la segunda parte**, aprovechando el parón que separa las dos partes.
3. **Al terminar el partido**, antes de enseñar el acta.

La aritmética no sale. Un partido de Blood Bowl dura hora y media y admitiría dos
intersticiales sin molestar. A un eCPM de intersticial en España de 3 a 8 €, eso son
entre 0,6 y 1,6 céntimos por partido completo: cubrir los 90 € de iOS pide entre
**5.600 y 15.000 partidos completos al año**, que a cuatro partidos al mes por usuario
son entre 125 y 300 usuarios activos sostenidos. Para un cronómetro de un juego de
nicho, eso no es una consecuencia de poner anuncios: es una condición previa que no se
cumple.

Y el precio no es de código. Meter AdMob trae `INTERNET`, `AD_ID`, el formulario de
consentimiento UMP obligatorio en la UE, rehacer la Seguridad de los datos de Play, la
App Tracking Transparency de iOS, y reescribir la política de privacidad para que diga
lo contrario de lo que dice hoy. `CONTEXT.md`, el README y la ficha de Play dejan de
poder decir "sin red". Se paga entero el primer día, y lo que compra son unos euros al
año que dependen de un tamaño de comunidad que la aplicación todavía no tiene.

## Decisión

Turnover! no lleva publicidad. Ni intersticiales, ni banner, ni anuncio de apertura.

El coste recurrente de iOS se cubre publicando allí una **versión de pago**, que es la
dirección elegida y se decidirá con su precio en su propio ticket. Play ya está pagado
y no necesita cubrirse.

Lo que sí cabría, si algún día hiciera falta, es un **patrocinio empaquetado**: la
imagen de una tienda de juegos dentro del APK, servida desde el propio aparato. No abre
un socket, no pide consentimiento, no toca la Seguridad de los datos y no invalida
ninguna línea de la política de privacidad. Es la única forma de publicidad compatible
con esta decisión, y queda abierta.

## Consecuencias

La política de privacidad sigue siendo cierta tal como está escrita, que es lo que
más se gana aquí. No hay UMP que montar, ni Seguridad de los datos que rehacer en cada
versión, ni una pantalla de consentimiento delante de un cronómetro de mesa.

Los tres huecos estudiados no desaparecen: siguen siendo los tres momentos en los que
ningún reloj corre, y quien vuelva sobre esto los encontrará aquí con sus números en
vez de tener que rehacerlos.

El parón de la segunda parte se hace igualmente, pero por su propio valor: hoy, al
pasar el turno que cierra la primera parte, el cronómetro arranca solo el turno 9 sin
decir nada, y eso se lee como un fallo. Nació en esta conversación como el sitio donde
iría un anuncio y se queda sin él.

Si algún día se revisa, lo que tiene que haber cambiado no es el precio de las cuentas
de desarrollador: es el número de gente que juega con ella. Con 300 usuarios activos la
conversación es otra, y entonces la comparación justa no será "anuncios o nada", sino
"anuncios o patrocinio".
