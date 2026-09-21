# Material de publicación

Lo que hay que pegar en cada tienda, ya escrito y medido. Una carpeta por
tienda, y dentro una carpeta por idioma.

```
store/
├── play-store/     Android, Google Play Console
│   ├── es-ES/      ficha y notas en castellano
│   └── en-US/      ficha y notas en inglés
├── app-store/      iOS, App Store Connect
│   ├── es-ES/
│   └── en-US/
├── capturas.md     qué enseña cada captura y en qué orden, para las dos tiendas
├── privacidad.md   la política, fuente del HTML que se sirve
└── web/            la política ya publicada y el zip con el que se subió
```

Las dos tiendas están separadas porque no piden lo mismo: las capturas de Play
son de 1080x2340 y las de App Store de 1320x2868, y un tamaño no vale en la
otra. App Store tiene además tres campos que Play no tiene (subtítulo, texto
promocional y palabras clave), y Play tiene uno que App Store no (descripción
breve).

Lo que sí es común vive en la raíz: la política de privacidad, que es una sola
dirección para las dos tiendas, y el guion de las capturas, que son las mismas
ocho pantallas en el mismo orden.

## Qué ficha manda

`play-store/es-ES/ficha.md` es la maestra. De ella salen las otras tres:

- `app-store/es-ES/ficha.md` es la misma descripción con `móvil` cambiado por
  `iPhone` donde se habla del volumen del aparato, más los tres campos propios
  de App Store.
- `play-store/en-US/ficha.md` es la versión en inglés, escrita con los términos
  que la aplicación ya usa en ese idioma (`lib/l10n/app_en.arb`), no traducida
  palabra por palabra.
- `app-store/en-US/ficha.md` es a la inglesa lo que la de App Store en
  castellano es a la de Play.

Al cambiar un argumento hay que cambiarlo en la maestra y bajarlo a las otras
tres. Cada fichero dice de cuál viene.

Los cuestionarios (clasificación de contenido, seguridad de los datos,
privacidad, cumplimiento de exportación) no son por idioma: se responden una vez
por tienda y están en las fichas en castellano.

## La política de privacidad, publicada

```
https://turnover.arespadelmanager.com/privacidad/
```

Esa es la dirección que va en Play Console y en App Store Connect, **con la
barra al final**. Sin ella se llega igual, pero pasando por dos redirecciones, y
la primera baja a `http://` antes de volver a subir. Funciona, pero no hay por
qué enseñarle a un revisor una bajada a HTTP que se puede evitar: con la barra
responde 200 directo.

Está servida desde Dokploy, en el servidor de Hetzner, como un servicio propio
que no depende de los despliegues de la landing. Lo que se subió es
`web/turnover-privacidad.zip`, con tipo de construcción **Static**. El detalle
está en `web/README.md`.

El certificado lo emite Let's Encrypt y se renueva solo. Para comprobar que
sigue en pie:

```sh
curl -I https://turnover.arespadelmanager.com/privacidad/
```

La política está publicada solo en castellano. Las dos tiendas aceptan una única
dirección para todos los idiomas, así que la ficha en inglés apunta a la misma.
Si algún día hace falta en inglés, se añade una página al lado y cada ficha
apunta a la suya.

## Lo que ya está hecho

- **Cuenta de desarrollador de Play**, creada y verificada.
- **La política de privacidad**, publicada y comprobada.
- **La clave de firma de Android**, creada y con el `.aab` firmado con ella.
- Los textos de las cuatro fichas, las notas de la versión, las capturas de las
  dos tiendas en castellano y las dos imágenes de Play.

## Lo que falta

- Las capturas en inglés, de las dos tiendas. Se toman con los mismos scripts,
  en el idioma inglés, y están explicadas en `capturas.md`.
- Los vídeos de previsualización de App Store, que se decidió no hacer de
  momento: `app-store/previsualizaciones.md`.
