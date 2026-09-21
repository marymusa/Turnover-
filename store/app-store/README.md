# Material de App Store

Lo de al lado, `store/es-ES/`, es de Play. Esto es de App Store, y están
separados porque las dos tiendas no piden lo mismo: las capturas de Play son de
1080x2340, las de aquí de 1320x2868, y un tamaño no vale en la otra.

| Fichero | Para qué |
|---|---|
| `es-ES/ficha.md` | nombre, subtítulo, texto promocional, descripción, palabras clave y las notas para el equipo de revisión |
| `es-ES/screenshots/` | las ocho capturas, 1320x2868 |
| `previsualizaciones.md` | por qué no hay vídeo de previsualización y qué haría falta |

La descripción es la misma que la de Play, que vive en `../es-ES/ficha.md` y no
se duplica. Lo que sí es propio de App Store es el subtítulo, el texto
promocional y las palabras clave, que son campos que Play no tiene.

## De dónde salen las capturas

```sh
./scripts/tomar-capturas-ios.sh
```

Las toma en el simulador del iPhone 17 Pro Max, que es el que da los 1320x2868
que App Store pide para las de 6,9 pulgadas. El script comprueba el tamaño antes
de dar la tanda por buena: una captura del simulador equivocado entra igual y no
se ve hasta que la tienda la rechaza.

Para la tanda en inglés:

```sh
./scripts/tomar-capturas-ios.sh --idioma en
```

Son las mismas ocho que en Play y en el mismo orden, así que lo que enseña cada
una está escrito en `../es-ES/capturas.md` y no se repite aquí.

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
