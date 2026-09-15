# 0003 - Los dos jugadores no son simétricos al reiniciar

Fecha: 2026-09-15
Estado: aceptado

## Contexto

Los dos jugadores son simétricos en tiempo: mismo turno, misma reserva, las mismas
reglas. Lo natural sería tratarlos igual también en todo lo demás.

Como personas no lo son. El móvil es de uno de los dos, que juega muchas partidas en
la liga y siempre con el mismo nombre. El otro es un oponente diferente cada vez.

## Decisión

El jugador 1 es el dueño del móvil y su nombre se guarda en el dispositivo. Sobrevive
a reiniciar el cronómetro y a cerrar la aplicación.

El jugador 2 vuelve a su nombre por defecto, "Oponente", cada vez que se reinicia el
cronómetro.

Al reiniciar se ponen a cero los relojes, se conserva la configuración de tiempos y
se conserva el nombre del jugador 1.

## Consecuencias

Lo que se guarda en el dispositivo son cuatro cosas y ninguna más: los tres tiempos
configurables y el nombre del jugador 1. Ni relojes, ni partido en curso, ni nombre
del jugador 2, ni historial.

No hay copia de seguridad en iCloud ni en Google: el nombre es una cadena que se
vuelve a escribir en cuatro segundos, y las copias de seguridad son una superficie
más que revisar en las tiendas a cambio de nada.
