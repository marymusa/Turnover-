# Bocinas

Los tres ficheros que empaqueta la aplicación, en jerarquía de intensidad de menor a
mayor. Los nombres los fija `AlertSound` en `lib/domain/match_alerts.dart` y no se
cambian sin cambiarlo allí.

| Fichero | Cuándo suena | Pulsaciones |
|---|---|---|
| `horn_soft.wav` | quedan treinta segundos de turno, y también de reserva | 1 |
| `horn_strong.wav` | se agota el turno | 2 |
| `horn_strongest.wav` | se agota la reserva | 3 |

Los tres que hay ahora son tonos provisionales generados a mano, no las bocinas
definitivas: sirven para que la aplicación suene mientras se prueba, y se sustituyen
en cuanto haya las de verdad.

Van empaquetados, no descargados, para que suene igual en las dos tiendas. Conviene
que sean cortos, de menos de dos segundos, porque se reproducen sobre la marcha y no
tienen que solaparse con el aviso siguiente.
