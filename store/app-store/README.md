# Material de App Store

Lo de al lado, `../play-store/`, es de Android. Esto es de iOS, y están
separados porque las dos tiendas no piden lo mismo: las capturas de Play son de
1080x2340, las de aquí de 1320x2868, y un tamaño no vale en la otra.

| Fichero | Para qué |
|---|---|
| `es-ES/ficha.md` | nombre, subtítulo, texto promocional, descripción, palabras clave y las notas para el equipo de revisión |
| `es-ES/screenshots/` | las ocho capturas de la ranura de 6,9", 1320x2868 |
| `es-ES/screenshots-6.7/` | las mismas ocho para la ranura de 6,7", 1284x2778 |
| `en-US/ficha.md` | lo mismo en inglés |
| `en-US/screenshots/` | las ocho en inglés, todavía sin tomar |
| `previsualizaciones.md` | por qué no hay vídeo de previsualización y qué haría falta |

La descripción es la misma que la de Play, que vive en
`../play-store/<idioma>/ficha.md` y no se duplica. Lo que sí es propio de App
Store es el subtítulo, el texto promocional y las palabras clave, que son campos
que Play no tiene.

Las notas de cada versión tampoco son propias: se escriben una vez por idioma en
`../play-store/<idioma>/notas-de-version.md`, con el límite de 500 caracteres de
Play, que es el estrecho de los dos.

## De dónde salen las capturas

```sh
./scripts/tomar-capturas-ios.sh
```

Las toma en el simulador del iPhone 17 Pro Max, que es el que da los 1320x2868
que App Store pide para las de 6,9 pulgadas. El script comprueba el tamaño antes
de dar la tanda por buena: una captura del simulador equivocado entra igual y no
se ve hasta que la tienda la rechaza.

La ranura de 6,7 pulgadas sale del iPhone 14 Plus, que da 1284x2778:

```sh
./scripts/tomar-capturas-ios.sh --aparato "iPhone 14 Plus"
```

No hace falta subirla: App Store Connect reduce sola la de 6,9 para las
pantallas menores. Está porque se pidió, y porque una captura pensada para la
pantalla en la que se ve gana algo frente a una reducida.

La ranura de 6,5 pulgadas (1242x2688) se queda sin hacer: pide un iPhone 11 Pro
Max o un XS Max, y en este Mac no hay ninguno instalado.

Para la tanda en inglés:

```sh
./scripts/tomar-capturas-ios.sh --idioma en
```

Son las mismas ocho que en Play y en el mismo orden, así que lo que enseña cada
una está escrito en `../capturas.md` y no se repite aquí.

## Por qué el script de iOS no es el de Android

En Android se llega a cada estado tocando la banda del borde izquierdo, porque
`adb` sabe tocar la pantalla. `simctl` no: sabe arrancar, fotografiar y matar, y
nada más. Así que en iOS la aplicación se arranca una vez por captura y se le
deja antes una nota con la que le toca, en el `tmp` de su contenedor.

La nota, y no una variable de entorno, porque en iOS `Platform.environment` le
llega vacía a Dart: `SIMCTL_CHILD_...` no la cruza. Se comprobó midiéndolo,
después de una tanda entera de ocho capturas iguales.

Esa tanda, además, pasó la comprobación de capturas repetidas que trae el script
de Android, porque compara el fichero entero y el reloj de la barra de estado
cambia entre captura y captura: ocho capturas idénticas con ocho sumas
distintas. Por eso aquí la suma se hace sin la barra de estado.

## Lo que el reloj de cada captura no dice

Entre sembrar el estado y disparar la foto pasan siete segundos, que es lo que
tarda el acta en montarse. El reloj del partido corre durante esa espera, así
que los segundos que se ven no son exactamente los que siembra
`capture_main.dart`. Pasa igual en Android y no importa para la ficha, pero
conviene saberlo antes de perseguir la diferencia.
