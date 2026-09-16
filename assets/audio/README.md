# Bocinas

Los tres ficheros que empaqueta la aplicación, en jerarquía de intensidad de menor a
mayor. Los nombres los fija `AlertSound` en `lib/domain/match_alerts.dart` y no se
cambian sin cambiarlo allí.

| Fichero | Cuándo suena | Vibración |
|---|---|---|
| `horn_soft.wav` | quedan treinta segundos de turno, y también de reserva | suave |
| `horn_strong.wav` | se agota el turno | fuerte |
| `horn_strongest.wav` | se agota la reserva | más fuerte |

La vibración va siempre en la misma intensidad que la bocina y empieza a la vez.
Cuánto dura y con cuánta fuerza sale en cada plataforma lo fija el ADR-0005.

Van empaquetados, no descargados, para que suene igual en las dos tiendas. Duran lo
que dura el original: no se recortan para que quepan en un hueco, porque un sonido
cortado dice "aquí falta algo" antes que "se acabó el turno".

## De dónde salen

Los tres vienen de Freesound y conservan aquí el fichero original con su nombre de
descarga, que lleva el identificador y el autor. Los `horn_*.wav` que lee la
aplicación se derivan de ellos, no se descargan.

| Bocina | Original |
|---|---|
| `horn_soft.wav` | `194812__funnyman850__epic-angry-boatinception-sound-effect.mp3` |
| `horn_strong.wav` | `414208__jacksonacademyashmore__airhorn.wav` |
| `horn_strongest.wav` | `455491__affreftony__whistle-end0012.wav` |

Antes de publicar hay que comprobar la licencia de cada uno en su página de Freesound:
las de CC0 no piden nada, pero las de CC-BY obligan a citar al autor en los créditos.

## Cómo se derivan

Los tres se normalizan a WAV mono de 44.1 kHz, que es lo que convenía aquí: el
original suave era un mp3, y el silbato venía en 96 kHz, ocho canales y 32 bits, unos
catorce megas de máster de estudio que en el altavoz de un móvil no se distinguen de
los cien kilos que ocupa ahora.

Ninguno se recorta. Los tres duran lo que dura su original, tres segundos, un segundo
y seis, y cuatro y seis. El silbato son tres pitidos seguidos con silencio en medio, y
así se queda: tres pitidos es justo como se cierra un partido.

```sh
ffmpeg -y -i 194812__funnyman850__epic-angry-boatinception-sound-effect.mp3 \
  -ac 1 -ar 44100 -c:a pcm_s16le -af "loudnorm=I=-16:TP=-1.5:LRA=11" \
  horn_soft.wav

ffmpeg -y -i 414208__jacksonacademyashmore__airhorn.wav \
  -ac 1 -ar 44100 -c:a pcm_s16le -af "loudnorm=I=-16:TP=-1.5:LRA=11" \
  horn_strong.wav

ffmpeg -y -i 455491__affreftony__whistle-end0012.wav \
  -ac 1 -ar 44100 -c:a pcm_s16le \
  horn_strongest.wav
```

El silbato no lleva `loudnorm` porque ya venía alto: da un pico de -2,6 dB y cualquier
subida lo satura. Los picos quedan en -8,3, -5,5 y -2,6 dB, que es el orden de
intensidad que pide la tabla sin tocarle la duración a ninguno.
