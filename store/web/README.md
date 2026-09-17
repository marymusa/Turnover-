# La página de la política de privacidad

Play exige una dirección pública que sirva la política antes de aceptar la ficha,
aunque la aplicación no recoja nada.

| Fichero | Para qué |
|---|---|
| `turnover-privacidad.zip` | lo que se sube a Dokploy, ya con la estructura buena |
| `privacidad.html` | la política, fuente del zip |
| `index.html` | una portada mínima, para que la raíz del dominio no sea un 404 |

## Dónde va

```
https://turnover.arespadelmanager.com/privacidad
```

Esa es la dirección que se pega en Play Console, en **Contenido de la aplicación
> Política de privacidad**. Play la comprueba de verdad: tiene que responder con
un 200 y servir el texto, así que hay que publicarla antes de rellenar la ficha.

Una vez publicada conviene no moverla. Si la dirección cambia hay que
actualizarla en Play Console, y mientras tanto la ficha queda con un enlace roto.

## Qué hay dentro del zip

```
index.html                 la portada, en la raíz
privacidad/index.html      la política
```

La política va como `index.html` dentro de una carpeta `privacidad/` a
propósito: así la dirección queda `/privacidad`, sin `.html` al final, que es más
limpia y más fácil de no romper luego.

Los dos ficheros son completos y sueltos: el estilo va dentro y no cargan nada de
fuera, ni tipografías ni imágenes. No hay nada que construir.

## Cómo publicarla en Dokploy

El orden importa: el certificado se emite por desafío HTTP, así que **el DNS
tiene que resolver antes** de pedirlo, o la emisión falla y hay que reintentarla.

**1. El registro DNS.** Donde esté el dominio, un registro `A`:

```
turnover.arespadelmanager.com.   A   178.104.206.35
```

Es la misma dirección a la que ya apunta `arespadelmanager.com`. Antes de seguir,
comprobar que ha propagado:

```sh
nslookup turnover.arespadelmanager.com
```

Tiene que devolver esa dirección. Hasta que lo haga, no seguir: el paso 4 falla.

**2. El servicio.** Una aplicación nueva en Dokploy:

- Provider: **Drop** (subir `turnover-privacidad.zip`)
- Build type: **Static**

Static es lo que toca porque aquí no hay nada que compilar: son dos ficheros HTML
que se sirven tal cual. Cualquiera de los otros tipos intentaría detectar un
proyecto que no existe.

**3. Desplegar.** Con el zip subido y el tipo puesto, desplegar.

**4. El dominio.** En la pestaña de dominios del servicio:

- Host: `turnover.arespadelmanager.com`
- Puerto del contenedor: `80`
- HTTPS activado, con `letsencrypt` como proveedor del certificado

Al guardar, Traefik recoge la configuración al vuelo, sin reiniciar nada. El
certificado tarda unos segundos en emitirse.

## Comprobar que ha quedado bien

Desde tu máquina, no desde el servidor:

```sh
curl -I https://turnover.arespadelmanager.com/privacidad
```

Tiene que responder `200` y `content-type: text/html`. Lo que puede salir mal:

- **No resuelve el nombre**: falta el DNS del paso 1 o no ha propagado todavía.
- **404**: el servidor estático sirve desde una carpeta que no es la raíz del
  zip. Probar entonces `https://turnover.arespadelmanager.com/privacidad/`, con
  la barra al final, que descarta que sea cosa del `index.html` de la carpeta.
- **Aviso del certificado, o responde en 80 pero no en 443**: el certificado no
  se llegó a emitir, casi siempre porque el DNS no resolvía cuando se pidió.
  Estando ya el DNS bien, se vuelve a guardar el dominio en Dokploy para que lo
  reintente.

Conviene abrirla además en el móvil antes de pegarla en Play, que es donde se va
a leer de verdad.

## Si cambia el texto

La fuente es `../es-ES/privacidad.md`. Tocar los dos a la vez, actualizar la
fecha de "Última actualización" en `privacidad.html`, y rehacer el zip:

```sh
python -c "
import zipfile
with zipfile.ZipFile('turnover-privacidad.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    z.write('index.html', 'index.html')
    z.write('privacidad.html', 'privacidad/index.html')
"
```

Se ejecuta desde esta carpeta. Después se sube el zip nuevo al servicio y se
vuelve a desplegar.
