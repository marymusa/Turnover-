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

Los tres vienen de Freesound. Los `horn_*.wav` que lee la aplicación se derivan de
ellos, no se descargan.

El original no se guarda en el repositorio: son dieciséis megas que no se leen nunca
y que se cuelan en el paquete de la aplicación. Lo que hace falta para volver a
encontrarlos es el número, que es el identificador de Freesound y va en la dirección
`https://freesound.org/s/<número>/`.

| Bocina | Original en Freesound |
|---|---|
| `horn_soft.wav` | 194812, de funnyman850, "epic angry boatinception sound effect" |
| `horn_strong.wav` | 414208, de jacksonacademyashmore, "airhorn" |
| `horn_strongest.wav` | 455491, de affreftony, "whistle end0012" |

Para rehacer alguno hay que descargarlo otra vez de esas páginas.

Antes de publicar hay que comprobar la licencia de cada uno en su página de Freesound:
las de CC0 no piden nada, pero las de CC-BY obligan a citar al autor en los créditos.

## Cómo se derivan

Los tres se normalizan a WAV mono de 44.1 kHz, que es lo que convenía aquí: el
original suave era un mp3, y el silbato venía en 96 kHz, ocho canales y 32 bits, unos
catorce megas de máster de estudio que en el altavoz de un móvil no se distinguen de
los cien kilos que ocupa ahora.

Ninguno se recorta. Los tres duran lo que dura su original, tres segundos, cuatro, y
cuatro y seis. El silbato son tres pitidos seguidos con silencio en medio, y
así se queda: tres pitidos es justo como se cierra un partido.

Los tres se nivelan en escalones de dos LU y medio, de menor a mayor intensidad: -19,
-16,5 y -14 LUFS, con el techo de pico en -1,5 dB. La jerarquía de la tabla se oye
igual, pero sin el salto de nueve LU que había entre el suave y el más fuerte.

`loudnorm` va en dos pasadas y no en una. En una sola pasada estima la corrección sobre
una ventana móvil, y en clips de tres o cuatro segundos se equivoca por varios LU: llegó
a dejar el fuerte más bajo que el suave. Primero se mide, después se aplica lo medido.

```sh
# Pasada 1: medir. Devuelve input_i, input_tp, input_lra e input_thresh.
ffmpeg -i <original> -af "loudnorm=I=<objetivo>:TP=-1.5:LRA=11:print_format=json" -f null -

# Pasada 2: aplicar, con los valores de la pasada 1 y linear=true.
ffmpeg -y -i <original> -ac 1 -ar 44100 -c:a pcm_s16le \
  -af "loudnorm=I=<objetivo>:TP=-1.5:LRA=11:measured_I=...:measured_TP=...:\
measured_LRA=...:measured_thresh=...:linear=true" \
  <destino>.wav
```

El fuerte necesita un paso más. El original viene saturado, con el pico real en +0,02 dB,
así que no queda hueco para subirlo: `loudnorm` detecta que pasaría del techo, se pasa a
modo dinámico y se queda corto. Antes de nivelarlo hay que subirlo y limitarlo, y aun así
se queda en -17 LUFS en vez de -16,5, pegado al techo de -1,5. Apretarlo más solo aplasta
el golpe de la bocina.

```sh
ffmpeg -y -i 414208__jacksonacademyashmore__airhorn.wav -ac 1 -ar 44100 -c:a pcm_s16le \
  -af "volume=5dB,alimiter=level_in=1:level_out=1:limit=0.84:attack=1:release=50:level=disabled" \
  horn_strong_limitado.wav
```

Quedan en -18,9, -17,0 y -14,6 LUFS, con picos de -8,0, -1,5 y -7,4 dB.
