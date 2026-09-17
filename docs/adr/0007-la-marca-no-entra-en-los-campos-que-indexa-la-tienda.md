# 0007 - La marca no entra en los campos que indexa la tienda

Fecha: 2026-09-17
Estado: aceptado

Sustituye a la parte del [ADR-0004](0004-identificadores-de-publicacion.md) que
dejaba el subtítulo pendiente de revisión.

## Contexto

El ADR-0004 fijó `Cronómetro para partidos de Blood Bowl` como subtítulo y dejó
escrito que la decisión se revisaba antes de publicar. Toca ahora, al preparar la
ficha de Play Store.

Blood Bowl es una marca registrada de Games Workshop. Nombrarla no es en sí
ilegítimo: describir para qué sirve una aplicación usando el nombre del juego es
uso nominativo, y es lo que hace cualquier accesorio de un juego de mesa. Lo que
cambia el riesgo es dónde se nombra.

El nombre y la descripción breve son los campos que indexa la tienda y los que
salen en los resultados de búsqueda. Una marca ahí compite por las búsquedas del
titular de la marca, y es lo que dispara una reclamación. La descripción completa
no se indexa igual y se lee como lo que es: la explicación de para qué sirve.

## Decisión

La marca no aparece ni en el nombre ni en la descripción breve.

- Nombre: `Turnover!`
- Descripción breve: `Cronómetro de turno y tiempo extra para juegos de mesa por turnos`

La descripción completa sí nombra el juego, una vez y para situar la aplicación,
y termina con el aviso de que la marca es de Games Workshop y de que esto no es
oficial ni está relacionado con ellos.

## Consecuencias

Se pierde descubrimiento: quien busque el nombre del juego en la tienda lo tiene
más difícil para encontrar la aplicación. Es el precio de no apoyar la ficha
entera sobre una marca ajena, y se paga a sabiendas.

El subtítulo que fijó el ADR-0004 deja de usarse en la ficha. Dentro de la
aplicación no cambia nada: `appTagline` sigue diciendo lo que decía, porque ahí
no hay tienda que indexe nada.

Si Games Workshop reclamara de todos modos, lo que queda por retirar es una frase
de la descripción, no el nombre de la aplicación ni el identificador, que no se
pueden cambiar una vez publicados.
