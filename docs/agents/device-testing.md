# Probar en un aparato de verdad

Lo que hay que saber antes de instalar nada en el teléfono de Luke.

## La aplicación instalada viene de Play y no se puede actualizar en local

El teléfono lleva la versión de Play, y Play vuelve a firmar lo que se sube con
su propia clave de firma. La que hay en `android/key.properties` es la de
subida, que no es la misma. O sea que **ninguna compilación local, ni de debug
ni de release, puede instalarse encima de la que hay**.

El intento acaba así:

```
INSTALL_FAILED_UPDATE_INCOMPATIBLE: Package com.ares.bloodbowl.turnover
signatures do not match previously installed version
```

El mensaje suena a que la firma está mal configurada, y no lo está. Compilar en
release para "arreglarlo" no sirve de nada: se tarda un buen rato y falla igual.

Para saber de dónde salió la que está instalada:

```bash
adb -s <serie> shell dumpsys package com.ares.bloodbowl.turnover | grep installerPackageName
```

Con `com.android.vending` es de Play, y entonces la única salida es
desinstalarla. **Eso borra los nombres de jugador y los ajustes guardados, así
que hay que preguntar antes de hacerlo**, y avisar de que luego hay que volver a
instalarla desde Play.

## Llegar a un estado del partido sin esperar al reloj

`scripts/capture_main.dart` es otro punto de entrada que siembra el reloj con
`clock.advance()`, de modo que cualquier estado se alcanza al momento. Para ver
el turno agotado no hace falta esperar cuatro minutos, ni bajar los tiempos
desde los ajustes.

```bash
flutter build apk --debug -t scripts/capture_main.dart
adb -s <serie> install -r build/app/outputs/flutter-apk/app-debug.apk
```

Se pasa de una a la siguiente tocando la banda del borde izquierdo
(`adb shell input tap 15 1170`). Si el estado que hace falta no está en la
lista, se añade allí: es lo que hace que la siguiente vez tampoco cueste.

Al terminar, el teléfono se queda con la compilación de capturas, que no es la
aplicación de verdad. Conviene decirlo.

## Las rutas de `/sdcard/` desde Git Bash

Git Bash traduce `/sdcard/foo.png` a una ruta de Windows y `adb` escribe donde
no toca. Con `MSYS_NO_PATHCONV=1` delante se queda como está. Es el mismo motivo
por el que `scripts/tomar-capturas.ps1` va en PowerShell.
