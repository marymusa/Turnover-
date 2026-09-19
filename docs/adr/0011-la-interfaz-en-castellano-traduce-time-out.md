# 0011 - La interfaz en castellano traduce Time-Out

Fecha: 2026-09-19
Estado: aceptado

Modifica al ADR-0010 en un punto: cómo se llama Time-Out **de cara al jugador** en la
interfaz en castellano. El resto del ADR-0010 sigue en pie, y el código y estos
documentos lo siguen llamando Time-Out.

## Contexto

El ADR-0010 decidió que Time-Out se llama por su nombre del reglamento y no se traduce,
con el mismo argumento que "drive": es el resultado de una tabla, no una descripción.

Al poner el botón en el velo de pausa se vio en el móvil lo que el argumento no
anticipaba. El velo ya es pausar, y "Time-Out" leído del tirón en una pantalla que
acaba de decir "Pausado" se entiende como otra forma de decir lo mismo. El nombre del
reglamento solo funciona para quien ya sabe que hay una tabla de patada inicial con
ocho resultados; para todos los demás, el botón parecía repetir el velo.

La primera respuesta fue encabezarlo con la tabla de la que sale, "Evento de patada
inicial", y añadir los dos dados y el 3. Eso resuelve de dónde viene, pero deja el
nombre en un idioma distinto del resto de la frase que lo rodea.

## Decisión

**La interfaz en castellano lo llama "Tiempo muerto".** El inglés lo sigue llamando
"Time-Out", que allí es a la vez el nombre del reglamento y el de la interfaz.

**El código, el glosario y los ADR lo siguen llamando Time-Out**: `TurnCount.timeOut`,
la clave `timeOut` y la entrada del glosario no cambian. Lo que se traduce es lo que
lee el jugador, no lo que lee quien programa.

La distinción es la que ya hay con el tiempo extra, que en el código sigue siendo
`reserveClock` y de cara al jugador es otra cosa. El nombre interno y el visible no
tienen por qué coincidir, y aquí cada uno responde a una pregunta distinta: el interno,
de qué regla se trata; el visible, qué va a pasar si se pulsa.

"Drive" no se ve afectado: no está en la interfaz, porque los drives quedan fuera del
alcance de esta versión. Si entran, se decide entonces y con el mismo criterio, que es
mirarlo en el móvil.

## Consecuencias

El término deja de ser uno solo y pasa a ser dos, uno por capa. Es una cosa más que
recordar al leer el código con la aplicación delante, y el glosario lo dice para que no
sorprenda.

El botón no se sostiene solo ni traducido: sigue necesitando el encabezado de la tabla,
los dados y el 3, que son de este mismo ticket. Lo que la traducción arregla es que la
frase entera se lea en un idioma.

El criterio general del ADR-0010, que los nombres del reglamento no se traducen, se
queda para el código y la documentación, que es donde nació y donde no estorba.
