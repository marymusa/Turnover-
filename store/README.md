# Material de publicación

Lo que hay que pegar en Play Console, ya escrito y medido. Un idioma por
carpeta: hoy solo `es-ES/`, porque la ficha se publica en castellano y el inglés
se añade después sin tocar el binario.

Lo de App Store va aparte, en `app-store/`, porque las dos tiendas no piden el
mismo tamaño de captura. Lo escrito (nombre, descripción, cuestionarios) sirve
para las dos y no se duplica: vive aquí.

| Fichero | Para qué |
|---|---|
| `es-ES/ficha.md` | nombre, descripción breve, descripción completa y las respuestas de los cuestionarios |
| `es-ES/notas-de-version.md` | las notas de cada versión, que Play pide al subir el `.aab` |
| `es-ES/capturas.md` | qué enseña cada captura y en qué orden van |
| `es-ES/privacidad.md` | la política, fuente del HTML que se sirve |
| `es-ES/screenshots/` | las ocho capturas, 1080x2340 |
| `es-ES/icono-512.png` | el icono de la ficha |
| `es-ES/grafico-destacado-1024x500.png` | el gráfico destacado |
| `web/` | la política ya publicada y el zip con el que se subió |
| `app-store/` | lo que solo vale para App Store: las capturas de 1320x2868 |

## La política de privacidad, publicada

```
https://turnover.arespadelmanager.com/privacidad/
```

Esa es la dirección que va en Play Console, **con la barra al final**. Sin ella
se llega igual, pero pasando por dos redirecciones, y la primera baja a `http://`
antes de volver a subir. Funciona, pero no hay por qué enseñarle a un revisor una
bajada a HTTP que se puede evitar: con la barra responde 200 directo.

Está servida desde Dokploy, en el servidor de Hetzner, como un servicio propio
que no depende de los despliegues de la landing. Lo que se subió es
`web/turnover-privacidad.zip`, con tipo de construcción **Static**. El detalle
está en `web/README.md`.

El certificado lo emite Let's Encrypt y se renueva solo. Para comprobar que
sigue en pie:

```sh
curl -I https://turnover.arespadelmanager.com/privacidad/
```

## Cómo se compila lo que se sube

El `.aab` firmado sale con:

```sh
flutter build appbundle --release
```

y aparece en `build/app/outputs/bundle/release/app-release.aab`. Eso es lo que
se sube a Play Console, no un `.apk`.

Para comprobar que lleva la firma buena y no la de depuración, que es un fallo
que no avisa:

```sh
unzip -l build/app/outputs/bundle/release/app-release.aab | grep META-INF
```

Tiene que salir `UPLOAD.RSA`. Si sale `CERT.RSA`, se ha firmado con la clave de
depuración y Play lo rechaza.

La clave se creó con `scripts/crear-keystore.ps1`. La huella SHA-256 del
certificado con el que se firmó la primera versión es:

```
2E:F5:41:05:D6:5C:86:AB:1C:36:D0:D9:3B:C1:57:8F:BE:11:36:2B:0B:B6:55:9D:38:41:77:9F:56:31:77:8E
```

Play Console la enseña después de subir el bundle, y tiene que ser esa. Si algún
día no coincide, el bundle se ha firmado con otra clave y no se puede publicar
como actualización.

## Lo que ya está hecho

- **Cuenta de desarrollador de Play**, creada y verificada.
- **La política de privacidad**, publicada y comprobada.
- **La clave de firma**, creada y con el `.aab` firmado con ella.
- La versión del `pubspec.yaml` es `1.0.0+1`.
- Gradle firma la release con la clave de `android/key.properties` si existe, y
  con la de depuración si no, de modo que un clon recién hecho sigue compilando.
- La clave, el `key.properties` y cualquier `.jks` están en el `.gitignore`.
- Los textos, las notas de la versión, las capturas y las dos imágenes.

## Lo que queda en Play Console

Con el `.aab` ya subido, lo que falta es rellenar la ficha. Cada cosa con su
fichero:

- **Notas de esta versión** → `es-ES/notas-de-version.md`
- **Nombre, descripción breve y descripción completa** → `es-ES/ficha.md`
- **Capturas, icono y gráfico destacado** → `es-ES/screenshots/` y los dos PNG
- **Política de privacidad** → la dirección de más arriba
- **Clasificación del contenido y seguridad de los datos** → las respuestas están
  al final de `es-ES/ficha.md`

Play no deja publicar hasta que están todos, y avisa de los que falten.

## Decisiones que ya están tomadas

- **El identificador** es `com.ares.bloodbowl.turnover` y no se puede cambiar
  una vez publicado (ADR-0004).
- **La marca** no aparece ni en el nombre ni en la descripción breve, que son los
  campos que indexa la tienda. Sí en la descripción completa, como uso
  nominativo y con su aviso al final. El ADR-0004 dejó esta decisión abierta
  hasta el momento de publicar y aquí queda cerrada.
- **La categoría** es Herramientas, no Juegos: con la aplicación no se juega, se
  mide el tiempo del juego que hay en la mesa.

## Cómo se regeneran las imágenes

El gráfico destacado sale de `.scratch/shots/banner.py`, que compone el logotipo
con el color del tema. El icono de 512 es `assets/branding/icon.png` reducido.
Las capturas, en `es-ES/capturas.md`.
