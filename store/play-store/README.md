# Material de Play Store

Lo de Android. Lo de iOS está al lado, en `../app-store/`, y lo común a las dos
tiendas en `../`: la política de privacidad y el guion de las capturas.

| Fichero | Para qué |
|---|---|
| `es-ES/ficha.md` | nombre, descripción breve, descripción completa y las respuestas de los cuestionarios |
| `es-ES/notas-de-version.md` | las notas de cada versión, que Play pide al subir el `.aab` |
| `es-ES/screenshots/` | las ocho capturas, 1080x2340 |
| `en-US/ficha.md` | lo mismo en inglés |
| `en-US/notas-de-version.md` | las notas en inglés |
| `en-US/screenshots/` | las ocho capturas en inglés, todavía sin tomar |
| `icono-512.png` | el icono de la ficha |
| `grafico-destacado-1024x500.png` | el gráfico destacado |

El icono y el gráfico destacado no están dentro de ningún idioma porque no
llevan texto: Play admite uno por idioma y aquí el mismo vale para los dos.

La ficha en castellano es la maestra de todo lo escrito, también de lo de App
Store. Está explicado en `../README.md`.

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

Gradle firma la release con la clave de `android/key.properties` si existe, y
con la de depuración si no, de modo que un clon recién hecho sigue compilando.
La clave, el `key.properties` y cualquier `.jks` están en el `.gitignore`.

## Lo que queda en Play Console

Con el `.aab` ya subido, lo que falta es rellenar la ficha. Cada cosa con su
fichero:

- **Notas de esta versión** → `es-ES/notas-de-version.md` y `en-US/notas-de-version.md`
- **Nombre, descripción breve y descripción completa** → `es-ES/ficha.md` y `en-US/ficha.md`
- **Capturas, icono y gráfico destacado** → `es-ES/screenshots/` y los dos PNG
- **Política de privacidad** → la dirección de `../README.md`
- **Clasificación del contenido y seguridad de los datos** → las respuestas están
  al final de `es-ES/ficha.md`

Play no deja publicar hasta que están todos, y avisa de los que falten. El
inglés se añade como idioma de la ficha sin tocar el binario: la aplicación ya
está localizada y el `.aab` subido sirve para los dos.

## Decisiones que ya están tomadas

- **El identificador** es `com.ares.bloodbowl.turnover` y no se puede cambiar
  una vez publicado (ADR-0004).
- **La marca** no aparece ni en el nombre ni en la descripción breve, que son los
  campos que indexa la tienda. Sí en la descripción completa, como uso
  nominativo y con su aviso al final (ADR-0007).
- **La categoría** es Herramientas, no Juegos: con la aplicación no se juega, se
  mide el tiempo del juego que hay en la mesa.

## Cómo se regeneran las imágenes

El gráfico destacado sale de `.scratch/shots/banner.py`, que compone el logotipo
con el color del tema. El icono de 512 es `assets/branding/icon.png` reducido.
Las capturas, en `../capturas.md`.
