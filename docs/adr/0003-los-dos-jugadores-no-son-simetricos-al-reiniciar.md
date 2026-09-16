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

El jugador 2 vuelve a su nombre por defecto, "Mi rival", cada vez que se reinicia el
cronómetro.

Los valores por defecto son "Yo" y "Mi rival", no "Jugador 1" y "Jugador 2". Numerarlos
los presenta como dos jugadores intercambiables, que es justo lo que esta decisión dice
que no son: el móvil es de uno de los dos.

Al reiniciar se ponen a cero los relojes, se conserva la configuración de tiempos y
se conserva el nombre del jugador 1.

## Consecuencias

Lo que se guarda en el dispositivo son cuatro cosas y ninguna más: los tres tiempos
configurables y el nombre del jugador 1. Ni relojes, ni partido en curso, ni nombre
del jugador 2, ni historial.

No se pide copia de seguridad en la nube: el nombre es una cadena que se vuelve a
escribir en cuatro segundos, y las copias de seguridad son una superficie más que
revisar en las tiendas a cambio de nada.

Lo que cada plataforma hace con eso no es lo mismo, y conviene decirlo en vez de
prometer lo que no se cumple:

- **En Android está desactivada.** El manifiesto lleva `allowBackup="false"` y
  `fullBackupContent="false"`, así que no sale nada del aparato.
- **En iOS los ajustes viajan en la copia de iCloud.** `shared_preferences` escribe en
  `NSUserDefaults`, que iCloud incluye por defecto y que no tiene interruptor para
  quedarse fuera. Excluirlo de verdad significaría sacar lo guardado a un fichero propio
  en Application Support con `isExcludedFromBackupKey`, que es rehacer la capa de
  almacenamiento entera.

Se acepta la asimetría a sabiendas (#12). Lo que viaja son tres enteros y un nombre, y
esta decisión rechazaba la copia de seguridad por no querer revisar esa superficie en
las tiendas, no por privacidad. Rehacer el almacenamiento para que un nombre de pila no
entre en una copia cifrada del propio usuario es pagar un precio real por un riesgo que
no existe.

Si algún día se guardara algo que de verdad no deba salir del aparato, esta decisión se
revisa: el seam es `SettingsStore`, y cambiar lo que hay debajo no toca el dominio.
