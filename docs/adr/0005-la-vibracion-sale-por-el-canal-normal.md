# 0005 - La vibración sale por el canal normal, no por el de alarma

Fecha: 2026-09-16
Estado: aceptado

## Contexto

Cada bocina lleva su vibración: una, dos o tres pulsaciones según la gravedad. La
forma directa de conseguir tres pulsaciones limpias en Flutter es el paquete
`vibration`, que acepta un patrón de milisegundos alternando espera y vibración.

Ese paquete construye todos sus efectos con `USAGE_ALARM`, el canal de alarma de
Android. Ese canal está exento a propósito de la configuración de vibración del
jugador, porque es el que usa un despertador para sonar aunque el móvil esté en
silencio. El paquete no ofrece ninguna forma de cambiarlo.

Con ese canal, el móvil vibra siempre: la casilla de "sonido y vibración
desactivados, no hace nada" no se puede cumplir en ningún aparato que tenga motor.
Comprobar `hasVibrator()` no arregla nada, porque responde si hay motor, no si el
jugador quiere vibración.

## Decisión

Se usa `HapticFeedback` del propio Flutter, que sale por el canal normal de
vibración, el que el sistema silencia cuando el jugador la apaga. Las pulsaciones
se encadenan a mano, separadas por una espera corta.

El dominio guarda el número de pulsaciones y nada más. Cuánto dura cada una y qué
las separa lo decide el adaptador.

## Consecuencias

Las tres casillas de configuración del sistema se cumplen de verdad, y no por
casualidad: el sonido lo silencia `respectSilence` y la vibración la silencia el
propio canal. La aplicación no lee el estado del timbre ni pide ningún permiso.

A cambio se pierde el control fino del patrón: una pulsación de `HapticFeedback`
dura lo que decida cada plataforma y no se puede alargar. Tres pulsaciones seguidas
se notan como tres golpes, no como un patrón medido. Es el precio de respetar la
configuración, y se paga.
